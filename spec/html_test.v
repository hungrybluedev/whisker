module main

import whisker
import os
import net.html

fn test_html_template_files() {
	partials := {
		'footer': 'spec/template_files/html/footer.wskr.html'
		'header': 'spec/template_files/html/header.wskr.html'
		'head':   'spec/template_files/html/head.wskr.html'
		'main':   'spec/template_files/html/main.wskr.html'
	}
	mut template := whisker.load_template(
		input: 'spec/template_files/html/base.wskr.html'
		partials: partials
	)!
	cases := os.ls('spec/template_files/html/cases')!

	for case in cases {
		data := whisker.from_json(os.read_file('spec/template_files/html/cases/${case}/data.wskr.json')!)!
		raw_result := template.run(data)!
		result_html := html.parse(raw_result)

		raw_expected := os.read_file('spec/template_files/html/cases/${case}/expected.html')!
		expected_html := html.parse(raw_expected)

		assert result_html.get_root().str() == expected_html.get_root().str(), 'Assertion failed for case ${case}'
	}
}
