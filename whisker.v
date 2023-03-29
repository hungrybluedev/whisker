module main

// import spec
import whisker
import spec

fn main() {
	suites := [
		spec.comment_tests,
		spec.delimiter_tests,
		spec.partial_test,
		spec.section_test,
		spec.inverted_test,
		spec.interpolation_test,
	]
	for suite in suites {
		for test in suite.tests {
			println('${suite.name}: ${test.name}')
			template := whisker.new_template(test.template, test.partials)!
			output := template.run(test.data)!
			// dump(output)
			// dump(output.bytes())
			// dump(test.expected)
			// dump(test.expected.bytes())
			assert output.trim_space() == test.expected.trim_space(), 'Assertion failed for ${suite.name}: ${test.name}'
		}
	}
}
