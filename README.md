jade2php
========

Unlock Jade for PHP! Convert Jade templates into raw PHP templates. CLI tool and JavaScript API. Test covered.
[**Gulp plugin**](https://github.com/viktorbezdek/gulp-jade2php) available.

## Purpose
Write Jade templates, parse them with original Jade parser (not a PHP port) and convert into equivalent PHP templates.

## Getting started
* install [**gulp**-jade2php](https://github.com/viktorbezdek/gulp-jade2php): `npm install --save gulp-jade2php`
* install command line utility: `npm install -g jade2php`
* install node module for API usage: `npm install --save jade2php`

## Features
Full support for all Jade features is maintained through unit testing, based on Language Reference.
```
Jade Language Reference
  Plain Text
    ✓ Piped Text
    ✓ Inline in a Tag
    ✓ Block in a Tag
  Tags
    ✓ Tags
    ✓ Predefined Self Closing Tags
    ✓ Block Expansion
    ✓ Self Closing Tags
  Doctype
    ✓ Doctype
    ✓ doctype html
    ✓ doctype xml
    ✓ doctype transitional
    ✓ doctype strict
    ✓ doctype frameset
    ✓ doctype 1.1
    ✓ doctype basic
    ✓ doctype mobile
    ✓ Custom Doctypes
  Comments
    ✓ Comments
    ✓ Unbuffered comments
    ✓ Block Comments
    ✓ Conditional Comments
  Attributes
    ✓ Attributes
    ✓ Normal JavaScript expressions
    ✓ Spread them across many lines
    ✓ Unescaped Attributes
    ✓ Boolean Attributes
    ✓ Boolean Attributes terse style when doctype html
    ✓ Class Attributes
    ✓ Class Literal
    ✓ Class Literal (default tag is div)
    ✓ ID Literal
    ✓ ID Literal (default tag is div)
    ✓ &attributes
    ✓ &attributes(variable)
  Code & Interpolation
    ✓ Unbuffered Code
    ✓ Buffered Code
    ✓ Buffered Code (JavaScript expressions)
    ✓ Unescaped Buffered Code
    ✓ Unescaped Buffered Code (JavaScript expressions)
    ✓ Interpolation
    ✓ Unescaped Interpolation
  Conditionals
    ✓ Conditionals
    ✓ Unless
  Case
    ✓ Case
    ✓ Case Fall Through
    ✓ Block Expansion
  Iteration
    ✓ each
    ✓ index
    ✓ keys
    ✓ tern
    ✓ while
  Mixins
    ✓ Mixins
    ✓ Mixins with arguments
    ✓ Mixin Blocks
    ✓ Mixin Attributes
    ✓ Mixin &attributes
    ✓ Rest Arguments
```
Additional, code-level checks
```
JadePhpCompiler
  rendering simple jade syntax into vanilla html
    ✓ should support simple text 
    ✓ should support simple tags 
    ✓ should support self-closing tags 
    ✓ should support doctypes 
    ✓ should support tags with text 
    ✓ should support tags with attrs 
    ✓ should support classes via dot notation 
    ✓ should support ids via sharp notation 
    ✓ should support nested tags 
  rendering simple expressions
    ✓ should support simple output 
    ✓ should support simple unescaped output 
    ✓ should support attr values 
    ✓ should support attr unescaped values 
    ✓ should support tag text 
    ✓ should support tag unescaped text 
    ✓ should support several attrs and text 
  string interpolation
    ✓ should support simple string output 
    ✓ should support simple unsecaped string output 
    ✓ should support simple interpolation with variable 
    ✓ should support simple attr interpolation with variable 
  control statements
    condition
      if
        ✓ simple 
        ✓ with else 
        ✓ several if-else-if-else-if-else 
        ✓ support negated if – unless 
      case
        ✓ string comparisons 
        ✓ numeric comparisons 
        ✓ default comparisons 
    iteration
      ✓ simple 
      ✓ simple with indexing 
      ✓ alternative 
  code node
    ✓ simple 
  class attribute
    ✓ simple 
  mixins
    ✓ simple 
    ✓ with args 
    ✓ name with dashes 
    ✓ support mixin blocks 
    ✓ support call mixin inside mixin with blocks 
    ✓ support rest params
```

## Roadmap
* pretty php code option
* pretty html output option
* code cleanup

## License
MIT

## Running tests
PHP must be installed to run tests.
```bash
npm intall --dev
npm test
```

## Contributing
Pull requests, sharing experience and ideas are welcomed :)

## Contributors
* [Ivan Kravchenko](https://github.com/ivankravchenko) at [SE7ENSKY](https://github.com/SE7ENSKY)
* [Jan Wirth](https://github.com/FranzSkuffka)
* [Karol Heczko](https://github.com/KHC)
