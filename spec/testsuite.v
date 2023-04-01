module spec

import datamodel { DataModel }

pub struct TestCase {
pub:
	name     string
	desc     string
	data     DataModel = DataModel(false)
	template string
	expected string
	partials map[string]string = {}
}

pub struct TestList {
pub:
	name     string
	overview string
	tests    []TestCase
}
