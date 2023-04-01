module main

import flag
import os
import datamodel
import template

fn main() {
	mut fp := flag.new_flag_parser(os.args)

	fp.application(app_name)
	fp.version(version)
	fp.description('${description}\n${instructions}')
	fp.skip_executable()

	input := fp.string('input', `i`, '', 'input template file')
	partials := fp.string('partials', `p`, '', 'partial template files entered as "name1:path,name2:other path,..."')
	data := fp.string('data', `d`, '', 'JSON file containing data for the template')
	output := fp.string('output', `o`, '', 'file to store output in otherwise prints to console')

	additional_args := fp.finalize() or {
		eprintln(err)
		eprintln(fp.usage())
		exit(1)
	}

	if additional_args.len > 0 {
		eprintln('Unnecessary arguments: ${additional_args.join(', ')}')
		eprintln(fp.usage())
		exit(1)
	}

	validate_path('input', input)

	partial_map := extract_partials(partials)
	clean_data := datamodel.from_json(os.read_file(data) or { '{}' }) or {
		eprintln('Could not obtain the data for the template from ${data}')
		exit(1)
	}

	file_template := template.load_file(input: input, partials: partial_map) or {
		eprintln('Failed to load a template with the following error:')
		eprintln(err)
		exit(1)
	}
	result := file_template.run(clean_data) or {
		eprintln('Failed to generate output with the following error:')
		eprintln(err)
		exit(1)
	}
	output_path := output.trim_space()
	if output_path.len == 0 {
		println(result)
		return
	}
	if os.exists(output_path) {
		os.rm(output_path) or {
			eprintln('Failed to delete output file: ${output_path}')
			exit(1)
		}
	}
	os.write_file(output_path, result) or {
		eprintln('Failed to write resilt to output file: ${output_path}')
		exit(1)
	}
}

fn validate_path(name string, path string) {
	if path.len == 0 {
		eprintln('Please provide a valid path for ${name}.')
		exit(1)
	}
	if !os.exists(path) {
		eprint('Invalid path: ${path} does not exist.')
		exit(1)
	}
}

fn extract_partials(partial_input string) map[string]string {
	if partial_input.len == 0 {
		// No partials provided
		return map[string]string{}
	}
	mut partials := map[string]string{}
	for content in partial_input.split(',') {
		pair := content.split(':')
		if pair.len != 2 {
			eprintln('Invalid (name, path) pair: ${content}')
			exit(1)
		}
		name := pair[0]
		if name.len == 0 {
			eprintln('A non-empty name is needed.')
			exit(1)
		}
		path := pair[1]
		validate_path(name, path)
		partials[name] = path
	}
	return partials
}
