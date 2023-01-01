module whisker

import strings

pub type DataModel = []DataModel | bool | map[string]DataModel | string

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

pub fn (template WhiskerTemplate) run(data DataModel) !string {
	mut index := 0
	mut output := strings.new_builder(256)

	for index < template.tokens.len {
		token := template.tokens[index]

		match token.token_type {
			.normal, .indent, .newline {
				output.write_string(token.content)
				index++
			}
			else {
				return error('Token not supported yet: ${token.token_type}')
			}
		}
	}

	return output.str()
}
