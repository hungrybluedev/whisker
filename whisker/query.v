module whisker

struct DataStack {
mut:
	data []DataModel
}

// fn (stack DataStack) is_empty() bool {
// 	return stack.data.len == 0
// }

fn (mut stack DataStack) push(context DataModel) {
	stack.data << context
}

// fn (mut stack DataStack) pop() !DataModel {
// 	return if stack.data.len > 0 { stack.data.pop() } else { error('Empty stack') }
// }

// fn (mut stack DataStack) peep() !DataStack {
// 	return if stack.data.len > 0 { stack.data.last() } else { error('Empty stack') }
// }

fn (mut stack DataStack) list_query(key string) ![]DataModel {
	return error('Not implemented yet.')
}

fn (mut stack DataStack) map_query(key string) !map[string]DataModel {
	return error('Not implemented yet.')
}

fn (mut stack DataStack) simple_query(key string) !DataModel {
	for index := stack.data.len - 1; index >= 0; index-- {
		context := stack.data[index]
		match context {
			map[string]DataModel {
				return context[key] or { continue }
			}
			else {
				continue
			}
		}
	}
	return error('Could not find anything for "${key}".')
}

fn (mut stack DataStack) query(key string) !DataModel {
	// We can get away with a simple query
	if !key.contains_u8(`.`) {
		return stack.simple_query(key)
	}

	// We need to return the atomic value of the section
	if key == '.' {
		if stack.data.len == 0 {
			return error('Nothing on the context stack to retrieve from.')
		}
		top := stack.data.last()
		return match top {
			bool {
				top.str()
			}
			else {
				return error('Cannot retrieve value of non-boolean key.')
			}
		}
	}

	// We need to process dotted keys
	keys := key.split('.')
	mut data := (stack.simple_query(keys.first()) or {
		return error('Could not find anything for "${keys.first()}".')
	}) as map[string]DataModel
	for i := 1; i < keys.len - 1; i++ {
		next_data_map := data[keys[i]] or {
			return error('Could not find anything for sub-key "${keys[i]}".')
		}
		if next_data_map is map[string]DataModel {
			data = next_data_map.clone()
		} else {
			return error('Failed to query dotted key: ${key}.')
		}
	}
	return data[keys.last()] or { return error('Could not find anything for "${key}".') }
}
