module spec

import whisker

pub const partial_test = TestList{
	name: 'Partials'
	overview: '
Partials are external templates that can be plugged into the current template.
'
	tests: [
		TestCase{
			name: 'Basic Behaviour'
			desc: 'The greater-than operator should expand to the named partial.'
			template: '"{{>text}}"'
			expected: '"from partial"'
			partials: {
				'text': 'from partial'
			}
		},
		TestCase{
			name: 'Context'
			desc: 'The greater-than operator should operate within the current context.'
			data: {
				'text': whisker.DataModel('content')
			}
			template: '"{{>partial}}"'
			partials: {
				'partial': '*{{text}}*'
			}
			expected: '"*content*"'
		},
		// TestCase{
		// 	name: 'Recursion'
		// 	desc: 'The greater-than operator should properly recurse.'
		// 	data: whisker.DataModel({
		// 		'content': whisker.DataModel('X')
		// 		'nodes':   whisker.DataModel([
		// 			whisker.DataModel({
		// 				'content': whisker.DataModel('Y')
		// 				'nodes':   []whisker.DataModel{}
		// 			}),
		// 		])
		// 	})
		// 	template: '{{>node}}'
		// 	partials: {
		// 		'node': '{{content}}<{{#nodes}}{{>node}}{{/nodes}}>'
		// 	}
		// 	expected: 'X<Y<>>'
		// },
		TestCase{
			name: 'Surrounding Whitespace'
			desc: 'The greater-than operator should not alter surrounding whitespace.'
			template: '| {{>partial}} |'
			partials: {
				'partial': '\t|\t'
			}
			expected: '| \t|\t |'
		},
		TestCase{
			name: 'Inline Indentation'
			desc: 'Whitespace should be left untouched.'
			data: whisker.DataModel({
				'data': whisker.DataModel('|')
			})
			partials: {
				'partial': '>\n>'
			}
			template: '  {{data}}  {{> partial}}\n'
			expected: '  |  >\n>\n'
		},
		TestCase{
			name: 'Standalone Line Endings'
			desc: '"\r\n" should be considered a newline for standalone tags.'
			template: '|\r\n{{>partial}}\r\n|'
			expected: '|\r\n>|'
			partials: {
				'partial': '>'
			}
		},
		// I don't like supporting significant whitespace.
		TestCase{
			name: 'Standalone Without Newline'
			desc: 'Standalone tags should not require a newline to follow them.'
			template: '>\n  {{>partial}}'
			expected: '>\n>\n>'
			partials: {
				'partial': '>\n>'
			}
		},
		TestCase{
			name: 'Padding Whitespace'
			desc: 'Superfluous in-tag whitespace should be ignored.'
			template: '|{{> partial }}|'
			partials: {
				'partial': '[]'
			}
			expected: '|[]|'
		},
	]
}
