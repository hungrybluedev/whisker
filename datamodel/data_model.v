module datamodel

import x.json2

const data_indent = '\t'

// DataModel describes the data types and structures that are supported
// by _whisker_.
pub type DataModel = []DataModel | bool | map[string]DataModel | string

// clone returns an independent, deep copy of the data model.
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

// str returns a string representation of the data model.
pub fn (data DataModel) str() string {
	result_node := data.to_json_node() or { json2.null }
	result := result_node.prettify_json_str()
	return if !result.contains_any('{}') {
		'{\n${datamodel.data_indent}".": ${result}\n}'
	} else {
		result
	}
}

// json_str returns a JSON string representation of the data model.
pub fn (data DataModel) json_str() string {
	return data.str()
}

// to_json_node returns a JSON node representation of the data model.
fn (data DataModel) to_json_node() !json2.Any {
	return match data {
		bool, string {
			json2.Any(data)
		}
		[]DataModel {
			mut any_list := []json2.Any{cap: data.len}
			for item in data {
				any_list << item.to_json_node()!
			}
			any_list
		}
		map[string]DataModel {
			mut any_map := map[string]json2.Any{}
			for key, item in data {
				any_map[key] = item.to_json_node()!
			}
			any_map
		}
	}
}

// from_json returns a DataModel from a valid JSON string.
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
