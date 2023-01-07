module whisker

import strings
import encoding.html

pub type DataModel = []DataModel | bool | map[string]DataModel | string

pub struct WhiskerTemplate {
	tokens []Token
}

pub fn new_template(input string) !WhiskerTemplate {
	// input_lines := extract_lines(input)!
	//
	// input_lines.validate_line_lengths()!
	// input_lines.validate_indentation()!
	//
	// mut tokenizer := Tokenizer{}
	// tokenizer.tokenize(input_lines)!
	//
	// return WhiskerTemplate{
	// 	tokens: tokenizer.tokens
	// }
	return WhiskerTemplate{
		tokens: tokenize(input)!
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
				index++

				// TODO
			}
			.negative_section {
				index++

				// TODO
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
				index++

				// TODO
			}
		}
	}

	return output.str()
}
