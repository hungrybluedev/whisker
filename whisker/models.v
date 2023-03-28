module whisker

import strings
import encoding.html
import datatypes

pub type DataModel = []DataModel | bool | map[string]DataModel | string

pub struct WhiskerTemplate {
pub:
	tokens   []Token
	partials map[string][]Token
}

pub fn new_template(input string, partials map[string]string) !WhiskerTemplate {
	if input.len == 0 {
		return WhiskerTemplate{}
	}

	mut tokenized_partials := map[string][]Token{}

	for label, partial in partials {
		tokenized_partials[label] = tokenize(partial)!
	}

	return WhiskerTemplate{
		tokens: tokenize(input)!
		partials: tokenized_partials
	}
}

struct Section {
	name     string
	contexts []DataModel
}

pub fn load_template(file string) !WhiskerTemplate {
	return error('Not implemented yet.')
}

pub fn (template WhiskerTemplate) run(context DataModel) !string {
	mut main_program := build_node_tree(template.tokens)!

	if unsafe { main_program.head == nil } {
		return ''
	}

	mut partial_programs := map[string]Program{}

	for partial, tokens in template.partials {
		partial_programs[partial] = build_node_tree(tokens)!
	}

	mut data_stack := DataStack{}
	data_stack.push(context)

	mut output := strings.new_builder(256)
	mut sections := datatypes.Stack[Section]{}

	mut current := main_program.head
	for unsafe { current != nil } {
		match current.token.token_type {
			.normal {
				output.write_string(current.token.content)
				current = current.next
			}
			.comment {
				// Skip
				current = current.next
			}
			.tag {
				query_value := data_stack.query(current.token.content)!
				if query_value !is string {
					return error('Expected a string for "${current.token.content}')
				}
				value := query_value as string
				output.write_string(html.escape(value))
				current = current.next
			}
			.positive_section {
				query_value := data_stack.query(current.token.content)!
				if query_value !is bool {
					return error('Expected a bool for "${current.token.content}')
				}
				switch := query_value as bool
				if !switch {
					current = current.jump
				} else {
					sections.push(Section{
						name: current.token.content
					})
					data_stack.push(true)
					current = current.next
				}
			}
			.negative_section {
				query_value := data_stack.query(current.token.content)!
				if query_value !is bool {
					return error('Expected a bool for "${current.token.content}')
				}
				switch := query_value as bool
				if switch {
					current = current.jump
				} else {
					sections.push(Section{
						name: current.token.content
					})
					data_stack.push(false)
					current = current.next
				}
			}
			.expanded_list_section {
				sections.push(Section{
					name: current.token.content
				})
				parts := current.token.content.split('#')
				if parts.len != 2 {
					return error('Invalid expanded section name: ${current.token.content}')
				}

				list_name := parts[0]
				list_index := parts[1].int()

				query_value := data_stack.query(list_name)!
				if query_value !is []DataModel {
					return error('Expected a list for "${list_name}"')
				}
				work_list := query_value as []DataModel

				if list_index < 0 || list_index >= work_list.len {
					return error('Invalid list index ${list_index} for "${list_name}"')
				}

				data_stack.push(work_list[list_index])
				current = current.next
			}
			.map_section {
				query_value := data_stack.query(current.token.content)!
				if query_value !is map[string]DataModel {
					return error('Expected a map for "${current.token.content}"')
				}
				work_map := query_value as map[string]DataModel
				data_stack.push(work_map)
				sections.push(Section{
					name: current.token.content
				})
				current = current.next
			}
			.list_section {
				// Iterate over all list keys and replace with expanded map sections

				query_value := data_stack.query(current.token.content)!
				if query_value !is []DataModel {
					return error('Expected a list for "${current.token.content}"')
				}
				work_list := query_value as []DataModel

				if work_list.len == 0 {
					// Nothing to do, skip over
					current = current.jump
					continue
				}

				// Copy over the inner contents of the list
				mut inner_nodes := []&Node{}

				for n := current.next; n != current.jump; n = n.next {
					inner_nodes << n
				}
				// Last one is the list close section
				original_list_closer := inner_nodes.pop()

				// If the inner content of the list section is empty, we skip
				if inner_nodes.len == 0 {
					// Nothing to do, skip over
					current = current.jump
					continue
				}

				sections.push(Section{
					name: current.token.content
				})

				// Now we copy the inner-nodes and modify the program
				mut join_point := current
				for index, _ in work_list {
					// New context for expanded list
					section_name := '${current.token.content}#${index}'
					mut list_opener := &Node{
						token: Token{
							content: section_name
							token_type: .expanded_list_section
						}
					}
					mut list_closer := &Node{
						token: Token{
							content: section_name
							token_type: .close_section
						}
						jump: list_opener
					}
					join_point.next = list_opener
					join_point = list_opener
					for node in inner_nodes {
						copy := &Node{
							...node
						}
						join_point.next = copy
						join_point = copy
					}
					join_point.next = list_closer
					join_point = list_closer
				}

				join_point.next = original_list_closer

				current = current.next
			}
			.close_section {
				if sections.is_empty() {
					return error('Found a stray closing tag.')
				}
				last_section := sections.pop()!
				if last_section.name != current.token.content {
					return error('Expected to close ${last_section.name}, closed ${current.token.content} instead.')
				}
				original_section := current.jump
				if original_section.token.token_type in [.expanded_list_section, .negative_section,
					.positive_section, .map_section] {
					data_stack.pop()!
				}
				current = current.next
			}
			.partial_section {
				name := current.token.content.trim_space()
				if name !in partial_programs {
					return error('No partial found named "${name}"')
				}
				next := current.next

				mut replacement := partial_programs[name]
				replacement.tail.next = next

				current = replacement.head
			}
		}
	}

	return output.str()
}
