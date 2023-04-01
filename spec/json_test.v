module main

import datamodel { DataModel }
import template
import os
import x.json2

fn test_simple_json_api() {
	// Demonstrates the following:
	// 1. Delimiter swap to [ and ]
	// 2. Raw tag usage using & prefix
	// 3. If the data is a string, pass in the quotes too.
	input := '
	{{=[ ]=}}
	{
		"value": [&value]
	}'.trim_indent()
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
		'
		{
			"value": 42
		}'.trim_indent(),
		'
		{
			"value": -147
		}'.trim_indent(),
		'
		{
			"value": 0
		}'.trim_indent(),
		'
		{
			"value": "Valid string value"
		}'.trim_indent(),
	]
	json_template := template.from_strings(input: input)!
	for index, data in test_data {
		output := json_template.run(data)!
		assert output == expected_values[index]
	}
}

fn test_json_template_files() {
	partials := {
		'article': 'spec/template_files/json/Article.partial.wskr.json'
		'author':  'spec/template_files/json/Author.partial.wskr.json'
	}
	input := 'spec/template_files/json/List of Articles.wskr.json'
	json_template := template.load_file(input: input, partials: partials)!

	data := datamodel.from_json(os.read_file('spec/template_files/json/Articles.data.wskr.json')!)!
	raw_output_string := json_template.run(data)!
	pretty_output_string := json2.raw_decode(raw_output_string)!.prettify_json_str()

	raw_expected_string := os.read_file('spec/template_files/json/List of Articles.json')!
	pretty_expected_string := json2.raw_decode(raw_expected_string)!.prettify_json_str()

	// dump(pretty_output_string)
	assert pretty_output_string == pretty_expected_string
}
