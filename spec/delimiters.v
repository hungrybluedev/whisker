module spec

import datamodel { DataModel }

pub const delimiter_tests = TestList{
	name: 'Delimiters'
	overview: "
Delimiter swap tags are used to change the tag delimiters for all content
following the tag in the current compilation unit.

The tag's content must be any two non-whitespace sequences separated by
whitespace except am equals sign ('=') followed by the current closing
delimiter.

Delimiter swap tags can be standalone tags.
"
	tests: [
		TestCase{
			name: 'Pair Behaviour'
			desc: 'The equals sign (used on both sides) should permit delimiter changes.'
			data: {
				'text': DataModel('Hey!')
			}
			template: '{{=<% %>=}}(<%text%>)'
			expected: '(Hey!)'
		},
		TestCase{
			name: 'Special Characters'
			desc: 'Characters with special meaning regexen should be valid delimiters.'
			data: {
				'text': DataModel('It worked!')
			}
			template: '({{=[ ]=}}[text])'
			expected: '(It worked!)'
		},
		TestCase{
			name: 'Sections'
			desc: 'Delimiters set outside sections should persist.'
			data: {
				'section': DataModel(true)
				'data':    'I got interpolated.'
			}
			template: '
[
{{+section}}
	{{data}}
	|data|
{{/section}}
{{= | | =}}
|+section|
	{{data}}
	|data|
|/section|
]
'
			expected: '
[
	I got interpolated.
	|data|
	{{data}}
	I got interpolated.
]
'
		},
		TestCase{
			name: 'Inverted Sections'
			desc: 'Delimiters set outside inverted sections should persist.'
			data: {
				'section': DataModel(false)
				'data':    'I got interpolated.'
			}
			template: '
[
{{-section}}
	{{data}}
	|data|
{{/section}}
{{= | | =}}
|-section|
	{{data}}
	|data|
|/section|
]
'
			expected: '
[
	I got interpolated.
	|data|
	{{data}}
	I got interpolated.
]
'
		},
		TestCase{
			name: 'Partial Inheritance'
			desc: 'Delimiters set in a parent template should not affect a partial.'
			data: DataModel({
				'value': DataModel('yes')
			})
			partials: {
				'include': '.{{value}}.'
			}
			template: '
[ {{>include}} ]
{{= | | =}}
[ |>include| ]
'
			expected: '
[ .yes. ]
[ .yes. ]
'
		},
		TestCase{
			name: 'Post-Partial Behavior'
			desc: 'Delimiters set in a partial should not affect the parent template.'
			data: DataModel({
				'value': DataModel('yes')
			})
			partials: {
				'include': '.{{value}}. {{= | | =}} .|value|.'
			}
			template: '
[ {{>include}} ]
[ .{{value}}.  .|value|. ]
'
			expected: '
[ .yes.  .yes. ]
[ .yes.  .|value|. ]
'
		},
		TestCase{
			name: 'Surrounding Whitespace'
			desc: 'Surrounding whitespace should be left untouched.'
			template: '| {{=@ @=}} |'
			expected: '|  |'
		},
		TestCase{
			name: 'Outlying Whitespace (Inline)'
			desc: 'Whitespace should be left untouched.'
			template: ' | {{=@ @=}}\n'
			expected: ' | \n'
		},
		TestCase{
			name: 'Standalone Tag'
			desc: 'Standalone lines should be removed from the template.'
			template: '
Begin.
{{=@ @=}}
End.
'
			expected: '
Begin.
End.
'
		},
		TestCase{
			name: 'Indented Standalone Tag'
			desc: 'Indented standalone lines should be removed from the template.'
			template: '
Begin.
{{=@ @=}}
End.
'
			expected: '
Begin.
End.
'
		},
		TestCase{
			name: 'Standalone Line Endings'
			desc: '"\r\n" should be considered a newline for standalone tags.'
			template: '|\r\n{{= @ @ =}}\r\n|'
			expected: '|\r\n|'
		},
		TestCase{
			name: 'Standalone Without Previous Line'
			desc: 'Standalone tags should not require a newline to precede them.'
			template: '  {{=@ @=}}\n='
			expected: '='
		},
		TestCase{
			name: 'Standalone Without Newline'
			desc: ' Standalone tags should not require a newline to follow them.'
			template: '=\n  {{=@ @=}}'
			expected: '=\n'
		},
		TestCase{
			name: 'Pair with Padding'
			desc: ' Superfluous in-tag whitespace should be ignored.'
			template: '|{{= @   @ =}}|'
			expected: '||'
		},
	]
}
