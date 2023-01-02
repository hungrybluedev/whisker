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

fn (mut stack DataStack) pop() !DataModel {
	return if stack.data.len > 0 { stack.data.pop() } else { error('Empty stack') }
}

// fn (mut stack DataStack) peep() !DataStack {
// 	return if stack.data.len > 0 { stack.data.last() } else { error('Empty stack') }
// }

fn (mut stack DataStack) list_query(key string) ![]DataModel {
	return error('Not implemented yet.')
}

fn (mut stack DataStack) map_query(key string) !map[string]DataModel {
	return error('Not implemented yet.')
}

fn (mut stack DataStack) query(key string) !ResultModel {
	for index := stack.data.len - 1; index >= 0; index-- {
		context := stack.data[index]
		match context {
			map[string]DataModel {
				value := context[key] or { continue }
				match value {
					string {
						return value
					}
					bool {
						return value
					}
					else {
						continue
					}
				}
			}
			else {
				continue
			}
		}
	}
	dump(stack)
	return error('Could not find anything for "${key}".')
}

enum SectionType {
	bool_section
	list_section
	map_section
}

struct Section {
	name string
	kind SectionType
}
