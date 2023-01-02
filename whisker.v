module main

import spec
import whisker

fn main() {
	suites := [
		spec.comment_tests,
		// spec.delimiter_tests,
	]
	for suite in suites {
		for test in suite.tests {
			println(test.name)
			template := whisker.new_template(test.template)!
			output := template.run(test.data)!
			dump(output)
			dump(test.expected)
			assert output.trim_space() == test.expected.trim_space(), 'Assertion failed for ${suite.name}: ${test.name}'
		}
	}
}
