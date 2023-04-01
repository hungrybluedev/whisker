module main

import template
import os
import net.html
import datamodel

fn test_html_template_files() {
	partials := {
		'footer': 'spec/template_files/html/footer.wskr.html'
		'header': 'spec/template_files/html/header.wskr.html'
		'head':   'spec/template_files/html/head.wskr.html'
		'main':   'spec/template_files/html/main.wskr.html'
	}
	mut html_template := template.load_file(
		input: 'spec/template_files/html/base.wskr.html'
		partials: partials
	)!
	cases := os.ls('spec/template_files/html/cases')!

	for case in cases {
		data := datamodel.from_json(os.read_file('spec/template_files/html/cases/${case}/data.wskr.json')!)!
		raw_result := html_template.run(data)!
		result_html := html.parse(raw_result)

		raw_expected := os.read_file('spec/template_files/html/cases/${case}/expected.html')!
		expected_html := html.parse(raw_expected)

		assert result_html.get_root().str() == expected_html.get_root().str(), 'Assertion failed for case ${case}'
	}
}
