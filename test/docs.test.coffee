chai = require('chai')
chai.should()

pug = require 'pug'
pug2php = require '../src/pug2php'
exec = require 'sync-exec'
fs = require 'fs'

runPhp = (phpCode) ->
	tmpFilename = '__input.php'
	fs.writeFileSync tmpFilename, phpCode, 'utf-8'
	try
		output = exec("php #{tmpFilename}").stdout
	catch e
		console.error e
		console.error "Bad PHP code\n#{phpCode}"
		throw e
	fs.unlink tmpFilename
	output

test = (testName, pugSrc) ->
	it testName, ->
		referenceHtml = pug.render pugSrc
		phpTemplate = pug2php pugSrc
		testHtml = runPhp phpTemplate
		testHtml.should.eql referenceHtml

describe 'Pug Language Reference', ->

	it "PHP CLI utility must be installed", ->
		runPhp("<?php echo 'installed';").should.eql "installed"

	describe 'Plain Text', ->
		test 'Piped Text', """
			| Plain text can include <strong>html</strong>
			p
			  | It must always be on its own line
		"""
		test 'Inline in a Tag', """
			p Plain text can include <strong>html</strong>
		"""
		test 'Block in a Tag', """
			script.
			  if (usingPug)
			    console.log('you are awesome')
			  else
			    console.log('use pug')
		"""

	describe 'Tags', ->
		test 'Tags', """
			ul
			  li Item A
			  li Item B
			  li Item C
		"""
		test 'Predefined Self Closing Tags', 'img'
		test 'Block Expansion', 'a: img'
		test 'Self Closing Tags', """
			foo/
			foo(bar='baz')/
		"""

	describe 'Doctype', ->
		test 'Doctype', 'doctype html'
		test 'doctype html', 'doctype html'
		test 'doctype xml', 'doctype xml'
		test 'doctype transitional', 'doctype transitional'
		test 'doctype strict', 'doctype strict'
		test 'doctype frameset', 'doctype frameset'
		test 'doctype 1.1', 'doctype 1.1'
		test 'doctype basic', 'doctype basic'
		test 'doctype mobile', 'doctype mobile'
		test 'Custom Doctypes', 'doctype html PUBLIC "-//W3C//DTD XHTML Basic 1.1//EN"'
		# 'Doctype Option' is not tested

	describe 'Comments', ->
		test 'Comments', """
			// just some paragraphs
			p foo
			p bar
		"""
		test 'Unbuffered comments', """
			//- will not output within markup
			p foo
			p bar
		"""
		test 'Block Comments', """
			body
			  //
			    As much text as you want
			    can go here.
		"""
		test 'Conditional Comments', """
			<!--[if IE 8]>
			<html lang="en" class="lt-ie9">
			<![endif]-->
			<!--[if gt IE 8]><!-->
			<html lang="en">
			<!--<![endif]-->
		"""

	describe 'Attributes', ->
		test 'Attributes', """
			a(href='google.com') Google
			a(class='button', href='google.com') Google
		"""
		test 'Normal JavaScript expressions', """
			- var authenticated = true
			body(class=authenticated ? 'authed' : 'anon')
		"""
		test 'Spread them across many lines', """
			input(
			  type='checkbox'
			  name='agreement'
			  checked
			)
		"""
		test 'Unescaped Attributes', """
			div(escaped="<code>")
			div(unescaped!="<code>")
		"""
		test 'Boolean Attributes', """
			input(type='checkbox', checked)
			input(type='checkbox', checked=true)
			input(type='checkbox', checked=false)
			input(type='checkbox', checked=true.toString())
		"""
		test 'Boolean Attributes terse style when doctype html', """
			doctype html
			input(type='checkbox', checked)
			input(type='checkbox', checked=true)
			input(type='checkbox', checked=false)
			input(type='checkbox', checked=true && 'checked')
		"""
		test 'Class Attributes', """
			- var classes = ['foo', 'bar', 'baz']
			a(class=classes)
			//- the class attribute may also be repeated to merge arrays
			a.bing(class=classes class=['bing'])
		"""
		test 'Class Literal', 'a.button'
		test 'Class Literal (default tag is div)', '.content'
		test 'ID Literal', 'a#main-link'
		test 'ID Literal (default tag is div)', '#content'
		test '&attributes', """
			div#foo(data-bar="foo")&attributes({'data-foo': 'bar'})
		"""
		test '&attributes(variable)', """
			- var attributes = {'data-foo': 'bar'};
			div#foo(data-bar="foo")&attributes(attributes)
		"""
	
	describe 'Code & Interpolation', ->
		test 'Unbuffered Code', """
			- for (var x = 0; x < 3; x++)
			  li item
		"""
		test 'Buffered Code', """
			p
			  = 'This code is <escaped>!'
		"""
		test 'Buffered Code (JavaScript expressions)', """
			p= 'This code is' + ' <escaped>!'
		"""
		test 'Unescaped Buffered Code', """
			p
			  != 'This code is <strong>not</strong> escaped!'
		"""
		test 'Unescaped Buffered Code (JavaScript expressions)', """
			p!= 'This code is <strong>not</strong> escaped!'
		"""
		test 'Interpolation', """
			- var user = {name: 'Forbes Lindesay'}
			p Welcome \#{user.name}
		"""
		test 'Unescaped Interpolation', """
			- var user = {name: '<strong>Forbes Lindesay</strong>'}
			p Welcome \#{user.name}
			p Welcome !{user.name}
		"""

	describe 'Conditionals', ->
		test 'Conditionals', """
			- var user = { description: 'foo bar baz' }
			- var authorised = false
			#user
			  if user.description
			    h2 Description
			    p.description= user.description
			  else if authorised
			    h2 Description
			    p.description.
			      User has no description,
			      why not add one...
			  else
			    h1 Description
			    p.description User has no description
		"""
		test "Unless", """
			- var user = { name: 'Username' }
			unless user.isAnonymous
			  p You're logged in as \#{user.name}
		"""

	describe 'Case', ->
		test 'Case', """
			- var friends = 10
			case friends
			  when 0
			    p you have no friends
			  when 1
			    p you have a friend
			  default
			    p you have \#{friends} friends
		"""
		test 'Case Fall Through', """
			- var friends = 0
			case friends
			  when 0
			  when 1
			    p you have very few friends
			  default
			    p you have \#{friends} friends
		"""
		test 'Block Expansion', """
			- var friends = 1
			case friends
			  when 0: p you have no friends
			  when 1: p you have a friend
			  default: p you have \#{friends} friends
		"""

	describe 'Iteration', ->
		test 'each', """
			ul
			  each val in [1, 2, 3, 4, 5]
			    li= val
		"""
		test 'index', """
			ul
			  each val, index in ['zero', 'one', 'two']
			    li= index + ': ' + val
		"""
		test 'keys', """
			ul
			  each val, index in {1:'one',2:'two',3:'three'}
			    li= index + ': ' + val
		"""
		test 'tern', """
			- var values = [];
			ul
			  each val in values.length ? values : ['There are no values']
			    li= val
		"""
		test 'while', """
			- var n = 0
			ul
			  while n < 4
			    li= n++
		"""

	describe 'Mixins', ->
		test 'Mixins', """
			//- Declaration
			mixin list
			  ul
			    li foo
			    li bar
			    li baz
			//- Use
			+list
			+list
		"""
		test 'Mixins with arguments', """
			mixin pet(name)
			  li.pet= name
			ul
			  +pet('cat')
			  +pet('dog')
			  +pet('pig')
		"""
		test 'Mixin Blocks', """
			mixin article(title)
			  .article
			    .article-wrapper
			      h1= title
			      if block
			        block
			      else
			        p No content provided

			+article('Hello world')

			+article('Hello world')
			  p This is my
			  p Amazing article
		"""
		test 'Mixin Attributes', """
			mixin link(href, name)
			  //- attributes == {class: "btn"}
			  a(class!=attributes.class, href=href)= name

			+link('/foo', 'foo')(class="btn")
		"""
		test 'Mixin &attributes', """
			mixin link(href, name)
			  a(href=href)&attributes(attributes)= name

			+link('/foo', 'foo')(class="btn")
		"""
		test 'Rest Arguments', """
			mixin list(id, ...items)
			  ul(id=id)
			    each item in items
			      li= item

			+list('my-list', 1, 2, 3, 4)
		"""

	describe "mixin with null params", ->
		test "should render same", """
			mixin user(name)
				.user(data-name=name)= name

			+user("one")
			+user
			+user("two")
			+user(null)
		"""
