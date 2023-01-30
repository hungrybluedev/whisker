module spec

import whisker

pub struct TestCase {
pub:
	name     string
	desc     string
	data     whisker.DataModel = whisker.DataModel(false)
	template string
	expected string
	partials map[string]whisker.Partial
}

pub struct TestList {
pub:
	name     string
	overview string
	tests    []TestCase
}
