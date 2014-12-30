js2php = require 'js2php'

jsExpressionToPhp = (jsExpr, opts = {}) ->
	opts.arraysOnly = on if typeof opts.arraysOnly is 'undefined'
	jsExpr = "(#{jsExpr})" if ///^\{.*\}$///.test jsExpr

	jsExpr = jsExpr.replace ///^\s*\(([a-zA-Z_][a-z_A-Z0-9]*(\.[a-zA-Z_][a-z_A-Z0-9]*)*)\)///g, '$1'
	jsExpr = jsExpr.replace ///\+\s*\(([a-zA-Z_][a-z_A-Z0-9]*(\.[a-zA-Z_][a-z_A-Z0-9]*)*)\)///g, '+ $1'

	replaced = yes
	while replaced
		replaced = no
		jsExpr = jsExpr.replace ///(([a-zA-Z_][a-z_A-Z0-9]*(\.[a-zA-Z_][a-z_A-Z0-9]*)*)|("[^"]*")|('[^']*')|(\d+))(\s*\+\s*(([a-zA-Z_][a-z_A-Z0-9]*(\.[a-zA-Z_][a-z_A-Z0-9]*)*)|("[^"]*")|('[^']*')|(\d+)))+///g, (s) ->
			replaced = yes
			"add(#{s.replace ///\s*\+\s*///g, ', '})"

	phpCode = js2php jsExpr
	phpExpression = phpCode.replace(///^<\?php\n///g, "").replace(///;\n$///g, "").replace(///;\n///g, "; ")
	if opts.arraysOnly and ///^(!)?\s*\$?[a-zA-Z_][a-z_A-Z0-9]*///.test phpExpression
		phpExpression = phpExpression.replace ///->([a-zA-Z_][a-z_A-Z0-9]*)///g, "['\$1']"

	phpExpression

module.exports = jsExpressionToPhp