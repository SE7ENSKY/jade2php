chai = require('chai')
chai.should()

describe 'JadePhpCompiler', ->
	JadePhpCompiler = null
	jade = null

	describe 'dependencies and methods', ->
		it 'jade is present', ->
			jade = require 'jade'
			jade.should.not.eql.null
		it 'should be defined', ->
			JadePhpCompiler = require '../src/JadePhpCompiler'
			JadePhpCompiler.should.not.eql.null
		it 'have .compile method', ->
			JadePhpCompiler.prototype.compile.should.not.eql.null

	parse = (str, options = { filename: '' }) ->
		parser = new jade.Parser str, options.filename, options
		tokens = parser.parse()
		compiler = new JadePhpCompiler tokens, options
		compiler.compile()
	c = (jadeSrc, htmlOutput) ->
		parse(jadeSrc).should.eql(htmlOutput)

	describe 'rendering simple jade syntax into vanilla html', ->

		it 'should support simple text', ->
			c "| Hello world!", "Hello world!"

		it 'should support simple tags', ->
			c "p", "<p></p>"
			c "div", "<div></div>"
			c "span", "<span></span>"

		it 'should support self-closing tags', ->
			c "hr", "<hr/>"
			c "br", "<br/>"
		
		it 'should support doctypes', ->
			c "doctype html", "<!DOCTYPE html>"
			c "doctype xml", '<?xml version="1.0" encoding="utf-8" ?>'
			c "doctype strict", '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">'
		
		it 'should support tags with text', ->
			c 'p Hello world!', '<p>Hello world!</p>'
			c 'p\n\t| Hello world!', '<p>Hello world!</p>'
			c 'p\n\t| Hello world!\n\t| Again!', '<p>Hello world!\nAgain!</p>'
			c 'div.\n\tHello world!', '<div>Hello world!</div>'
		
		it 'should support tags with attrs', ->
			c 'option(value="5")', '<option value="5"></option>'
			c 'option(value="5", data-src="http://test.com/example.png")', '<option value="5" data-src="http://test.com/example.png"></option>'
		
		it 'should support classes via dot notation', ->
			c "p.lead", '<p class="lead"></p>'
			c "p.lead.big", '<p class="lead big"></p>'
		
		it 'should support ids via sharp notation', ->
			c 'nav#main-nav', '<nav id="main-nav"></nav>'
			c "br#separator", '<br id="separator"/>'
		
		it 'should support nested tags', ->
			c 'div: div', '<div><div></div></div>'
			c 'div#one: div#two.inner\n\t#three Hello world!', '<div id="one"><div id="two" class="inner"><div id="three">Hello world!</div></div></div>'

	describe 'rendering simple expressions', ->

		it 'should support simple output', ->
			c '= value', '<?= htmlspecialchars($value) ?>'

		it 'should support simple unescaped output', ->
			c '!= value', '<?= $value ?>'

		it 'should support attr values', ->
			c 'div(data-value=someValue)', "<div<?= ($_ = $someValue) ? (' data-value=\"' . htmlspecialchars($_) . '\"') : '' ?>></div>"
		
		it 'should support attr unescaped values', ->
			c 'div(data-value!=someValue)', "<div<?= ($_ = $someValue) ? (' data-value=\"' . $_ . '\"') : '' ?>></div>"
		
		it 'should support tag text', ->
			c 'div= someText', '<div><?= htmlspecialchars($someText) ?></div>'

		it 'should support tag unescaped text', ->
			c 'div!= someText', '<div><?= $someText ?></div>'

		it 'should support several attrs and text', ->
			c 'a(href=url, title=title)= title', "<a<?= ($_ = $url) ? (' href=\"' . htmlspecialchars($_) . '\"') : '' ?><?= ($_ = $title) ? (' title=\"' . htmlspecialchars($_) . '\"') : '' ?>><?= htmlspecialchars($title) ?></a>"

	describe 'string interpolation', ->

		it 'should support simple string output', ->
			c '= "Hello world!"', '<?= htmlspecialchars("Hello world!") ?>'
			c '= \'Hello world!\'', '<?= htmlspecialchars("Hello world!") ?>'
			c 'div= "Hello world!"', '<div><?= htmlspecialchars("Hello world!") ?></div>'
			c 'div= \'Hello world!\'', '<div><?= htmlspecialchars("Hello world!") ?></div>'
		
		it 'should support simple unsecaped string output', ->
			c '!= "Hello world!"', 'Hello world!'
			c '!= \'Hello world!\'', 'Hello world!'
			c 'div!= "Hello world!"', '<div>Hello world!</div>'
			c 'div!= \'Hello world!\'', '<div>Hello world!</div>'

		it 'should support simple interpolation with variable', ->
			c '.greeting Hello, \#{name}!', '<div class="greeting">Hello, <?= htmlspecialchars($name) ?>!</div>'
			c '.greeting Hello, !{name}!', '<div class="greeting">Hello, <?= $name ?>!</div>'
			c '.greeting Hello, #{firstName} #{lastName}!', '<div class=\"greeting\">Hello, <?= htmlspecialchars($firstName) ?> <?= htmlspecialchars($lastName) ?>!</div>'

		it 'should support simple attr interpolation with variable', ->
			c 'article(id="post-#{id}")', '<article id="post-<?= htmlspecialchars($id) ?>"></article>'
			c 'article(id="post-!{id}")', '<article id="post-<?= $id ?>"></article>'
