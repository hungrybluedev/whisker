module main

import whisker

fn test_normal_text() {
	input := 'Sample text'

	mut template := whisker.new_template(
		input: input
	)!

	assert template.run(false)! == 'Sample text'
}

fn test_double_curly_braces_indicate_sections() {
	input := 'Hello, {{name}}!'

	mut template := whisker.new_template(
		input: input
	)!

	data := whisker.from_json('{
   	"name": "world"
}')!

	assert template.run(data)! == 'Hello, world!'
}

fn test_changing_delimiters() {
	input := "{{=[ ]=}}
module main

fn main() {
println('[greeting]')
}"

	data := whisker.from_json('{
"greeting": "Have a nice day!"
}')!

	mut template := whisker.new_template(input: input)!
	assert template.run(data)!.trim_space() == "
module main

fn main() {
println('Have a nice day!')
}".trim_space()
}

fn test_boolean_positive_negative_sections() {
	input := '
<nav>
<ul>
<li>Home</li>
<li>About</li>
{{-logged_in}}<li>Log In</li>{{/logged_in}}{{+logged_in}}<li>Account: {{user.name}}</li>{{/logged_in}}
</ul>
</nav>
'
	data_list := [
		whisker.from_json('{
			"logged_in": false,
		}')!,
		whisker.from_json('{
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
',
		'
<nav>
<ul>
<li>Home</li>
<li>About</li>
<li>Account: whisker</li>
</ul>
</nav>
',
	]

	mut template := whisker.new_template(input: input)!

	for index, data in data_list {
		assert template.run(data)! == outputs[index]
	}
}

fn test_maps_lists_partials() {
	input := '
<ol>
{{*items}}
{{>item}}
{{/items}}
</ol>
'
	partials := {
		'item': '<li>{{name}}: {{description}}</li>
'
	}

	data := whisker.from_json('{
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

	mut template := whisker.new_template(input: input, partials: partials)!

	assert template.run(data)! == '
<ol>
<li>Banana: Rich in potassium and naturally sweet.</li>
<li>Orange: High in Vitamin C and very refreshing.</li>
</ol>
'
}
