js2php = require 'js2php'
jsExpressionToPhp = (jsExpr) ->
  jsExpr = "(#{jsExpr})" if ///^\{.*\}$///.test jsExpr
  phpCode = js2php jsExpr
  phpExpression = phpCode.replace(///^<\?php\n///g, "").replace(///;\n$///g, "").replace(///;\n///g, "; ")
  if ///^(!)?\s*\$[a-zA-Z_][a-z_A-Z0-9]*(->[a-zA-Z_][a-z_A-Z0-9]*)+$///.test phpExpression
    phpExpression = phpExpression.replace ///->([a-zA-Z_][a-z_A-Z0-9]*)///, "['\$1']"
  
  # try to fix string concatenation
  if ///\s*\+\s*([a-zA-Z_][a-z_A-Z0-9]+|'[^']*'|'[^']*'|\d+)///.test phpExpression
    phpExpression = "add(#{phpExpression.replace ///\s*\+\s*///g, ', '})"

  phpExpression

module.exports = jsExpressionToPhp