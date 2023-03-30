module whisker

import strings
import x.json2

const data_indent = '\t'

pub type DataModel = []DataModel | bool | map[string]DataModel | string

pub fn (data DataModel) clone() DataModel {
	return match data {
		bool {
			data
		}
		string {
			data
		}
		[]DataModel {
			data.clone()
		}
		map[string]DataModel {
			data.clone()
		}
	}
}

pub fn (data DataModel) str() string {
	result := data.internal_str(0)
	return if !result.contains_any('{}') {
		'{\n${whisker.data_indent}".": ${result}\n}'
	} else {
		result
	}
}

fn escape(content string) string {
	return content.replace_each([
		'"',
		'\\"',
	])
}

pub fn (data DataModel) json_str() string {
	return data.str()
}

fn (data DataModel) internal_str(depth int) string {
	padding := whisker.data_indent.repeat(depth)
	return match data {
		bool {
			json
		}
		string {
			escaped := escape(data)
			'"${escaped}"'
		}
		[]DataModel {
			mut output := strings.new_builder(data.len * 4 + 10)

			new_padding := padding + whisker.data_indent
			output.write_string('[\n')
			mut needs_newline := false

			for item in data {
				if needs_newline {
					output.write_string(',\n')
				} else {
					needs_newline = true
				}
				output.write_string(new_padding)
				output.write_string(item.internal_str(depth + 1))
			}
			output.write_string('\n')
			output.write_string(padding)
			output.write_string(']')
			output.str()
		}
		map[string]DataModel {
			mut output := strings.new_builder(data.len * 4 + 10)

			new_padding := padding + whisker.data_indent
			output.write_string('{\n')
			mut needs_newline := false

			for key, value in data {
				if needs_newline {
					output.write_string(',\n')
				} else {
					needs_newline = true
				}
				output.write_string(new_padding)
				output.write_string('"${escape(key)}"')
				output.write_string(': ')
				output.write_string(value.internal_str(depth + 1))
			}
			output.write_string('\n')
			output.write_string(padding)
			output.write_string('}')
			output.str()
		}
	}
}

pub fn from_json(input string) !DataModel {
	root := json2.raw_decode(input)!
	value := recursive_decode(root)!
	if value is map[string]DataModel {
		if value.len == 1 && '.' in value {
			return value['.'] or {
				return error('Could not extract data model from topmost context.')
			}
		}
	}
	return value
}

fn recursive_decode(node json2.Any) !DataModel {
	return match node {
		bool, string {
			DataModel(node)
		}
		[]json2.Any {
			mut items := []DataModel{cap: node.len}
			for json_item in node {
				items << recursive_decode(json_item)!
			}
			items
		}
		map[string]json2.Any {
			mut data_map := map[string]DataModel{}
			for key, json_item in node {
				data_map[key] = recursive_decode(json_item)!
			}
			data_map
		}
		else {
			return error('Unsupported type: ${typeof(node).name}')
		}
	}
}
