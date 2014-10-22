JadePhpCompiler = require './JadePhpCompiler'
jade = require 'jade'

module.exports = jade2php = (str, options = { filename: '' }) ->
	parser = new jade.Parser str, options.filename, options
	tokens = parser.parse()
	compiler = new JadePhpCompiler tokens, options
	compiler.compile()