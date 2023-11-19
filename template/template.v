module template

import os

// Template is a compiled template that can be rendered with an input data model (context).
pub struct Template {
pub:
	program          Program
	partials         []string
	partial_programs map[string]Program
}

// TemplateConfig is the configuration struct for a template.
@[params]
pub struct TemplateConfig {
	input    string            @[required]
	partials map[string]string = {}
}

// from_strings creates a template from a primary string input and a map of partial names to input strings.
pub fn from_strings(config TemplateConfig) !Template {
	if config.input.len == 0 {
		return Template{}
	}

	mut tokenized_partials := map[string][]Token{}

	for label, partial in config.partials {
		tokenized_partials[label] = tokenize(partial)!
	}

	main_tokens := tokenize(config.input)!
	main_program := build_node_tree(main_tokens)!
	mut partial_programs := map[string]Program{}

	for partial, tokens in tokenized_partials {
		partial_programs[partial] = build_node_tree(tokens)!
	}

	return Template{
		program: main_program
		partials: tokenized_partials.keys()
		partial_programs: partial_programs
	}
}

// load_file loads a template from a primary input file and a map of partial names to input files.
pub fn load_file(config TemplateConfig) !Template {
	input := os.read_file(config.input)!

	mut partial_contents := map[string]string{}
	for partial_name, path in config.partials {
		partial_contents[partial_name] = os.read_file(path)!
	}

	return from_strings(input: input, partials: partial_contents)
}
