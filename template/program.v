module template

import strings
import encoding.html
import datatypes
import datamodel { DataModel }

[heap]
struct Node {
	token Token
mut:
	// For traversal
	next &Node = unsafe { nil }
	jump &Node = unsafe { nil }
}

pub fn (node Node) str() string {
	next := if isnil(node.next) { '' } else { node.next.str() }
	skip := if isnil(node.jump) { '' } else { node.jump.str() }
	return '{${node.token}}\n${next}\n${skip}'.trim_space()
}

[heap]
struct Program {
	len int
mut:
	head &Node = unsafe { nil }
	tail &Node = unsafe { nil }
}

pub fn build_node_tree(fragment []Token) !Program {
	if fragment.len == 0 {
		return Program{}
	}
	mut head := &Node{
		token: fragment.first()
	}
	mut current := head
	mut count := 1

	// Link all nodes together
	for token in fragment[1..] {
		next := &Node{
			token: token
		}
		current.next = next
		current = next
		count++
	}

	add_jumps(head)!

	return Program{
		head: head
		tail: current
		len: count
	}
}

fn add_jumps(head &Node) ! {
	mut current := unsafe { head }
	for !isnil(current) {
		match current.token.token_type {
			.positive_section, .negative_section, .map_section, .list_section {
				// Found the beginning of a skippable section
				// We save the name of the section and look for the closing section
				name := current.token.content

				mut depth := 0

				mut section := current.next
				for !isnil(section) && !(depth == 0 && section.token.token_type == .close_section
					&& section.token.content == name) {
					// Check for nested sections
					if section.token.content == name {
						match section.token.token_type {
							// Found a duplicate nested section, keep track
							current.token.token_type {
								depth++
							}
							// Found a closer for the nested section, leave it alone.
							.close_section {
								depth--
							}
							else {}
						}
					}
					section = section.next
				}

				if isnil(section) {
					return error('Missing a closing section for: ${name}')
				}

				// We now have the corresponding closing section
				current.jump = section
				section.jump = current
			}
			else {}
		}
		current = current.next
	}
}

fn (program Program) clone() Program {
	return clone_linked_list(program.head, program.tail.next)
}

fn clone_linked_list(head &Node, sentinel &Node) Program {
	mut original_nodes := []&Node{}

	// Store the original nodes in an indexable array
	if isnil(sentinel) {
		// Go until the end of the list
		for current := unsafe { head }; !isnil(current); current = current.next {
			original_nodes << current
		}
	} else {
		// Go until the sentinel
		for current := unsafe { head }; current != sentinel; current = current.next {
			original_nodes << current
		}
	}
	mut jump_points := []int{}
	mut copied_nodes := []&Node{}
	// Find the jump points and create copies
	for original in original_nodes {
		copy := &Node{
			...original
		}
		copied_nodes << copy
		if isnil(original.jump) {
			jump_points << -1
		} else {
			// Find the node that is being linked to
			for jump_index, current in original_nodes {
				if !isnil(original.jump) && current == original.jump {
					jump_points << jump_index
					break
				}
			}
		}
	}
	// Connect the copied nodes together
	for i := 1; i < copied_nodes.len; i++ {
		copied_nodes[i - 1].next = copied_nodes[i]
	}
	for i, jump_point in jump_points {
		if jump_point >= 0 {
			copied_nodes[i].jump = copied_nodes[jump_point]
		}
	}

	return Program{
		len: copied_nodes.len
		head: copied_nodes.first()
		tail: copied_nodes.last()
	}
}

pub fn (template Template) run(context DataModel) !string {
	mut main_program := build_node_tree(template.tokens)!

	if isnil(main_program.head) {
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
	for !isnil(current) {
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
					return error('Expected a string for "${current.token.content}"')
				}
				value := query_value as string
				output.write_string(html.escape(value))
				current = current.next
			}
			.raw_tag {
				query_value := data_stack.query(current.token.content)!
				if query_value !is string {
					return error('Expected a string for "${current.token.content}"')
				}
				value := query_value as string
				output.write_string(value)
				current = current.next
			}
			.positive_section {
				query_value := data_stack.query(current.token.content)!
				if query_value !is bool {
					return error('Expected a bool for "${current.token.content}"')
				}
				switch := query_value as bool
				if !switch {
					current = current.jump.next
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
					return error('Expected a bool for "${current.token.content}"')
				}
				switch := query_value as bool
				if switch {
					current = current.jump.next
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

				list_name := current.token.content
				list_index := current.token.index

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
					current = current.jump.next
					continue
				}

				inner_program := clone_linked_list(current.next, current.jump)
				if inner_program.len == 0 {
					// Nothing to do, skip over
					current = current.jump.next
					continue
				}

				mut join_point := current
				for index, _ in work_list {
					// New context for expanded list
					section_name := current.token.content
					mut list_opener := &Node{
						token: Token{
							content: section_name
							token_type: .expanded_list_section
							index: index
						}
					}
					mut list_closer := &Node{
						token: Token{
							content: section_name
							token_type: .close_section
						}
					}
					mut current_program := inner_program.clone()

					// Attach this new expanded section to the joining point
					join_point.next = list_opener

					// Attach the inner copy to the expanded section
					list_opener.next = current_program.head
					current_program.tail.next = list_closer

					// Connect the list and closer sections by jump points
					list_closer.jump = list_opener
					list_opener.jump = list_closer

					// Now attach the remaining after the new closer
					join_point = list_closer
				}

				join_point.next = current.jump

				sections.push(Section{
					name: current.token.content
				})
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

				mut replacement := partial_programs[name].clone()
				replacement.tail.next = next

				current = replacement.head
			}
		}
	}

	return output.str()
}
