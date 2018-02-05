fs = require 'fs'
path = require 'path'
basename = path.basename
dirname = path.dirname
resolve = path.resolve
exists = fs.existsSync or path.existsSync
join = path.join

program = require 'commander'
monocle = require('monocle')()
mkdirp = require 'mkdirp'
# pug = require 'pug'
parse = require 'pug-parser'
lex = require 'pug-lexer'
PugPhpCompiler = require './PugPhpCompiler'

options = {}

program
	.version(require('../package.json').version)
	.usage('[options] [dir|file ...]')
	.option('--omit-php-runtime', 'don\'t include php runtime into compiled templates')
	.option('--omit-php-extractor', 'don\'t include php extractor code into compiled templates')
	.option('-O, --obj <str>', 'javascript options object')
	.option('-o, --out <dir>', 'output the compiled html to <dir>')
	.option('-p, --path <path>', 'filename used to resolve includes')
	.option('-P, --pretty', 'compile pretty html output')
	.option('-c, --client', 'compile function for client-side runtime.js')
	.option('-n, --name <str>', 'The name of the compiled template (requires --client)')
	.option('-D, --no-debug', 'compile without debugging (smaller functions)')
	.option('-w, --watch', 'watch files for changes and automatically re-render')
	.option('--name-after-file', 'Name the template after the last section of the file path (requires --client and overriden by --name)')
	.option('--doctype <str>', 'Specify the doctype on the command line (useful if it is not specified by the template)')
	.option('--arrays-only', 'convert $a->b to $a["b"] (default behavior)')
	.option('--no-arrays-only', 'don\'t convert $a->b to $a["b"]')


program.on '--help', ->
	console.log """
		Examples:

			# translate pug the templates dir
			$ pug templates

			# create {foo,bar}.html
			$ pug {foo,bar}.pug

			# pug over stdio
			$ pug < my.pug > my.html

			# pug over stdio
			$ echo 'h1 Pug!' | pug

			# foo, bar dirs rendering to /tmp
			$ pug foo bar --out /tmp"""


program.parse process.argv

if program.obj
	options = if exists program.obj
		JSON.parse fs.readFileSync program.obj
	else
		eval '(' + program.obj + ')'

options.omitPhpRuntime = true if program.omitPhpRuntime
options.omitPhpExtractor = true if program.omitPhpExtractor
options.arraysOnly = program.arraysOnly
options.filename = program.path if program.path
options.watch = program.watch
files = program.args

transpilePugToPhp = (src, options = { filename: '' }) ->
	# parser = new pug.Parser str, options.filename, options
	# tokens = parser.parse()
	tokens = lex(src, options)
	filename = options.filename
	ast = parse(tokens, {filename, src})
	# console.log ast
	compiler = new PugPhpCompiler ast, options
	compiler.compile()

stdin = ->
	buf = ""
	process.stdin.setEncoding "utf8"
	process.stdin.on "data", (chunk) ->
		buf += chunk

	process.stdin.on "end", ->
		output = transpilePugToPhp buf, options
		process.stdout.write output
	
	process.stdin.resume()

	process.on "SIGINT", ->
		process.stdout.write "\n"
		process.stdin.emit "end"
		process.stdout.write "\n"
		process.exit()


getNameFromFileName = (filename) ->
	file = path.basename(filename, ".pug")
	file.toLowerCase().replace(/[^a-z0-9]+([a-z])/g, (_, character) ->
		character.toUpperCase()
	) + "Template"

renderFile = (path) ->
	re = /\.pug$/
	fs.lstat path, (err, stat) ->
		throw err  if err
		
		# Found pug file
		if stat.isFile() and re.test(path)
			fs.readFile path, "utf8", (err, str) ->
				throw err  if err
				options.filename = path
				options.name = getNameFromFileName(path)  if program.nameAfterFile
				console.log "transpiling #{path}"
				compiledPhp = transpilePugToPhp str, options
				extname = ".php"
				path = path.replace(re, extname)
				path = join(program.out, basename(path))  if program.out
				dir = resolve(dirname(path))
				mkdirp dir, 0o755, (err) ->
					throw err	if err
					try
						fs.writeFile path, compiledPhp, (err) ->
							throw err  if err
							console.log "  \u001b[90mrendered \u001b[36m%s\u001b[0m", path

					catch e
						if options.watch
							console.error e.stack or e.message or e
						else
							throw e
		
		# Found directory
		else if stat.isDirectory()
			fs.readdir path, (err, files) ->
				throw err	if err
				files.map((filename) ->
					path + "/" + filename
				).forEach renderFile


if files.length
	console.log()
	if options.watch
		process.on "uncaughtException", (err) ->
			console.error err

		files.forEach renderFile
		monocle.watchFiles
			files: files
			listener: (file) ->
				renderFile file.absolutePath

	else
		files.forEach renderFile
	process.on "exit", ->
		console.log()
else
	stdin()
