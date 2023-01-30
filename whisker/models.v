module whisker

import strings
import encoding.html
import datatypes

pub type DataModel = []DataModel | bool | map[string]DataModel | string

pub struct WhiskerTemplate {
	tokens []Token
}

pub fn new_template(input string, partials map[string]string) !WhiskerTemplate {
	mut tokenized_partials := map[string][]Token{}

	for label, partial in partials {
		tokenized_partials[label] = tokenize(partial)!
	}

	return WhiskerTemplate{
		tokens: replace_partials(tokenize(input)!, tokenized_partials)!
	}
}

fn replace_partials(original []Token, partials map[string][]Token) ![]Token {
	mut partial_found := false
	for token in original {
		if token.token_type == .partial {
			partial_found = true
			break
		}
	}
	if !partial_found {
		return original
	}
	mut new_tokens := []Token{cap: original.len}
	for token in original {
		match token.token_type {
			.partial {
				new_tokens << partials[token.content] or {
					return error('Could not find partial named: ${token.content}')
				}
			}
			else {
				new_tokens << token
			}
		}
	}
	return replace_partials(new_tokens, partials)
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
			.partial {
				return error('All partials should have been replaced at the beginning.')
			}
		}
	}

	return output.str()
}
