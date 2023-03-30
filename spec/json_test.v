module main

import whisker { DataModel }

fn test_simple_json_api() {
	// Demonstrates the following:
	// 1. Delimiter swap to [ and ]
	// 2. Raw tag usage using & prefix
	// 3. If the data is a string, pass in the quotes too.
	input := '{{=[ ]=}}{
	"value": [&value]
}'
	test_data := [
		DataModel({
			'value': DataModel('42')
		}),
		DataModel({
			'value': DataModel('-147')
		}),
		DataModel({
			'value': DataModel('0')
		}),
		DataModel({
			'value': DataModel('"Valid string value"')
		}),
	]
	expected_values := [
		'{
	"value": 42
}',
		'{
	"value": -147
}',
		'{
	"value": 0
}',
		'{
	"value": "Valid string value"
}',
	]
	template := whisker.new_template(input: input)!
	for index, data in test_data {
		output := template.run(data)!
		assert output == expected_values[index]
	}
}

fn test_json_template_files() {
}

fn test_simple_html_header() {
}
