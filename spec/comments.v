module spec

import datamodel { DataModel }

pub const comment_tests = TestList{
	name: 'Comments'
	overview: "
Comment tags represent content that should never appear in the resulting output.

The tag's content may contain any sequence of characters (including
whitespace and newlines) except the active closing delimiter.

Comment tags can act as standalone tags (taking up a line, indented, etc).
"
	tests: [
		TestCase{
			name: 'Inline'
			desc: 'Comment blocks should be removed from the template.'
			template: '12345{{! Comment Block! }}67890'
			expected: '1234567890'
		},
		TestCase{
			name: 'Multiline'
			desc: 'Multiline comments should be permitted.'
			template: '12345{{!\n  This is a\n  multi-line comment...\n}}67890\n'
			expected: '1234567890\n'
		},
		TestCase{
			name: 'Standalone'
			desc: 'All standalone comment lines should be removed.'
			template: 'Begin.\n{{! Comment Block! }}\nEnd.\n'
			expected: 'Begin.\nEnd.\n'
		},
		TestCase{
			name: 'Indented Standalone'
			desc: 'All standalone comment lines should be removed.'
			template: 'Begin.\n  {{! Indented Comment Block! }}\nEnd.\n'
			expected: 'Begin.\nEnd.\n'
		},
		TestCase{
			name: 'Standalone Line Endings'
			desc: '"\\r\\n" should be considered a newline for standalone tags.'
			template: '|\r\n{{! Standalone Comment }}\r\n|'
			expected: '|\r\n|'
		},
		TestCase{
			name: 'Standalone Without Previous Line'
			desc: 'Standalone tags should not require a newline to precede them.'
			template: "  {{! I'm Still Standalone }}\n!"
			expected: '!'
		},
		TestCase{
			name: 'Standalone Without Newline'
			desc: 'Standalone tags should not require a newline to follow them.'
			template: "!\n  {{! I'm Still Standalone }}"
			expected: '!\n'
		},
		TestCase{
			name: 'Multiline Standalone'
			desc: 'All standalone comment lines should be removed.'
			template: "Begin.\n{{!\nSomething's going on here...\n}}\nEnd.\n"
			expected: 'Begin.\nEnd.\n'
		},
		TestCase{
			name: 'Indented Multiline Standalone'
			desc: 'All standalone comment lines should be removed.'
			template: "Begin.\n  {{!\n    Something's going on here...\n  }}\nEnd.\n"
			expected: 'Begin.\nEnd.\n'
		},
		TestCase{
			name: 'Indented Inline'
			desc: 'Inline comments should not strip whitespace.'
			template: '  12 {{! 34 }}\n'
			expected: '  12 \n'
		},
		TestCase{
			name: 'Surrounding Whitespace'
			desc: 'Comment removal should preserve surrounding whitespace.'
			template: '12345 {{! Comment Block! }} 67890'
			expected: '12345  67890'
		},
		TestCase{
			name: 'Variable Name Collision'
			desc: 'Comments must never render, even if variable with same name exists.'
			data: {
				'! comment':  DataModel('1')
				'! comment ': '2'
				'!comment':   '3'
				'comment':    '4'
			}
			template: 'comments never show: >{{! comment }}<'
			expected: 'comments never show: ><'
		},
	]
}
