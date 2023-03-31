module main

import whisker
import spec
import os
import x.json2

const spec_test_suites = [
	spec.comment_tests,
	spec.delimiter_tests,
	spec.partial_test,
	spec.section_test,
	spec.inverted_test,
	spec.interpolation_test,
]

fn test_full_spec() {
	for suite in spec_test_suites {
		for test in suite.tests {
			println('${suite.name}: ${test.name}')
			template := whisker.new_template(input: test.template, partials: test.partials)!
			output := template.run(test.data)!
			// dump(output)
			// dump(output.bytes())
			// dump(test.expected)
			// dump(test.expected.bytes())
			assert output.trim_space() == test.expected.trim_space(), 'Assertion failed for ${suite.name}: ${test.name}'
		}
	}
}

fn generate_json_files() ! {
	os.mkdir('src/spec/gen') or {}

	for suite in spec_test_suites {
		for test in suite.tests {
			json_string := json2.encode_pretty(test.data)

			os.mkdir('src/spec/gen/${suite.name}') or {}
			os.write_file('src/spec/gen/${suite.name}/${test.name}.wskr.json', json_string)!
		}
	}
}

fn test_exported_files() ! {
	if !os.exists('src/spec/gen') {
		generate_json_files()!
	}
	for suite in spec_test_suites {
		for test in suite.tests {
			json_content := os.read_file('src/spec/gen/${suite.name}/${test.name}.wskr.json')!

			decoded_data := whisker.from_json(json_content)!
			assert decoded_data == test.data
		}
	}
}
