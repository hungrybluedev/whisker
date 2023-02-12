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
				value := data_stack.query(current.token.content)! as string
				output.write_string(html.escape(value))
				current = current.next
			}
			.positive_section {
				switch := data_stack.query(current.token.content)! as bool
				if !switch {
					current = current.jump
				} else {
					sections.push(Section{
						name: current.token.content
					})
					current = current.next
				}
			}
			.negative_section {
				switch := data_stack.query(current.token.content)! as bool
				if switch {
					current = current.jump
				} else {
					sections.push(Section{
						name: current.token.content
					})
					current = current.next
				}
			}
			.map_section {
				// TODO
				current = current.next
			}
			.list_section {
				// TODO
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
				current = current.next
			}
			.partial_section {
				name := current.token.content
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

	// mut index := 0
	// mut output := strings.new_builder(256)
	//
	// mut data_stack := DataStack{}
	// data_stack.push(context)
	//
	// mut sections := datatypes.Stack[Section]{}
	//
	// for index < template.tokens.len {
	// 	token := template.tokens[index]
	// 	match token.token_type {
	// 		.normal {
	// 			output.write_string(token.content)
	// 			index++
	// 		}
	// 		.comment {
	// 			// Skip
	// 			index++
	// 		}
	// 		.tag {
	// 			value := data_stack.query(token.content)!
	// 			output.write_string(html.escape(value))
	// 			index++
	// 		}
	// 		.positive_section {
	// 			switch := data_stack.query_boolean_section(token.content)!
	// 			if !switch {
	// 				for template.tokens[index].token_type != .close_section
	// 					&& template.tokens[index].content != token.content {
	// 					index++
	//
	// 					if index >= template.tokens.len {
	// 						return error('Could not find section closing tag for ${token.content}')
	// 					}
	// 				}
	// 			} else {
	// 				sections.push(Section{
	// 					name: token.content
	// 					section_type: .boolean
	// 				})
	// 				index++
	// 			}
	// 		}
	// 		.negative_section {
	// 			switch := data_stack.query_boolean_section(token.content)!
	// 			if switch {
	// 				for template.tokens[index].token_type != .close_section
	// 					&& template.tokens[index].content != token.content {
	// 					index++
	//
	// 					if index >= template.tokens.len {
	// 						return error('Could not find section closing tag for ${token.content}')
	// 					}
	// 				}
	// 			} else {
	// 				sections.push(Section{
	// 					name: token.content
	// 					section_type: .boolean
	// 				})
	// 				index++
	// 			}
	// 		}
	// 		.map_section {
	// 			index++
	//
	// 			// TODO
	// 		}
	// 		.list_section {
	// 			index++
	//
	// 			// TODO
	// 		}
	// 		.close_section {
	// 			if sections.is_empty() {
	// 				return error('Found a stray closing tag.')
	// 			}
	// 			last_section := sections.pop()!
	// 			if last_section.name != token.content {
	// 				return error('Expected to close ${last_section.name}, closed ${token.content} instead.')
	// 			}
	// 			index++
	// 		}
	// 		.partial_section {
	// 			return error('All partials should have been replaced at the beginning.')
	// 		}
	// 	}
	// }
	//
	// return output.str()
}
