module spec

import datamodel { DataModel }

pub const interpolation_test = TestList{
	name: 'Interpolation'
	overview: "Interpolation tags are used to integrate dynamic content into the template.

The tag's content MUST be a non-whitespace character sequence NOT containing
the current closing delimiter."
	tests: [
		TestCase{
			name: 'No Interpolation'
			desc: 'Mustache-free templates should render as-is.'
			template: '
Hello from {Mustache}!
'
			expected: '
Hello from {Mustache}!
'
		},
		TestCase{
			name: 'Basic Interpolation'
			desc: 'Unadorned tags should interpolate content into the template.'
			data: DataModel({
				'subject': DataModel('world')
			})
			template: '
Hello, {{subject}}!
'
			expected: '
Hello, world!
'
		},
		TestCase{
			name: 'HTML Escaping'
			desc: 'Basic interpolation should be HTML escaped.'
			data: {
				'forbidden': DataModel('& " < >')
			}
			template: '
These characters should be HTML escaped: {{forbidden}}
'
			expected: '
These characters should be HTML escaped: &amp; &quot; &lt; &gt;
'
		},
		TestCase{
			name: 'Triple Mustache'
			desc: 'Triple mustaches should interpolate without HTML escaping.'
			data: DataModel({
				'forbidden': DataModel('& " < >')
			})
			template: '
These characters should not be HTML escaped: {{{forbidden}}}
'
			expected: '
These characters should not be HTML escaped: & " < >
'
		},
		TestCase{
			name: 'Ampersand'
			desc: 'Ampersand should interpolate without HTML escaping.'
			data: DataModel({
				'forbidden': DataModel('& " < >')
			})
			template: '
These characters should not be HTML escaped: {{&forbidden}}
'
			expected: '
These characters should not be HTML escaped: & " < >
'
		},
		TestCase{
			name: 'Dotted Names - Basic Interpolation'
			desc: 'Dotted names should be considered a form of shorthand for sections.'
			data: DataModel({
				'person': DataModel({
					'name': DataModel('Joe')
				})
			})
			template: '"{{person.name}}" == "{{#person}}{{name}}{{/person}}"'
			expected: '"Joe" == "Joe"'
		},
		TestCase{
			name: 'Dotted Names - Triple Mustache Interpolation'
			desc: 'Dotted names should be considered a form of shorthand for sections.'
			data: DataModel({
				'person': DataModel({
					'name': DataModel('Joe')
				})
			})
			template: '"{{{person.name}}}" == "{{#person}}{{{name}}}{{/person}}"'
			expected: '"Joe" == "Joe"'
		},
		TestCase{
			name: 'Dotted Names - Ampersand Interpolation'
			desc: 'Dotted names should be considered a form of shorthand for sections.'
			data: DataModel({
				'person': DataModel({
					'name': DataModel('Joe')
				})
			})
			template: '"{{&person.name}}" == "{{#person}}{{&name}}{{/person}}"'
			expected: '"Joe" == "Joe"'
		},
		TestCase{
			name: 'Dotted Names - Arbitrary Depth'
			desc: 'Dotted names should be functional to any level of nesting.'
			data: DataModel({
				'a': DataModel({
					'b': DataModel({
						'c': DataModel({
							'd': DataModel({
								'e': DataModel({
									'name': DataModel('Phil')
								})
							})
						})
					})
				})
			})
			template: '"{{a.b.c.d.e.name}}" == "Phil"'
			expected: '"Phil" == "Phil"'
		},
		TestCase{
			name: 'Dotted Names - Initial Resolution'
			desc: 'The first part of a dotted name should resolve as any other name.'
			data: DataModel({
				'a': DataModel({
					'b': DataModel({
						'c': DataModel({
							'd': DataModel({
								'e': DataModel({
									'name': DataModel('Phil')
								})
							})
						})
					})
				})
				'b': DataModel({
					'c': DataModel({
						'd': DataModel({
							'e': DataModel({
								'name': DataModel('Wrong')
							})
						})
					})
				})
			})
			template: '"{{#a}}{{b.c.d.e.name}}{{/a}}" == "Phil"'
			expected: '"Phil" == "Phil"'
		},
		TestCase{
			name: 'Dotted Names - Context Precedence'
			desc: 'Dotted names should be resolved against former resolutions.'
			data: DataModel({
				'a': DataModel({
					'b': DataModel({
						'c': DataModel('YES')
					})
				})
				'b': DataModel({
					'c': DataModel('ERROR')
				})
			})
			template: '{{#a}}{{b.c}}{{/a}}'
			expected: 'YES'
		},
		TestCase{
			name: 'Implicit Iterators - Basic Interpolation'
			desc: 'Unadorned tags should interpolate content into the template.'
			data: DataModel('world')
			template: '
Hello, {{.}}!
'
			expected: '
Hello, world!
'
		},
		TestCase{
			name: 'Implicit Iterators - HTML Escaping'
			desc: ' Basic interpolation should be HTML escaped.'
			data: '& " < >'
			template: '
These characters should be HTML escaped: {{.}}
'
			expected: '
These characters should be HTML escaped: &amp; &quot; &lt; &gt;
'
		},
		TestCase{
			name: 'Implicit Iterators - Triple Mustache'
			desc: 'Triple mustaches should interpolate without HTML escaping.'
			data: '& " < >'
			template: '
These characters should not be HTML escaped: {{{.}}}
'
			expected: '
These characters should not be HTML escaped: & " < >
'
		},
		TestCase{
			name: 'Implicit Iterators - Ampersand'
			desc: 'Ampersand should interpolate without HTML escaping.'
			data: '& " < >'
			template: '
These characters should not be HTML escaped: {{&.}}
'
			expected: '
These characters should not be HTML escaped: & " < >
'
		},
		TestCase{
			name: 'Interpolation - Surrounding Whitespace'
			desc: 'Interpolation should not alter surrounding whitespace.'
			data: DataModel({
				'string': DataModel('---')
			})
			template: '| {{string}} |'
			expected: '| --- |'
		},
		TestCase{
			name: 'Triple Mustache - Surrounding Whitespace'
			desc: 'Interpolation should not alter surrounding whitespace.'
			data: DataModel({
				'string': DataModel('---')
			})
			template: '| {{{string}}} |'
			expected: '| --- |'
		},
		TestCase{
			name: 'Ampersand - Surrounding Whitespace'
			desc: 'Interpolation should not alter surrounding whitespace.'
			data: DataModel({
				'string': DataModel('---')
			})
			template: '| {{&string}} |'
			expected: '| --- |'
		},
		TestCase{
			name: 'Interpolation - Standalone'
			desc: 'Standalone interpolation should not alter surrounding whitespace.'
			data: DataModel({
				'string': DataModel('---')
			})
			template: '  {{string}}\n'
			expected: '  ---\n'
		},
		TestCase{
			name: 'Triple Mustache - Standalone'
			desc: 'Standalone interpolation should not alter surrounding whitespace.'
			data: DataModel({
				'string': DataModel('---')
			})
			template: '  {{{string}}}\n'
			expected: '  ---\n'
		},
		TestCase{
			name: 'Ampersand - Standalone'
			desc: 'Standalone interpolation should not alter surrounding whitespace.'
			data: DataModel({
				'string': DataModel('---')
			})
			template: '  {{&string}}\n'
			expected: '  ---\n'
		},
		TestCase{
			name: 'Interpolation With Padding'
			desc: 'Superfluous in-tag whitespace should be ignored.'
			data: DataModel({
				'string': DataModel('---')
			})
			template: '|{{ string }}|'
			expected: '|---|'
		},
		TestCase{
			name: 'Triple Mustache With Padding'
			desc: 'Superfluous in-tag whitespace should be ignored.'
			data: DataModel({
				'string': DataModel('---')
			})
			template: '|{{{ string }}}|'
			expected: '|---|'
		},
		TestCase{
			name: 'Ampersand With Padding'
			desc: 'Superfluous in-tag whitespace should be ignored.'
			data: DataModel({
				'string': DataModel('---')
			})
			template: '|{{& string }}|'
			expected: '|---|'
		},
		TestCase{
			name: 'Inner Brace Raw Tag With Delimiter Swap'
			desc: 'If the delimiter has been swapped, respect raw tag with curly braces.'
			data: DataModel('<OK>')
			template: '{{=[ ]=}}[.][{.}]'
			expected: '&lt;OK&gt;<OK>'
		},
		TestCase{
			name: 'Delimiter Swap With Ampersand'
			desc: 'Ampersand should still work after delimiter swap.'
			data: DataModel('<OK>')
			template: '{{=[ ]=}}[.][&.]'
			expected: '&lt;OK&gt;<OK>'
		},
	]
}
