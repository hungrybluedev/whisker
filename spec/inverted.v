module spec

import whisker { DataModel }

pub const inverted_test = TestList{
	name: 'Inverted Sections'
	overview: ''
	tests: [
		TestCase{
			name: 'False Boolean Value'
			desc: 'False Boolean sections should have their contents rendered.'
			data: DataModel({
				'boolean': DataModel(false)
			})
			template: '"{{-boolean}}This should be rendered.{{/boolean}}"'
			expected: '"This should be rendered."'
		},
		TestCase{
			name: 'True Boolean Value'
			desc: 'True sections should have their contents omitted.'
			data: DataModel({
				'boolean': DataModel(true)
			})
			template: '"{{-boolean}}This should not be rendered.{{/boolean}}"'
			expected: '""'
		},
		TestCase{
			name: 'Doubled'
			desc: 'Multiple inverted sections per template should be permitted.'
			data: DataModel({
				'bool': DataModel(false)
				'two':  'second'
			})
			template: '
			{{-bool}}
			* first
			{{/bool}}
			* {{two}}
			{{-bool}}
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
			name: 'Nested (False)'
			desc: 'Nested false sections should have their contents rendered.'
			data: DataModel({
				'bool': DataModel(false)
			})
			template: '| A {{-bool}}B {{-bool}}C{{/bool}} D{{/bool}} E |'
			expected: '| A B C D E |'
		},
		TestCase{
			name: 'Nested (True)'
			desc: 'Nested true sections should be omitted.'
			data: DataModel({
				'bool': DataModel(true)
			})
			template: '| A {{-bool}}B {{-bool}}C{{/bool}} D{{/bool}} E |'
			expected: '| A  E |'
		},
		TestCase{
			name: 'Dotted Names - True'
			desc: 'Dotted names should be valid for Negative Section tags.'
			data: DataModel({
				'a': DataModel({
					'b': DataModel({
						'c': DataModel(true)
					})
				})
			})
			template: '"{{-a.b.c}}Not Here{{/a.b.c}}" == ""'
			expected: '"" == ""'
		},
		TestCase{
			name: 'Dotted Names - False'
			desc: 'Dotted names should be valid for Negative Section tags.'
			data: DataModel({
				'a': DataModel({
					'b': DataModel({
						'c': DataModel(false)
					})
				})
			})
			template: '"{{-a.b.c}}Not Here{{/a.b.c}}" == "Not Here"'
			expected: '"Not Here" == "Not Here"'
		},
		TestCase{
			name: 'Surrounding Whitespace'
			desc: 'Negative sections should not alter surrounding whitespace.'
			data: DataModel({
				'boolean': DataModel(false)
			})
			template: ' | {{-boolean}}\t|\t{{/boolean}} | \n'
			expected: ' | \t|\t | \n'
		},
		TestCase{
			name: 'Internal Whitespace'
			desc: 'Negative section should not alter internal whitespace.'
			data: DataModel({
				'boolean': DataModel(false)
			})
			template: ' | {{-boolean}} {{! Important Whitespace }}\n {{/boolean}} | \n'
			expected: ' |  \n  | \n'
		},
		TestCase{
			name: 'Indented Inline Sections'
			desc: 'Single-line sections should not alter surrounding whitespace.'
			data: DataModel({
				'boolean': DataModel(false)
			})
			template: ' {{-boolean}}NO{{/boolean}}\n {{-boolean}}WAY{{/boolean}}\n'
			expected: ' NO\n WAY\n'
		},
		TestCase{
			name: 'Standalone Lines'
			desc: 'Standalone lines should be removed from the template.'
			data: DataModel({
				'boolean': DataModel(false)
			})
			template: '
			| This Is
			{{-boolean}}
			|
			{{/boolean}}
			| A Line
			'
			expected: '
			| This Is
			|
			| A Line
			'
		},
		TestCase{
			name: 'Standalone Indented Lines'
			desc: 'Standalone indented lines should be removed from the template.'
			data: DataModel({
				'boolean': DataModel(false)
			})
			template: '
			| This Is
				{{-boolean}}
			|
				{{/boolean}}
			| A Line
			'
			expected: '
			| This Is
			|
			| A Line
			'
		},
		TestCase{
			name: 'Standalone Line Endings'
			desc: '"\r\n" should be considered a newline for standalone tags.'
			data: DataModel({
				'boolean': DataModel(false)
			})
			template: '|\r\n{{-boolean}}\r\n{{/boolean}}\r\n|'
			expected: '|\r\n|'
		},
		TestCase{
			name: 'Standalone Without Previous Line'
			desc: 'Standalone tags should not require a newline to precede them.'
			data: DataModel({
				'boolean': DataModel(false)
			})
			template: '  {{-boolean}}\n^{{/boolean}}\n/'
			expected: '^\n/'
		},
		TestCase{
			name: 'Standalone Without Newline'
			desc: 'Standalone tags should not require a newline to follow them.'
			data: DataModel({
				'boolean': DataModel(false)
			})
			template: '^{{-boolean}}\n/\n  {{/boolean}}'
			expected: '^\n/\n'
		},
		TestCase{
			name: 'Padding'
			desc: 'Superfluous in-tag whitespace should be ignored.'
			data: DataModel({
				'boolean': DataModel(false)
			})
			template: '|{{- boolean }}={{/ boolean }}|'
			expected: '|=|'
		},
	]
}
