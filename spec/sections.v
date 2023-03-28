module spec

import whisker { DataModel }

pub const section_test = TestList{
	name: 'Sections'
	overview: ''
	tests: [
		TestCase{
			name: 'True Boolean Section'
			desc: 'True boolean sections should have their contents displayed.'
			template: '"{{+boolean}}This should be rendered.{{/boolean}}"'
			expected: '"This should be rendered."'
			data: DataModel({
				'boolean': DataModel(true)
			})
		},
		TestCase{
			name: 'False Boolean Section'
			desc: 'False boolean sections should not have their contents displayed.'
			template: '"{{+boolean}}This should not be rendered.{{/boolean}}"'
			expected: '""'
			data: DataModel({
				'boolean': DataModel(false)
			})
		},
		TestCase{
			name: 'Guard Sections Positive'
			desc: 'Use positive boolean sections to indicate presence of data.'
			data: DataModel({
				'has_name': DataModel(true)
				'name':     DataModel('Joe')
			})
			template: '"{{+has_name}}Hi {{name}}.{{/has_name}}"'
			expected: '"Hi Joe."'
		},
		TestCase{
			name: 'Guard Sections Negative'
			desc: 'Use positive negative sections to indicate presence of data.'
			data: DataModel({
				'has_name': DataModel(false)
			})
			template: '"{{+has_name}}Hi {{name}}.{{/has_name}}{{-has_name}}Hi user.{{/has_name}}"'
			expected: '"Hi user."'
		},
		TestCase{
			name: 'Simple Map Section'
			desc: 'Simple map keys can be queried properly.'
			data: DataModel({
				'person': DataModel({
					'name':   DataModel('Subhomoy')
					'age':    '24'
					'indian': true
				})
			})
			template: "{{#person}}
		My name is {{name}}.
		I am {{age}} years old.
		{{+indian}}I'm from India{{/indian}}
		{{/person}}
		"
			expected: "
		My name is Subhomoy.
		I am 24 years old.
		I'm from India
		"
		},
		TestCase{
			name: 'Context'
			desc: 'Objects and hashes should be pushed onto the context stack.'
			data: DataModel({
				'context': DataModel({
					'name': DataModel('Joe')
				})
			})
			template: '"{{#context}}Hi {{name}}.{{/context}}"'
			expected: '"Hi Joe."'
		},
		TestCase{
			name: 'Parent Context'
			desc: 'Names missing in the current context are looked up in the stack.'
			data: DataModel({
				'a':   DataModel('foo')
				'b':   'wrong'
				'sec': {
					'b': DataModel('bar')
				}
				'c':   {
					'd': DataModel('baz')
				}
			})
			template: '"{{#sec}}{{a}}, {{b}}, {{c.d}}{{/sec}}"'
			expected: '"foo, bar, baz"'
		},
		TestCase{
			name: 'Variable Test'
			desc: 'Valid boolean sections should have their value available at the top of the context stack. This value must be accessible by {{.}}'
			data: DataModel({
				'check1': DataModel(false)
				'check2': true
			})
			template: '{{-check1}}{{.}}{{/check1}} and {{+check2}}{{.}}{{/check2}}'
			expected: 'false and true'
		},
		TestCase{
			name: 'Deeply Nested Contexts'
			desc: ''
			data: DataModel({
				'a': DataModel({
					'one': DataModel('1')
				})
				'b': {
					'two': DataModel('2')
				}
				'c': {
					'three': DataModel('3')
					'd':     {
						'four': DataModel('4')
						'five': DataModel('5')
					}
				}
			})
			template: '
		{{#a}}
		{{one}}
		{{#b}}
		{{one}}{{two}}{{one}}
		{{#c}}
		{{one}}{{two}}{{three}}{{two}}{{one}}
		{{#d}}
		{{one}}{{two}}{{three}}{{four}}{{three}}{{two}}{{one}}
		{{one}}{{two}}{{three}}{{four}}{{five}}{{four}}{{three}}{{two}}{{one}}
		{{one}}{{two}}{{three}}{{four}}{{five}}6{{five}}{{four}}{{three}}{{two}}{{one}}
		{{one}}{{two}}{{three}}{{four}}{{five}}{{four}}{{three}}{{two}}{{one}}
		{{one}}{{two}}{{three}}{{four}}{{three}}{{two}}{{one}}
		{{/d}}
		{{one}}{{two}}{{three}}{{two}}{{one}}
		{{/c}}
		{{one}}{{two}}{{one}}
		{{/b}}
		{{one}}
		{{/a}}
		'
			expected: '
		1
		121
		12321
		1234321
		123454321
		12345654321
		123454321
		1234321
		12321
		121
		1
		'
		},
		TestCase{
			name: 'Doubled'
			desc: 'Multiple sections per template should be permitted.'
			data: DataModel({
				'bool': DataModel(true)
				'two':  DataModel('second')
			})
			template: '
		{{+bool}}
		* first
		{{/bool}}
		* {{two}}
		{{+bool}}
		* third
		{{/bool}}
		'
			expected: '
		* first
		* second
		* third
		'
		},
		TestCase{
			name: 'Empty List'
			desc: 'Empty list should be skipped over.'
			data: DataModel({
				'sample': DataModel('vibe')
				'empty':  []DataModel{}
			})
			template: '{{sample}}{{*empty}}{{sample}}{{/empty}}'
			expected: 'vibe'
		},
		TestCase{
			name: 'List'
			desc: 'Lists should be iterated; list items should visit the context stack.'
			data: DataModel({
				'list': DataModel([DataModel({
					'item': DataModel('1')
				}), {
					'item': DataModel('2')
				}, {
					'item': DataModel('3')
				}])
			})
			template: '"{{*list}}{{item}}{{/list}}"'
			expected: '"123"'
		},
	]
}
