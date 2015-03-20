chai = require('chai')
chai.should()

jade = require 'jade'
jade2php = require '../src/jade2php'

describe 'JadePhpCompiler', ->
	c = (jadeSrc, referenceCode, opts = null) ->
		opts or= 
			omitPhpRuntime: yes
			omitPhpExtractor: yes
		compiledPhp = jade2php jadeSrc, opts
		compiledPhp.should.eql referenceCode

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
			c 'div(data-value=someValue)', "<div<?php attr('data-value', $someValue, true) ?>></div>"
		
		it 'should support attr unescaped values', ->
			c 'div(data-value!=someValue)', "<div<?php attr('data-value', $someValue, false) ?>></div>"
		
		it 'should support tag text', ->
			c 'div= someText', '<div><?= htmlspecialchars($someText) ?></div>'

		it 'should support tag unescaped text', ->
			c 'div!= someText', '<div><?= $someText ?></div>'

		it 'should support several attrs and text', ->
			c 'a(href=url, title=title)= title', "<a<?php attr('href', $url, true) ?><?php attr('title', $title, true) ?>><?= htmlspecialchars($title) ?></a>"

	describe 'string interpolation', ->

		it 'should support simple string output', ->
			c '= "Hello world!"', '<?= htmlspecialchars("Hello world!") ?>'
			c "= 'Hello world!'", "<?= htmlspecialchars('Hello world!') ?>"
			c 'div= "Hello world!"', '<div><?= htmlspecialchars("Hello world!") ?></div>'
			c "div= 'Hello world!'", "<div><?= htmlspecialchars('Hello world!') ?></div>"
		
		it 'should support simple unsecaped string output', ->
			c '!= "Hello world!"', '<?= "Hello world!" ?>'
			c "!= 'Hello world!'", "<?= 'Hello world!' ?>"
			c 'div!= "Hello world!"', '<div><?= "Hello world!" ?></div>'
			c "div!= 'Hello world!'", "<div><?= 'Hello world!' ?></div>"

		it 'should support simple interpolation with variable', ->
			c '.greeting Hello, \#{name}!', '<div class="greeting">Hello, <?= htmlspecialchars($name) ?>!</div>'
			c '.greeting Hello, !{name}!', '<div class="greeting">Hello, <?= $name ?>!</div>'
			c '.greeting Hello, #{firstName} #{lastName}!', '<div class=\"greeting\">Hello, <?= htmlspecialchars($firstName) ?> <?= htmlspecialchars($lastName) ?>!</div>'

		it 'should support simple attr interpolation with variable', ->
			c 'article(id="post-#{id}")', '<article id="post-<?= htmlspecialchars($id) ?>"></article>'
			c 'article(id="post-#{type}-#{id}")', '<article id="post-<?= htmlspecialchars($type) ?>-<?= htmlspecialchars($id) ?>"></article>'
			c 'article(id="post-#{type}-#{id}") Post \##{id} of type \'#{type}\'', '<article id="post-<?= htmlspecialchars($type) ?>-<?= htmlspecialchars($id) ?>">Post #<?= htmlspecialchars($id) ?> of type \'<?= htmlspecialchars($type) ?>\'</article>'
			
			# jade not support this :(
			# c 'article(id="post-!{idNumber}")', '<article id="post-<?= $idNumber ?>"></article>'

	describe 'control statements', ->
		describe 'condition', ->
			describe 'if', ->
				it 'simple', ->
					c """
						if testCondition
							.test-result passed
					""", '<?php if ($testCondition) : ?><div class="test-result">passed</div><?php endif ?>'
				it 'with else', ->
					c """
						if testCondition
							.test-result passed
						else
							.error failed
					""", '<?php if ($testCondition) : ?><div class="test-result">passed</div><?php else : ?><div class="error">failed</div><?php endif ?>'
				it 'several if-else-if-else-if-else', ->
					c """
						if testCondition
							.test-result passed
						else if another1TestCondition
							.test-result another 1
						else if another2TestCondition
							.test-result another 2
					""", '<?php if ($testCondition) : ?><div class="test-result">passed</div><?php elseif ($another1TestCondition) : ?><div class="test-result">another 1</div><?php elseif ($another2TestCondition) : ?><div class="test-result">another 2</div><?php endif ?>'
					c """
						.test-result
							if testCondition
								| passed
							else if another1TestCondition
								| another 1
							else if another2TestCondition
								| another 2
							else
								| failed
					""", '<div class="test-result"><?php if ($testCondition) : ?>passed<?php elseif ($another1TestCondition) : ?>another 1<?php elseif ($another2TestCondition) : ?>another 2<?php else : ?>failed<?php endif ?></div>'
					c """
						.test-result
							if oneBranch
								| one
							else
								| not one
							if anotherBranch
								| another
							if anyBranch
								| any
							else
								| what?
					""", '<div class="test-result"><?php if ($oneBranch) : ?>one<?php else : ?>not one<?php endif ?><?php if ($anotherBranch) : ?>another<?php endif ?><?php if ($anyBranch) : ?>any<?php else : ?>what?<?php endif ?></div>'
				it 'support negated if – unless', ->
					c """
						unless a
							| not a
						else
							| a
					""", '<?php if (!$a) : ?>not a<?php else : ?>a<?php endif ?>'
			describe 'case', ->
				it 'string comparisons', ->
					c """
						case mode
							when "simple"
								hr.simple
							when "advanced"
								hr.advanced
					""", '<?php switch ($mode) : ?><?php case "simple" : ?><hr class="simple"/><?php break ?><?php case "advanced" : ?><hr class="advanced"/><?php break ?><?php endswitch ?>'
				it 'numeric comparisons', ->
					c """
						case count
							when 2
								| two
							when 1
								| one
							when 0
								| zero
					""", '<?php switch ($count) : ?><?php case 2 : ?>two<?php break ?><?php case 1 : ?>one<?php break ?><?php case 0 : ?>zero<?php break ?><?php endswitch ?>'
				it 'default comparisons', ->
					c """
						case count
							when 1
								| single
							default
								| unknown count
					""", '<?php switch ($count) : ?><?php case 1 : ?>single<?php break ?><?php default : ?>unknown count<?php endswitch ?>'
		describe 'iteration', ->
			it 'simple', ->
				c """
					each user in users
						.user= user
				""", '<?php if ($users) : foreach ($users as $user) : $■[\'user\'] = $user; ?><div class="user"><?= htmlspecialchars($user) ?></div><?php endforeach; endif ?>'
			it 'simple with indexing', ->
				c """
					each value, key in options
						.option \#{key}: \#{value}
				""", '<?php if ($options) : foreach ($options as $key => $value) : $■[\'key\'] = $key;$■[\'value\'] = $value; ?><div class="option"><?= htmlspecialchars($key) ?>: <?= htmlspecialchars($value) ?></div><?php endforeach; endif ?>'
			it 'alternative', ->
				c """
					each user in users
						.user= user
					else
						.error No users found
				""", '<?php if ($users) : foreach ($users as $user) : $■[\'user\'] = $user; ?><div class="user"><?= htmlspecialchars($user) ?></div><?php endforeach; else : ?><div class="error">No users found</div><?php endif ?>'

	describe 'code node', ->
		it 'simple', ->
			c """
				- var name = "NodeJS"
				h1 Hello, \#{name}!
			""", '<?php $name = "NodeJS" ?><h1>Hello, <?= htmlspecialchars($name) ?>!</h1>'
			
			c """
				- var firstName = "Node"
				- var lastName = "JS"
				h1 Hello, \#{firstName} \#{lastName}!
			""", '<?php $firstName = "Node" ?><?php $lastName = "JS" ?><h1>Hello, <?= htmlspecialchars($firstName) ?> <?= htmlspecialchars($lastName) ?>!</h1>'

	describe 'class attribute', ->
		it 'simple', ->
			c """
				- var someClasses = null
				p(class=someClasses)

				- var someClasses = []
				p(class=someClasses, class="test")

				- var someClasses = ["single-ended", "push-pull"]
				p(class=someClasses)

			""", "<?php $someClasses = null ?><p<?php attr_class($someClasses) ?>></p><?php $someClasses = array() ?><p<?php attr_class($someClasses, \"test\") ?>></p><?php $someClasses = array(\"single-ended\", \"push-pull\") ?><p<?php attr_class($someClasses) ?>></p>"

	describe 'mixins', ->
		it 'simple', ->
			c """
				mixin user
					.user

				+user()
				+user()
			""", "<?php if (!function_exists('mixin__user')) { function mixin__user($block = null, $attributes = null) { ?><div class=\"user\"></div><?php } } ?><?php mixin__user() ?><?php mixin__user() ?>"
		it 'with args', ->
			c """
				mixin user(name)
					.user= name

				+user("Node")
				+user("JS")
				+user("PHP")
			""", "<?php if (!function_exists('mixin__user')) { function mixin__user($block = null, $attributes = null, $name = null) { global $■;$■['name'] = $name;?><div class=\"user\"><?= htmlspecialchars($name) ?></div><?php } } ?><?php mixin__user(null, null, \"Node\") ?><?php mixin__user(null, null, \"JS\") ?><?php mixin__user(null, null, \"PHP\") ?>"
		it 'name with dashes', ->
			c """
				mixin user-name(firstName, lastName)
					span.user-name !{firstName} !{lastName}

				+user-name("Node", "JS")
				+user-name("Jade", "PHP")
			""", "<?php if (!function_exists('mixin__user_name')) { function mixin__user_name($block = null, $attributes = null, $firstName = null, $lastName = null) { global $■;$■['firstName'] = $firstName;$■['lastName'] = $lastName;?><span class=\"user-name\"><?= $firstName ?> <?= $lastName ?></span><?php } } ?><?php mixin__user_name(null, null, \"Node\", \"JS\") ?><?php mixin__user_name(null, null, \"Jade\", \"PHP\") ?>"

		it 'support mixin blocks', ->
			c """
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
			""", "<?php if (!function_exists('mixin__article')) { function mixin__article($block = null, $attributes = null, $title = null) { global $■;$■['title'] = $title;?><div class=\"article\"><div class=\"article-wrapper\"><h1><?= htmlspecialchars($title) ?></h1><?php if ($block) : ?><?php if (is_callable($block)) $block(); ?><?php else : ?><p>No content provided</p><?php endif ?></div></div><?php } } ?><?php mixin__article(null, null, 'Hello world') ?><?php mixin__article(function(){ ?><p>This is my</p><p>Amazing article</p><?php }, null, 'Hello world') ?>"

		it 'support call mixin inside mixin with blocks', ->
			c """
				mixin content
					if block
						block
					else
						p No content provided

				mixin article(title)
					.article
						.article-wrapper
							h1= title
							+content
								block

				+article('Hello world')

				+article('Hello world')
					p This is my
					p Amazing article
			""", "<?php if (!function_exists('mixin__content')) { function mixin__content($block = null, $attributes = null) { ?><?php if ($block) : ?><?php if (is_callable($block)) $block(); ?><?php else : ?><p>No content provided</p><?php endif ?><?php } } ?><?php if (!function_exists('mixin__article')) { function mixin__article($block = null, $attributes = null, $title = null) { global $■;$■['title'] = $title;?><div class=\"article\"><div class=\"article-wrapper\"><h1><?= htmlspecialchars($title) ?></h1><?php mixin__content(function() use ($block) { ?><?php if (is_callable($block)) $block(); ?><?php }) ?></div></div><?php } } ?><?php mixin__article(null, null, 'Hello world') ?><?php mixin__article(function(){ ?><p>This is my</p><p>Amazing article</p><?php }, null, 'Hello world') ?>"

		it 'support rest params', ->
			c """
				mixin sum(a, b, ...other)
					- var result = a + b
					each number in other
						- result += number
					.sum= result

				+sum(1, 2)
				+sum(5, 5, 12)
				+sum(5, 5, 12, 1)
			""", "<?php if (!function_exists('mixin__sum')) { function mixin__sum($block = null, $attributes = null, $a = null, $b = null) { $other = array_slice(func_get_args(), 4); global $■;$■['a'] = $a;$■['b'] = $b;?><?php $result = add($a, $b) ?><?php if ($other) : foreach ($other as $number) : $■['number'] = $number; ?><?php $result += $number ?><?php endforeach; endif ?><div class=\"sum\"><?= htmlspecialchars($result) ?></div><?php } } ?><?php mixin__sum(null, null, 1, 2) ?><?php mixin__sum(null, null, 5, 5, 12) ?><?php mixin__sum(null, null, 5, 5, 12, 1) ?>"

			c """
				mixin list(id, ...items)
					ul(id=id)
						each item in items
							li= item

				+list('my-list', 1, 2, 3, 4)
			""", "<?php if (!function_exists('mixin__list')) { function mixin__list($block = null, $attributes = null, $id = null) { $items = array_slice(func_get_args(), 3); global $■;$■['id'] = $id;?><ul<?php attr('id', $id, true) ?>><?php if ($items) : foreach ($items as $item) : $■['item'] = $item; ?><li><?= htmlspecialchars($item) ?></li><?php endforeach; endif ?></ul><?php } } ?><?php mixin__list(null, null, 'my-list', 1, 2, 3, 4) ?>"

	describe "other mixed tests", ->
		it 'mixin + class attrs + interpolation', ->
			c """
				+e("li").item.col-sm-4(class="delivery-steps__item_\#{deliveryProcessItem.class}")
			""", "<?php mixin__e(null, array('class' => array('item', 'col-sm-4', add(\"delivery-steps__item_\", $deliveryProcessItem['class'], \"\"))), \"li\") ?>"

	describe "pretty option", ->
		it "should be ignored", ->
			c """
				doctype html
			""", "<!DOCTYPE html>",
				pretty: yes
				omitPhpRuntime: yes
				omitPhpExtractor: yes

	describe "raw tag inserting", ->
		it "should work :)", ->
			c """
				doctype html
				html
					head
						title test
					<body !{bodyAttributes}>
					header
					main
						article
					footer
					</body>
			""", '<!DOCTYPE html><html><head><title>test</title></head><body <?= $bodyAttributes ?>><header></header><main><article></article></main><footer></footer></body></html>'
