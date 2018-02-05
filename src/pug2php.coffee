PugPhpCompiler = require './PugPhpCompiler'
# parse = require 'pug-parser'
lex = require 'pug-lexer'
module.exports = pug2php = (src, options = { filename: '' }) ->
	# parser = new pug.Parser src, options.filename, options
	# tokens = parser.parse()
	tokens = lex(src, options)
	compiler = new PugPhpCompiler tokens, options
	compiler.compile()