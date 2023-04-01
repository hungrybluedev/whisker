module main

import template
import datamodel

fn test_normal_text() {
	input := 'Sample text'

	simple_template := template.from_strings(
		input: input
	)!

	assert simple_template.run(false)! == 'Sample text'
}

fn test_first_example() {
	simple_template := template.from_strings(input: 'Hello, {{name}}!')!
	data := datamodel.from_json('{"name": "World"}')!

	assert simple_template.run(data)! == 'Hello, World!'
}

fn test_double_curly_braces_indicate_sections() {
	input := 'Hello, {{name}}!'

	simple_template := template.from_strings(
		input: input
	)!

	data := datamodel.from_json('{
		"name": "world"
	}')!

	assert simple_template.run(data)! == 'Hello, world!'
}

fn test_changing_delimiters() {
	input := "
	{{=[ ]=}}
	module main

	fn main() {
		println('[greeting]')
	}".trim_indent()

	data := datamodel.from_json('{
		"greeting": "Have a nice day!"
	}')!

	delimiter_template := template.from_strings(input: input)!
	assert delimiter_template.run(data)!.trim_space() == "
	module main

	fn main() {
		println('Have a nice day!')
	}".trim_indent()
}

fn test_boolean_positive_negative_sections() {
	input := '
	<nav>
	<ul>
	<li>Home</li>
	<li>About</li>
	{{-logged_in}}<li>Log In</li>{{/logged_in}}
	{{+logged_in}}<li>Account: {{user.name}}</li>{{/logged_in}}
	</ul>
	</nav>
	'.trim_indent()
	data_list := [
		datamodel.from_json('{
			"logged_in": false,
		}')!,
		datamodel.from_json('{
			"logged_in": true,
			"user": {
			  "name": "whisker"
			}
		}')!,
	]

	outputs := [
		'
		<nav>
		<ul>
		<li>Home</li>
		<li>About</li>
		<li>Log In</li>

		</ul>
		</nav>
		'.trim_indent(),
		'
		<nav>
		<ul>
		<li>Home</li>
		<li>About</li>

		<li>Account: whisker</li>
		</ul>
		</nav>
		'.trim_indent(),
	]

	section_template := template.from_strings(input: input)!

	for index, data in data_list {
		assert section_template.run(data)! == outputs[index]
	}
}

fn test_maps_lists_partials() {
	input := '
	<ol>
	{{*items}}
	{{>item}}
	{{/items}}
	</ol>'.trim_indent()
	partials := {
		'item': '<li>{{name}}: {{description}}</li>\n'
	}

	data := datamodel.from_json('{
		"items": [
			{
				"name": "Banana",
				"description": "Rich in potassium and naturally sweet."
			},
			{
				"name": "Orange",
				"description": "High in Vitamin C and very refreshing."
			}
	   ]
	}')!

	advanced_template := template.from_strings(input: input, partials: partials)!

	assert advanced_template.run(data)! == '
	<ol>
	<li>Banana: Rich in potassium and naturally sweet.</li>
	<li>Orange: High in Vitamin C and very refreshing.</li>
	</ol>
	'.trim_indent()
}
