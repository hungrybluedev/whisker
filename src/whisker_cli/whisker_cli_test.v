module main

import os
import net.html

fn test_whisker_cli() {
	cases := os.ls('./src/spec/template_files/html/cases')!
	for case in cases {
		result := os.execute_or_panic('${os.quoted_path(@VEXE)} run .' +
			' --input ./src/spec/template_files/html/base.wskr.html' +
			' --data ./src/spec/template_files/html/cases/${case}/data.wskr.json' +
			' --partials head:./src/spec/template_files/html/head.wskr.html,' +
			'header:./src/spec/template_files/html/header.wskr.html,' +
			'main:./src/spec/template_files/html/main.wskr.html,' +
			'footer:./src/spec/template_files/html/footer.wskr.html')

		result_html := html.parse(result.output).get_root().str()
		expected_html := html.parse(os.read_file('./src/spec/template_files/html/cases/${case}/expected.html')!).get_root().str()

		assert result_html == expected_html
	}
}
