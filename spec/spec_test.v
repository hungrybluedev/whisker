module main

import spec
import os
import template
import datamodel

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
			spec_template := template.from_strings(input: test.template, partials: test.partials)!
			output := spec_template.run(test.data)!
			// dump(output)
			// dump(output.bytes())
			// dump(test.expected)
			// dump(test.expected.bytes())
			assert output.trim_space() == test.expected.trim_space(), 'Assertion failed for ${suite.name}: ${test.name}'
		}
	}
}

fn generate_json_files() ! {
	os.mkdir('spec/gen') or {}

	for suite in spec_test_suites {
		for test in suite.tests {
			json_string := test.data.str()

			os.mkdir('spec/gen/${suite.name}') or {}
			os.write_file('spec/gen/${suite.name}/${test.name}.wskr.json', json_string)!
		}
	}
}

fn test_exported_files() ! {
	os.rmdir('spec/gen') or {}
	generate_json_files()!

	for suite in spec_test_suites {
		for test in suite.tests {
			json_content := os.read_file('spec/gen/${suite.name}/${test.name}.wskr.json')!

			decoded_data := datamodel.from_json(json_content)!
			assert decoded_data == test.data
		}
	}
}
