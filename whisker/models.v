module whisker

import strings
import encoding.html
import datatypes

pub type DataModel = []DataModel | bool | map[string]DataModel | string

pub type Partial = string
pub struct WhiskerTemplate {
	tokens []Token
}

pub fn new_template(input string, partials map[string]Partial) !WhiskerTemplate {
	return WhiskerTemplate{
		tokens: tokenize(input)!
	}
}

enum SectionType {
	boolean
	list
	map
}

struct Section {
	name         string
	section_type SectionType
}

pub fn load_template(file string) !WhiskerTemplate {
	return error('Not implemented yet.')
}

pub fn (template WhiskerTemplate) run(context DataModel) !string {
	mut index := 0
	mut output := strings.new_builder(256)

	mut data_stack := DataStack{}
	data_stack.push(context)

	mut sections := datatypes.Stack[Section]{}

	for index < template.tokens.len {
		token := template.tokens[index]
		match token.token_type {
			.normal {
				output.write_string(token.content)
				index++
			}
			.comment {
				// Skip
				index++
			}
			.tag {
				value := data_stack.query(token.content)!
				output.write_string(html.escape(value))
				index++
			}
			.positive_section {
				switch := data_stack.query_boolean_section(token.content)!
				if !switch {
					for template.tokens[index].token_type != .close_section
						&& template.tokens[index].content != token.content {
						index++

						if index >= template.tokens.len {
							return error('Could not find section closing tag for ${token.content}')
						}
					}
				} else {
					sections.push(Section{
						name: token.content
						section_type: .boolean
					})
					index++
				}
			}
			.negative_section {
				switch := data_stack.query_boolean_section(token.content)!
				if switch {
					for template.tokens[index].token_type != .close_section
					&& template.tokens[index].content != token.content {
						index++

						if index >= template.tokens.len {
							return error('Could not find section closing tag for ${token.content}')
						}
					}
				} else {
					sections.push(Section{
						name: token.content
						section_type: .boolean
					})
					index++
				}
			}
			.map_section {
				index++

				// TODO
			}
			.list_section {
				index++

				// TODO
			}
			.close_section {
				if sections.is_empty() {
					return error('Found a stray closing tag.')
				}
				last_section := sections.pop()!
				if last_section.name != token.content {
					return error('Expected to close ${last_section.name}, closed ${token.content} instead.')
				}
				index++
			}
		}
	}

	return output.str()
}
