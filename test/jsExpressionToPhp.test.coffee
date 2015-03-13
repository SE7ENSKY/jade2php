chai = require('chai')
chai.should()

jsExpressionToPhp = require '../src/jsExpressionToPhp'

test = (js, referencePhp, opts = {}) ->
	jsExpressionToPhp(js, opts).should.eql referencePhp

describe 'jsExpressionToPhp', ->

	it 'should transpile simple types', ->
		test 'null', 'null'
		test '0', '0'
		test '1', '1'
		test '""', '""'
		test '"one"', '"one"'
		test '\'two\'', '\'two\''
		test '"1"', '"1"'
		test 'true', 'true'
		test 'false', 'false'

	it 'should transpile variables', ->
		test 'a', '$a'
		test 'abc', '$abc'
		test 'ab1c', '$ab1c'

	it 'should transpile calls', ->
		test 'a()', 'a()'
		test 'abc()', 'abc()'
		test 'ab(1)', 'ab(1)'
		test 'ab(1, "aa")', 'ab(1, "aa")'

	it 'should transpile access dots', ->
		test 'a.b', "$a['b']"
		test 'a.b.c', "$a['b']['c']"
		test 'a.b.c.d5', "$a['b']['c']['d5']"

	it 'should support array index', ->
		test 'a[0]', '$a[0]'

	it 'should transpile mixed access and calls', ->
		test 'a.b(c.d.e).f(g)', "$a['b']($c['d']['e'])['f']($g)"

	it 'should transpile concatenation', ->
		test '"a" + "b"', "add(\"a\", \"b\")"
		test '5 + "b"', "add(5, \"b\")"
		test '1 + 2 + "b" + 4', "add(1, 2, \"b\", 4)"
		test 'a + "b" + "c"', 'add($a, "b", "c")'

	it 'should transpile concatenation + access', ->
		test 'a + a.b + "c" + d.e.f', "add($a, $a['b'], \"c\", $d['e']['f'])"


	it 'should correctly transpile concatenation + calls + arrays', ->
		test '[a, "b", a + "b", a + "b" + "c"]', 'array($a, "b", add($a, "b"), add($a, "b", "c"))'

	it 'should support concatenation with brackets', ->
		test """
			['item','col-sm-4',"delivery-steps__item_" + (deliveryProcessItem.class) + ""]
		""", "array('item', 'col-sm-4', add(\"delivery-steps__item_\", $deliveryProcessItem['class'], \"\"))"

	it 'other tests', ->
		test '"icon-" + icon + ""', "add(\"icon-\", $icon, \"\")"

	it 'support arraysOnly=false option', ->
		test 'a + a.b + "c" + d.e.f', "add($a, $a->b, \"c\", $d->e->f)",
			arraysOnly: false
		test 'a.b(c.d)', '$a->b($c->d)',
			arraysOnly: false

	it 'should not get confused by "+" sings inside strings', ->
		test "'' + '+420'", "add('', '+420')"
