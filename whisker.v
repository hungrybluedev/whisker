module main

import spec
import whisker

fn main() {
	suite := spec.comment_tests

	for test in suite.tests {
		println(test.name)
		template := whisker.new_template(test.template)!
		output := template.run(test.data)!
		assert output.trim_space() == test.expected.trim_space(), 'Assertion failed for ${test.name}'
	}
}
