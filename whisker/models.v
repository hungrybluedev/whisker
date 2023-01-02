module whisker

import strings
import datatypes

pub type DataModel = []DataModel | bool | map[string]DataModel | string

pub type ResultModel = bool | string

pub struct WhiskerTemplate {
	tokens []Token
}

pub fn new_template(input string) !WhiskerTemplate {
	input_lines := extract_lines(input)!

	input_lines.validate_line_lengths()!
	input_lines.validate_indentation()!

	mut tokenizer := Tokenizer{}
	tokenizer.tokenize(input_lines)!

	return WhiskerTemplate{
		tokens: tokenizer.tokens
	}
}

pub fn load_template(file string) !WhiskerTemplate {
	return error('Not implemented yet.')
}

pub fn (template WhiskerTemplate) run(context DataModel) !string {
	dump(template.tokens)
	mut index := 0
	mut output := strings.new_builder(256)

	mut data_stack := DataStack{}
	data_stack.push(context)

	mut section_stack := datatypes.Stack[Section]{}

	for index < template.tokens.len {
		token := template.tokens[index]

		match token.token_type {
			.normal, .indent, .newline {
				output.write_string(token.content)
				index++
			}
			.tag {
				result := data_stack.query(token.content)!
				if result is string {
					output.write_string(result)
				} else {
					return error('Expected string value for ${token.content}')
				}
				index++
			}
			.open_section_tag {
				section_name := token.content[1..]
				// Check the type of section requested from the first character
				match token.content[0] {
					`+` {
						// Boolean requested (positive)
						result := data_stack.query(section_name)!
						if result !is bool {
							return error('Expected a boolean value for ${section_name}')
						}
						// If result is false, skip to end of section
						if result as bool {
							section_stack.push(Section{
								name: section_name
								kind: .bool_section
							})
							index++
						} else {
							mut inner_index := index + 1
							for inner_index < template.tokens.len {
								if template.tokens[inner_index].token_type == .close_section_tag {
									if template.tokens[inner_index].content == section_name {
										index = inner_index + 1
										break
									} else {
										inner_index++
									}
								} else {
									inner_index++
								}
							}
						}
					}
					else {
						return error('Could not infer section type.')
					}
				}
				// index++
			}
			.close_section_tag {
				if !section_stack.is_empty() && section_stack.peek()!.name == token.content {
					section_stack.pop()!
				} else {
					return error('Unexpected closing tag at index: ${index}')
				}
				index++
			}
			else {
				return error('Token not supported yet: ${token.token_type}')
			}
		}
	}

	return output.str()
}
