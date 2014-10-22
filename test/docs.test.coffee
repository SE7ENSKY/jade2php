chai = require('chai')
chai.should()

jade = require 'jade'
jade2php = require '../src/jade2php'
execSync = require 'exec-sync'
fs = require 'fs'

runPhp = (phpCode) ->
	tmpFilename = '__input.php'
	fs.writeFileSync tmpFilename, phpCode, 'utf-8'
	try
		output = execSync "php #{tmpFilename}"
	catch e
		console.error e
		console.error "Bad PHP code\n#{phpCode}"
		throw e
	fs.unlink tmpFilename
	output

test = (testName, jadeSrc) ->
	it testName, ->
		referenceHtml = jade.render jadeSrc
		phpTemplate = jade2php jadeSrc
		testHtml = runPhp phpTemplate
		testHtml.should.eql referenceHtml

describe 'Jade Language Reference', ->

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
			  if (usingJade)
			    console.log('you are awesome')
			  else
			    console.log('use jade')
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
		# test '&attributes', """
		# 	div#foo(data-bar="foo")&attributes({'data-foo': 'bar'})
		# """
		# test '&attributes(variable)', """
		# 	- var attributes = {'data-foo': 'bar'};
		# 	div#foo(data-bar="foo")&attributes(attributes)
		# """
