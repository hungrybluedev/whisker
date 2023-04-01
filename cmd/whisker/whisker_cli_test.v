module main

import os
import net.html

fn test_whisker_cli() {
	cases := os.ls('spec/template_files/html/cases')!
	for case in cases {
		os.mkdir('cmd/bin') or {}
		os.execute_or_panic('${os.quoted_path(@VEXE)} cmd/whisker -o cmd/bin/whisker')
		result := os.execute_or_panic('cmd/bin/whisker' +
			' --input spec/template_files/html/base.wskr.html' +
			' --data spec/template_files/html/cases/${case}/data.wskr.json' +
			' --partials head:spec/template_files/html/head.wskr.html,' +
			'header:spec/template_files/html/header.wskr.html,' +
			'main:spec/template_files/html/main.wskr.html,' +
			'footer:spec/template_files/html/footer.wskr.html')

		result_html := html.parse(result.output).get_root().str()
		expected_html := html.parse(os.read_file('spec/template_files/html/cases/${case}/expected.html')!).get_root().str()

		assert result_html == expected_html
	}
}
