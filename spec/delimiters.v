module spec

import whisker { DataModel }

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
	]
}
