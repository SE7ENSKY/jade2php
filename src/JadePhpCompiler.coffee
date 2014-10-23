isConstant = (src) ->
  constantinople src,
    jade: runtime
    jade_interp: `undefined`

toConstant = (src) ->
  constantinople.toConstant src,
    jade: runtime
    jade_interp: `undefined`

errorAtNode = (node, error) ->
  error.line = node.line
  error.filename = node.filename
  error

jsExpressionToPhp = require './jsExpressionToPhp'

IF_REGEX = ///^if\s\(\s?(.*)\)$///
ELSE_IF_REGEX = ///^else\s+if\s+\(\s?(.*)\)$///
LOOP_REGEX = ///^(for|while)\s*\((.+)\)$///

phpRuntimeCode = require './phpRuntimeCode'

"use strict"

nodes = require("jade/lib/nodes")
filters = require("jade/lib/filters")
doctypes = require("jade/lib/doctypes")
runtime = require("jade/lib/runtime")
utils = require("jade/lib/utils")
selfClosing = require("jade/node_modules/void-elements")
parseJSExpression = require("jade/node_modules/character-parser").parseMax
constantinople = require("jade/node_modules/constantinople")

###*
Initialize `Compiler` with the given `node`.

@param {Node} node
@param {Object} options
@api public
###
Compiler = module.exports = Compiler = (node, options) ->
  @options = options = options or {}
  @node = node
  @hasCompiledDoctype = false
  @hasCompiledTag = false
  @pp = options.pretty or false
  @debug = false isnt options.compileDebug
  @indents = 0
  @parentIndents = 0
  @terse = false
  @mixins = {}
  @dynamicMixins = false
  @insideMixin = false
  @setDoctype options.doctype  if options.doctype
  return


###*
Compiler prototype.
###
Compiler:: =
  
  ###*
  Compile parse tree to JavaScript.
  
  @api public
  ###
  compile: ->
    @buf = []
    @buf.push "var jade_indent = [];"  if @pp
    @lastBufferedIdx = -1
    @visit @node
    unless @dynamicMixins
      
      # if there are no dynamic mixins we can remove any un-used mixins
      mixinNames = Object.keys(@mixins)
      i = 0

      while i < mixinNames.length
        mixin = @mixins[mixinNames[i]]
        unless mixin.used
          x = 0

          while x < mixin.instances.length
            y = mixin.instances[x].start

            while y < mixin.instances[x].end
              @buf[y] = ""
              y++
            x++
        i++
    phpRuntimeCode + @buf.join if @pp then "\n" else ""

  
  ###*
  Sets the default doctype `name`. Sets terse mode to `true` when
  html 5 is used, causing self-closing tags to end with ">" vs "/>",
  and boolean attributes are not mirrored.
  
  @param {string} name
  @api public
  ###
  setDoctype: (name) ->
    @doctype = doctypes[name.toLowerCase()] or "<!DOCTYPE " + name + ">"
    @terse = @doctype.toLowerCase() is "<!doctype html>"
    @xml = 0 is @doctype.indexOf("<?xml")
    return

  
  ###*
  Buffer the given `str` exactly as is or with interpolation
  
  @param {String} str
  @param {Boolean} interpolate
  @api public
  ###
  buffer: (str, interpolate) ->
    self = this
    if interpolate
      match = /(\\)?([#!]){((?:.|\n)*)$/.exec(str)
      if match
        @buffer str.substr(0, match.index), false
        if match[1] # escape
          @buffer match[2] + "{", false
          @buffer match[3], true
          return
        else
          rest = match[3]
          range = parseJSExpression(rest)
          # code = ((if "!" is match[2] then "" else "jade.escape")) + "((jade_interp = " + range.src + ") == null ? '' : jade_interp)"
          if "!" is match[2]
          	code = "<?= #{jsExpressionToPhp range.src} ?>"
          else
          	code = "<?= htmlspecialchars(#{jsExpressionToPhp range.src}) ?>"
          @bufferExpression code
          @buffer rest.substr(range.end + 1), true
          return
    # str = utils.stringify(str)
    # str = str.substr(1, str.length - 2)
    if @lastBufferedIdx is @buf.length
      # @lastBuffered += " + \""  if @lastBufferedType is "code"
      @lastBufferedType = "text"
      @lastBuffered += str
      # @buf[@lastBufferedIdx - 1] = "buf.push(" + @bufferStartChar + @lastBuffered + "\");"
      @buf[@lastBufferedIdx - 1] = @bufferStartChar + @lastBuffered
    else
      # @buf.push "buf.push(\"" + str + "\");"
      @buf.push str
      @lastBufferedType = "text"
      @bufferStartChar = ""
      @lastBuffered = str
      @lastBufferedIdx = @buf.length
    return

  
  ###*
  Buffer the given `src` so it is evaluated at run time
  
  @param {String} src
  @api public
  ###
  bufferExpression: (src) ->
    return @buffer(toConstant(src) + "", false)  if isConstant(src)
    if @lastBufferedIdx is @buf.length
      # @lastBuffered += "\""  if @lastBufferedType is "text"
      @lastBufferedType = "code"
      # @lastBuffered += " + (" + src + ")"
      @lastBuffered += src
      @buf[@lastBufferedIdx - 1] = "buf.push(" + @bufferStartChar + @lastBuffered + ");"
      # @buf[@lastBufferedIdx - 1] = @bufferStartChar + @lastBuffered
    else
      # @buf.push "buf.push(" + src + ");"
      @buf.push src
      @lastBufferedType = "code"
      @bufferStartChar = ""
      @lastBuffered = "(" + src + ")"
      @lastBufferedIdx = @buf.length
    return

  
  ###*
  Buffer an indent based on the current `indent`
  property and an additional `offset`.
  
  @param {Number} offset
  @param {Boolean} newline
  @api public
  ###
  prettyIndent: (offset, newline) ->
    offset = offset or 0
    newline = (if newline then "\n" else "")
    @buffer newline + Array(@indents + offset).join("  ")
    @buf.push "buf.push.apply(buf, jade_indent);"  if @parentIndents
    return

  
  ###*
  Visit `node`.
  
  @param {Node} node
  @api public
  ###
  visit: (node) ->
    debug = @debug
    # @buf.push "jade_debug.unshift({ lineno: " + node.line + ", filename: " + ((if node.filename then utils.stringify(node.filename) else "jade_debug[0].filename")) + " });"  if debug
    
    # Massive hack to fix our context
    # stack for - else[ if] etc

    # if false is node.debug and @debug
    #   @buf.pop()
    #   @buf.pop()
    @visitNode node
    # @buf.push "jade_debug.shift();"  if debug
    return

  
  ###*
  Visit `node`.
  
  @param {Node} node
  @api public
  ###
  visitNode: (node) ->
    this["visit" + node.type] node

  
  ###*
  Visit case `node`.
  
  @param {Literal} node
  @api public
  ###
  visitCase: (node) ->
    _ = @withinCase
    @withinCase = true
    @buf.push "<?php switch (#{jsExpressionToPhp node.expr}) : ?>"
    @visit node.block
    @buf.push "<?php endswitch ?>"
    @withinCase = _
    return

  
  ###*
  Visit when `node`.
  
  @param {Literal} node
  @api public
  ###
  visitWhen: (node) ->
    if "default" is node.expr
      @buf.push "<?php default : ?>"
    else
      @buf.push "<?php case #{jsExpressionToPhp node.expr} : ?>"
    if node.block
      @visit node.block
      @buf.push "<?php break ?>" unless "default" is node.expr
    return

  
  ###*
  Visit literal `node`.
  
  @param {Literal} node
  @api public
  ###
  visitLiteral: (node) ->
    @buffer node.str
    return

  
  ###*
  Visit all nodes in `block`.
  
  @param {Block} block
  @api public
  ###
  visitBlock: (block) ->
    len = block.nodes.length
    escape = @escape
    pp = @pp
    
    # Pretty print multi-line text
    @prettyIndent 1, true  if pp and len > 1 and not escape and block.nodes[0].isText and block.nodes[1].isText
    i = 0

    while i < len
      
      # Pretty print text
      @prettyIndent 1, false  if pp and i > 0 and not escape and block.nodes[i].isText and block.nodes[i - 1].isText

      # else, else if support
      if i < len - 1 and block.nodes[i].type is 'Code' and IF_REGEX.test block.nodes[i].val
        @nextElses = []
        j = i + 1
        while j < len and block.nodes[j].type is 'Code' and ///^else///.test block.nodes[j].val
          @nextElses.push block.nodes[j]
          ++j
        @visit block.nodes[i]
        @nextElses = null
      else
        @visit block.nodes[i]
      
      # Multiple text nodes are separated by newlines
      @buffer "\n"  if block.nodes[i + 1] and block.nodes[i].isText and block.nodes[i + 1].isText
      ++i
    return

  
  ###*
  Visit a mixin's `block` keyword.
  
  @param {MixinBlock} block
  @api public
  ###
  visitMixinBlock: (block) ->
    # @buf.push "jade_indent.push('" + Array(@indents + 1).join("  ") + "');"  if @pp
    # @buf.push "block && block();"
    # @buf.push "jade_indent.pop();"  if @pp
    @buf.push "<?php if (is_callable($block)) $block(); ?>"
    return

  
  ###*
  Visit `doctype`. Sets terse mode to `true` when html 5
  is used, causing self-closing tags to end with ">" vs "/>",
  and boolean attributes are not mirrored.
  
  @param {Doctype} doctype
  @api public
  ###
  visitDoctype: (doctype) ->
    @setDoctype doctype.val or "default"  if doctype and (doctype.val or not @doctype)
    @buffer @doctype  if @doctype
    @hasCompiledDoctype = true
    return

  
  ###*
  Visit `mixin`, generating a function that
  may be called within the template.
  
  @param {Mixin} mixin
  @api public
  ###
  visitMixin: (mixin) ->
    # name = "jade_mixins["
    args = mixin.args or ""
    block = mixin.block
    attrs = mixin.attrs
    attrsBlocks = mixin.attributeBlocks

    args = (if args then args.split(",") else [])
    rest = undefined
    rest = args.pop().trim().replace(/^\.\.\./, "")  if args.length and /^\.\.\./.test(args[args.length - 1].trim())
    phpAttrs = (jsExpressionToPhp arg for arg in args)

    phpMixinName = mixin.name.replace ///-///, '_'

    pp = @pp
    dynamic = mixin.name[0] is "#"
    key = mixin.name
    @dynamicMixins = true  if dynamic
    # name += ((if dynamic then mixin.name.substr(2, mixin.name.length - 3) else "\"" + mixin.name + "\"")) + "]"
    @mixins[key] = @mixins[key] or
      used: false
      instances: []

    if mixin.call
      @mixins[key].used = true
      # @buf.push "jade_indent.push('" + Array(@indents + 1).join("  ") + "');"  if pp
      # if block or attrs.length or attrsBlocks.length
      #   @buf.push name + ".call({"
      #   if block
      #     @buf.push "block: function(){"
          
      #     # Render block with no indents, dynamically added when rendered
      #     @parentIndents++
      #     _indents = @indents
      #     @indents = 0
      #     @visit mixin.block
      #     @indents = _indents
      #     @parentIndents--
      #     if attrs.length or attrsBlocks.length
      #       @buf.push "},"
      #     else
      #       @buf.push "}"
      #   if attrsBlocks.length
      #     if attrs.length
      #       val = @attrs(attrs)
      #       attrsBlocks.unshift val
      #     @buf.push "attributes: jade.merge([" + attrsBlocks.join(",") + "])"
      #   else if attrs.length
      #     val = @attrs(attrs)
      #     @buf.push "attributes: " + val
      #   if args
      #     @buf.push "}, " + args + ");"
      #   else
      #     @buf.push "});"
      # else
      #   @buf.push name + "(" + args + ");"
      # @buf.push "jade_indent.pop();"  if pp
      @buf.push "<?php mixin__#{phpMixinName}("

      attributes = null

      if block
        @buf.push "function()"
        @buf.push " use ($block) " if @insideMixin
        @buf.push "{ ?>"
        @visit block
        @buf.push "<?php }"
      else
        @buf.push "null" if phpAttrs.length > 0 or attributes

      if attrs.length > 0
        @buf.push ", array(" + (for attr in attrs
          """'#{attr.name}' => #{jsExpressionToPhp attr.val}"""
        ).join(', ') + ")"
      else
        @buf.push ", null" if phpAttrs.length > 0

      @buf.push ", #{phpAttrs.join ', '}" if phpAttrs.length > 0
      @buf.push ") ?>"
    else
      mixin_start = @buf.length
      # args = (if args then args.split(",") else [])
      # @buf.push name + " = function(" + args.join(",") + "){"
      # @buf.push "var block = (this && this.block), attributes = (this && this.attributes) || {};"
      # if rest
      #   @buf.push "var " + rest + " = [];"
      #   @buf.push "for (jade_interp = " + args.length + "; jade_interp < arguments.length; jade_interp++) {"
      #   @buf.push "  " + rest + ".push(arguments[jade_interp]);"
      #   @buf.push "}"
      # @parentIndents++
      # @visit block
      # @parentIndents--
      # @buf.push "};"
      mixinAttrs = ['$block = null', '$attributes = null']
      mixinAttrs.push phpAttrs.join(', ') if phpAttrs.length > 0
      @buf.push "<?php function mixin__#{phpMixinName}(#{mixinAttrs.join ', '}) { "
      if rest
        @buf.push "#{jsExpressionToPhp rest} = array_slice(func_get_args(), #{mixinAttrs.length}); "
      @buf.push "?>"
      @parentIndents++
      oldInsideMixin = @insideMixin
      @insideMixin = yes
      @visit block
      @insideMixin = oldInsideMixin
      @parentIndents--
      @buf.push "<?php } ?>"
      mixin_end = @buf.length
      @mixins[key].instances.push
        start: mixin_start
        end: mixin_end

    return

  
  ###*
  Visit `tag` buffering tag markup, generating
  attributes, visiting the `tag`'s code and block.
  
  @param {Tag} tag
  @api public
  ###
  visitTag: (tag) ->
    bufferName = ->
      if tag.buffer
        self.bufferExpression name
      else
        self.buffer name
      return
    @indents++
    name = tag.name
    pp = @pp
    self = this
    @escape = true  if "pre" is tag.name
    unless @hasCompiledTag
      @visitDoctype()  if not @hasCompiledDoctype and "html" is name
      @hasCompiledTag = true
    
    # pretty print
    @prettyIndent 0, true  if pp and not tag.isInline()
    if tag.selfClosing or (not @xml and selfClosing.indexOf(tag.name) isnt -1)
      @buffer "<"
      bufferName()
      @visitAttributes tag.attrs, tag.attributeBlocks
      (if @terse then @buffer(">") else @buffer("/>"))
      
      # if it is non-empty throw an error
      throw errorAtNode(tag, new Error(name + " is self closing and should not have content."))  if tag.block and not (tag.block.type is "Block" and tag.block.nodes.length is 0) and tag.block.nodes.some((tag) ->
        tag.type isnt "Text" or not /^\s*$/.test(tag.val)
      )
    else
      
      # Optimize attributes buffering
      @buffer "<"
      bufferName()
      @visitAttributes tag.attrs, tag.attributeBlocks
      @buffer ">"
      @visitCode tag.code  if tag.code
      @visit tag.block
      
      # pretty print
      @prettyIndent 0, true  if pp and not tag.isInline() and "pre" isnt tag.name and not tag.canInline()
      @buffer "</"
      bufferName()
      @buffer ">"
    @escape = false  if "pre" is tag.name
    @indents--
    return

  
  ###*
  Visit `filter`, throwing when the filter does not exist.
  
  @param {Filter} filter
  @api public
  ###
  visitFilter: (filter) ->
    text = filter.block.nodes.map((node) ->
      node.val
    ).join("\n")
    filter.attrs.filename = @options.filename
    try
      @buffer filters(filter.name, text, filter.attrs), true
    catch err
      throw errorAtNode(filter, err)
    return

  
  ###*
  Visit `text` node.
  
  @param {Text} text
  @api public
  ###
  visitText: (text) ->
    @buffer text.val, true
    return

  
  ###*
  Visit a `comment`, only buffering when the buffer flag is set.
  
  @param {Comment} comment
  @api public
  ###
  visitComment: (comment) ->
    return  unless comment.buffer
    @prettyIndent 1, true  if @pp
    @buffer "<!--" + comment.val + "-->"
    return

  
  ###*
  Visit a `BlockComment`.
  
  @param {Comment} comment
  @api public
  ###
  visitBlockComment: (comment) ->
    return  unless comment.buffer
    @prettyIndent 1, true  if @pp
    @buffer "<!--" + comment.val
    @visit comment.block
    @prettyIndent 1, true  if @pp
    @buffer "-->"
    return

  
  ###*
  Visit `code`, respecting buffer / escape flags.
  If the code is followed by a block, wrap it in
  a self-calling function.
  
  @param {Code} code
  @api public
  ###
  visitCode: (code) ->
    
    # Wrap code blocks with {}.
    # we only wrap unbuffered code blocks ATM
    # since they are usually flow control

    # Buffer code
    if code.buffer
      val = code.val.trimLeft()
      val = jsExpressionToPhp val
      val = "htmlspecialchars(" + val + ")"  if code.escape
      val = '<?= ' + val + ' ?>'
      @bufferExpression val
    else if IF_REGEX.test code.val
      m = code.val.match IF_REGEX
      condition = m[1]
      @visitIf
        condition: condition
        block: code.block
        nextElses: @nextElses
    else if ///^else///.test code.val
      # ignore else and else-if, they was catched in @nextElses when processing first if
    else if LOOP_REGEX.test code.val
      @visitLoop code
    else
      @buf.push "<?php #{jsExpressionToPhp code.val} ?>"
    
      # Block support
      if code.block
        # @buf.push "<?php "  unless code.buffer
        @visit code.block
        # @buf.push " ?>"  unless code.buffer
    return

  visitLoop: (loopNode) ->
    m = loopNode.val.match LOOP_REGEX
    loopType = m[1]
    conditions = m[2]
    @buf.push "<?php #{loopType} (#{jsExpressionToPhp conditions}) : ?>"
    @visit loopNode.block if loopNode.block
    @buf.push "<?php end#{loopType} ?>"

  visitIf: (ifNode) ->
    @buf.push "<?php if (#{jsExpressionToPhp ifNode.condition}) : ?>"
    @visit ifNode.block if ifNode.block
    unless ifNode.nextElses
      @buf.push "<?php endif ?>"
    else
      for alternative in ifNode.nextElses
        if alternative.val is "else"
          @buf.push "<?php else : ?>"
          @visit alternative.block
        else if ELSE_IF_REGEX.test alternative.val
          m = alternative.val.match ELSE_IF_REGEX
          condition = m[1]
          @buf.push "<?php elseif (#{jsExpressionToPhp condition}) : ?>"
          @visit alternative.block
      @buf.push "<?php endif ?>"
  
  ###*
  Visit `each` block.
  
  @param {Each} each
  @api public
  ###
  visitEach: (each) ->
    as = if each.key is '$index'
      jsExpressionToPhp each.val
    else
      "#{jsExpressionToPhp each.key} => #{jsExpressionToPhp each.val}"
    @buf.push "<?php if (#{jsExpressionToPhp each.obj}) : foreach (#{jsExpressionToPhp each.obj} as #{as}) : ?>"
    @visit each.block
    unless each.alternative
      @buf.push "<?php endforeach; endif ?>"
    else
      @buf.push "<?php endforeach; else : ?>"
      @visit each.alternative
      @buf.push "<?php endif ?>"
    return

  
  ###*
  Visit `attrs`.
  
  @param {Array} attrs
  @api public
  ###
  visitAttributes: (attrs, attributeBlocks) ->
    if attributeBlocks.length
      if attrs.length
        val = @attrs(attrs)
        attributeBlocks.unshift val
      @buffer "<?php attrs(" + (for attributeBlock in attributeBlocks
        if attributeBlock[0] is '{'
          cc = attributeBlock.replace ///jade\.escape///g, 'htmlspecialchars'
          jsExpressionToPhp cc
        else
          jsExpressionToPhp attributeBlock
      ).join(", ") + "); ?>"
      # @bufferExpression "jade.attrs(jade.merge([" + attributeBlocks.join(",") + "]), " + utils.stringify(@terse) + ")"
    else @attrs attrs, true  if attrs.length
    return

  
  ###*
  Compile attributes.
  ###
  attrs: (attrs, buffer) ->
    buf = []
    classes = []
    classEscaping = []
    attrs.forEach ((attr) ->
      key = attr.name
      escaped = attr.escaped
      if key is "class"
        classes.push attr.val
        classEscaping.push attr.escaped
      else if isConstant(attr.val)
        if buffer
          @buffer runtime.attr(key, toConstant(attr.val), escaped, @terse)
        else
          val = toConstant(attr.val)
          val = runtime.escape(val)  if escaped and not (key.indexOf("data") is 0 and typeof val isnt "string")
          buf.push utils.stringify(key) + ": " + utils.stringify(val)
      else
        if buffer
          # @bufferExpression "jade.attr(\"" + key + "\", " + attr.val + ", " + utils.stringify(escaped) + ", " + utils.stringify(@terse) + ")"
          if ///^[a-z_][a-z_A-Z0-9]*$///.test attr.val
            # @bufferExpression "<?= ($_ = #{jsExpressionToPhp attr.val}) ? (' #{key}=\"' . #{if escaped then 'htmlspecialchars($_)' else '$_'} . '\"') : '' ?>"
            @bufferExpression "<?php attr('#{key}', #{jsExpressionToPhp attr.val}, #{if escaped then 'true' else 'false'}) ?>"
          else
            jsString = attr.val
            jadeString = jsString.replace(///^"///, '').replace(///"$///, '')
            jadeString = jadeString.replace ///"\s\+\s\(([^"]+)\)\s\+\s"///g, '#{$1}'
            @buffer " #{key}=\""
            @buffer jadeString, yes
            @buffer "\""
        else
          val = attr.val
          if escaped and (key.indexOf("data") isnt 0)
            val = "jade.escape(" + val + ")"
          else val = "(typeof (jade_interp = " + val + ") == \"string\" ? jade.escape(jade_interp) : jade_interp)"  if escaped
          buf.push utils.stringify(key) + ": " + val
      return
    ).bind(this)
    if buffer
      if classes.every(isConstant)
        @buffer runtime.cls(classes.map(toConstant), classEscaping)
      else
        # phpExpr = '<?php $_ = '

        # if classes.length > 1
        #   phpExpr += 'array(); '
        #   for classExpr in classes
        #     continue if classExpr is 'null' or classExpr is 'false'
        #     phpClassExpr = jsExpressionToPhp classExpr
        #     if ///^[a-z_][a-z_A-Z0-9\.]*///.test classExpr
        #       phpExpr += "if (is_array(#{phpClassExpr})) { $_ = array_merge($_, #{phpClassExpr}); } else { array_push($_, #{phpClassExpr}); } "
        #     else
        #       phpExpr += "array_push($_, #{phpClassExpr}); "
        # else
        #   phpClassExpr = jsExpressionToPhp classes[0]
        #   phpExpr += "is_array(#{phpClassExpr}) ? #{phpClassExpr} : array(#{phpClassExpr}); " 
        # phpExpr += '$_ = array_filter($_); if (!empty($_)) echo \' class="\' . join(" ", $_) . \'"\'; ?>'
        # @buffer phpExpr
        attrClassArgs = if classes.length is 1
          jsExpressionToPhp classes[0]
        else
          (jsExpressionToPhp c for c in classes).join ', '
        @buffer "<?php attr_class(#{attrClassArgs}) ?>"
    else if classes.length
      if classes.every(isConstant)
        classes = utils.stringify(runtime.joinClasses(classes.map(toConstant).map(runtime.joinClasses).map((cls, i) ->
          (if classEscaping[i] then runtime.escape(cls) else cls)
        )))
      else
        classes = "(jade_interp = " + utils.stringify(classEscaping) + "," + " jade.joinClasses([" + classes.join(",") + "].map(jade.joinClasses).map(function (cls, i) {" + "   return jade_interp[i] ? jade.escape(cls) : cls" + " }))" + ")"
      buf.push "\"class\": " + classes  if classes.length
    "{" + buf.join(",") + "}"