module whisker

import strings
import math { abs }

const (
	default_start_delimiter = '{{'
	default_end_delimiter   = '}}'

	default_content_size    = 16
)

enum TokenType {
	// Normal tokens appear verbatim in the final result
	normal
	// Comment tokens are absent in the output
	comment
	// Tags are used for simple interpolation queries
	tag
	// The different types of sections:
	// Positive section is activated if the key is true
	positive_section
	// Negative section is activated if the key is false
	negative_section
	// Map section is activated for every key value pair
	map_section
	// List section is activated for every index item pair
	list_section
	// Close section marks the end of a section
	close_section
	// Partials are plugged into the current template
	partial_section
}

struct Token {
	content    string
	token_type TokenType
}

fn (token Token) str() string {
	return '${token.token_type}: "${token.content}"'
}

fn tokenize(input string) ![]Token {
	// Validate the line endings in the template
	line_ending := extract_line_ending(input)!
	// Validate the use of indentation in the template
	validate_indentation(input.split(line_ending))!

	// Extract tokens ignoring line endings and indentation information
	raw_tokens := extract_tokens(input)!

	// Further refine in lines of tokens
	token_lines := split_into_lines(raw_tokens, line_ending)

	// Flatten lines of tokens into a regular sequence of tokens
	clean_tokens := flatten_lines(token_lines, line_ending)

	// Return tokens after one final simplification pass
	return simplify_tokens(clean_tokens)
}

fn extract_tokens(input string) ![]Token {
	mut tokens := []Token{}
	mut buffer := strings.new_builder(whisker.default_content_size)

	mut start_delim := whisker.default_start_delimiter
	mut end_delim := whisker.default_end_delimiter

	mut index := 0
	for index < input.len {
		// Skip to the beginning of a tag
		mut continue_scanning := true
		for input[index] != start_delim[0] {
			buffer.write_u8(input[index])
			index++

			if index == input.len {
				// We've reached the end
				if buffer.len > 0 {
					tokens << Token{
						token_type: .normal
						content: buffer.str()
					}
				}
				continue_scanning = false
				break
			}
		}
		if !continue_scanning {
			break
		}
		// The first character matches:
		// Check to see if the full delimiter matches
		mut delim_index := index
		mut start_delim_found := true
		for ch in start_delim {
			if delim_index >= input.len {
				return error('Reached an unexpected end of input while trying to scan opening delimiter.')
			}
			if input[delim_index] == ch {
				delim_index++
			} else {
				// False alarm
				start_delim_found = false
				break
			}
		}
		if !start_delim_found {
			// False alarm, add all that we've matched so far to the buffer.
			for _ in index .. delim_index {
				buffer.write_u8(input[index])
				index++
			}
			continue
		}
		// First, we save the buffer contents to the array
		if buffer.len > 0 {
			tokens << Token{
				content: buffer.str()
				token_type: .normal
			}
		}

		// Next, we move the index to the start of the tag
		index += start_delim.len

		if index >= input.len {
			return error('Reached an unexpected end of input when trying to scan tag content.')
		}

		// Do we need to swap?
		if input[index] == `=` {
			index++

			mut new_start := strings.new_builder(whisker.default_content_size)
			mut new_end := strings.new_builder(whisker.default_content_size)

			if index >= input.len {
				return error('Reached an unexpected end of input while trying to swap delimiters.')
			}

			// Skip whitespace
			for input[index] in [` `, `\t`] {
				index++

				if index >= input.len {
					return error('Reached an unexpected end of input when trying to scan tag content.')
				}
			}

			for input[index] !in [` `, `\t`] {
				new_start.write_u8(input[index])
				index++

				if index >= input.len {
					return error('Reached an unexpected end of input while trying to scan new opening delimiter.')
				}
			}

			// Skip whitespace
			for input[index] in [` `, `\t`] {
				index++

				if index >= input.len {
					return error('Reached an unexpected end of input while trying to find new closing delimiter.')
				}
			}

			for input[index] !in [` `, `\t`, `=`] {
				new_end.write_u8(input[index])
				index++

				if index >= input.len {
					return error('Reached an unexpected end of input while trying to scan new closing delimiter.')
				}
			}

			// Skip whitespace until `=`
			for input[index] in [` `, `\t`] {
				index++

				if index >= input.len {
					return error('Reached an unexpected end of input while trying to find new closing delimiter.')
				}
			}
			if input[index] != `=` {
				return error('Expected "=" for finishing delimiter swap.')
			}
			index++

			// Make sure the delimiter closes
			for ch in end_delim {
				if input[index] != ch {
					return error('Closing delimiter not found for delimiter swap.')
				}
				index++

				if index >= input.len {
					return error('Reached an unexpected end of input while trying to end swap delimiter section.')
				}
			}

			// We've extracted the new start and end delimiters so apply them
			start_delim = new_start.str()
			end_delim = new_end.str()

			// Add a dummy comment tag so that it can be removed if it standalone
			tokens << Token{
				content: ''
				token_type: .comment
			}

			// Ready to normal character parsing
			continue
		}

		// We don't need to swap so read the tag contents
		mut found_closing := false
		for !found_closing {
			for input[index] != end_delim[0] {
				buffer.write_u8(input[index])
				index++

				if index >= input.len {
					return error('Reached an unexpected end of input while trying to scan tag contents.')
				}
			}
			// Check if we have found the closing delimiter
			found_closing = true
			delim_index = index
			for ch in end_delim {
				if input[delim_index] == ch {
					delim_index++
				} else {
					found_closing = false
					break
				}
			}
			if !found_closing {
				// Add the content to the buffer
				for _ in index .. delim_index {
					buffer.write_u8(input[index])
					index++
				}
			}
		}
		// We've got the closing tag
		index += end_delim.len
		tag_content := buffer.str().trim_space()
		if tag_content.len < 2 {
			return error('Invalid tag content: "${tag_content}"')
		}

		tokens << match tag_content[0] {
			`!` {
				Token{
					token_type: .comment
					content: ''
				}
			}
			`+` {
				Token{
					token_type: .positive_section
					content: tag_content[1..]
				}
			}
			`-` {
				Token{
					token_type: .negative_section
					content: tag_content[1..]
				}
			}
			`#` {
				Token{
					token_type: .map_section
					content: tag_content[1..]
				}
			}
			`$` {
				Token{
					token_type: .list_section
					content: tag_content[1..]
				}
			}
			`/` {
				Token{
					token_type: .close_section
					content: tag_content[1..]
				}
			}
			`>` {
				Token{
					token_type: .partial_section
					content: tag_content[1..]
				}
			}
			else {
				Token{
					token_type: .tag
					content: tag_content
				}
			}
		}
	}
	return tokens
}

struct TokenLine {
	tokens []Token
}

fn (line TokenLine) str() string {
	mut buffer := strings.new_builder(whisker.default_content_size)
	buffer.write_string('\n((')
	for index, token in line.tokens {
		if index != 0 {
			buffer.write_string(', ')
		}
		buffer.write_string(token.str())
	}
	buffer.write_string('))\n')
	return buffer.str()
}

fn split_into_lines(tokens []Token, line_ending string) []TokenLine {
	mut lines := []TokenLine{}
	mut current_line := []Token{cap: tokens.len}

	for token in tokens {
		match token.token_type {
			.normal {
				mut local_lines := token.content.split(line_ending)
				if local_lines.len == 0 {
					continue
				}
				current_line << Token{
					token_type: .normal
					content: local_lines.first()
				}
				if local_lines.len == 1 {
					continue
				}
				lines << TokenLine{
					tokens: current_line.clone()
				}
				current_line.clear()

				for index in 1 .. local_lines.len - 1 {
					lines << TokenLine{
						tokens: [
							Token{
								token_type: .normal
								content: local_lines[index]
							},
						]
					}
				}

				current_line << Token{
					token_type: .normal
					content: local_lines.last()
				}
			}
			else {
				current_line << token
			}
		}
	}

	if current_line.len > 0 {
		lines << TokenLine{
			tokens: current_line
		}
	}

	return lines
}

fn simplify_tokens(tokens []Token) ![]Token {
	mut simplified_tokens := []Token{cap: tokens.len}
	mut buffer := strings.new_builder(whisker.default_content_size)
	for token in tokens {
		match token.token_type {
			.comment {
				// Empty buffer and skip adding the comment tag
				if buffer.len > 0 {
					simplified_tokens << Token{
						token_type: .normal
						content: buffer.str()
					}
				}
			}
			.normal {
				buffer.write_string(token.content)
			}
			else {
				// Empty buffer and add the token
				if buffer.len > 0 {
					simplified_tokens << Token{
						token_type: .normal
						content: buffer.str()
					}
				}
				simplified_tokens << token
			}
		}
	}
	if buffer.len > 0 {
		simplified_tokens << Token{
			token_type: .normal
			content: buffer.str()
		}
	}
	return simplified_tokens
}

fn extract_indentation(line string) string {
	mut indent_buffer := strings.new_builder(line.len)
	for ch in line {
		if ch in [` `, `\t`] {
			indent_buffer.write_u8(ch)
		} else {
			break
		}
	}
	return indent_buffer.str()
}

fn validate_indentation(lines []string) ! {
	mut space_count, mut tab_count := 0, 0
	for line in lines {
		indent := extract_indentation(line)
		for ch in indent {
			match ch {
				` ` {
					space_count++
				}
				`\t` {
					tab_count++
				}
				else {
					return error('Indentation processing failed. Obtained a non-whitespace character: "${ch}"')
				}
			}
		}
	}
	if space_count * tab_count != 0 {
		// Both were non-zero indicating mixed character usage
		return error('Please use consistent indentation. Do not mix spaces and tabs.')
	}
}

fn extract_line_ending(input string) !string {
	// Identify the line breaks
	mut r_count, mut n_count := 0, 0
	for ch in input {
		match ch {
			`\r` {
				r_count++
			}
			`\n` {
				n_count++
			}
			else {}
		}
	}

	// Does the template have only one line
	if r_count == 0 && n_count == 0 {
		return '\n'
	} else if r_count == 0 && n_count != 0 {
		return '\n'
	} else if r_count != 0 && n_count == 0 {
		return '\r'
	} else if r_count == n_count {
		lines := input.split('\r\n')
		if abs(n_count - lines.len) > 2 {
			return error('Improper line endings used. Please use only "\\n", "\\r", or "\\r\\n".')
		}
		return '\r\n'
	} else {
		return error('Mixed line endings used. Please use only "\\n", "\\r", or "\\r\\n".')
	}
}

fn flatten_lines(lines []TokenLine, line_ending string) []Token {
	mut tokens := []Token{}
	mut add_newline := false
	for line in lines {
		if add_newline {
			tokens << Token{
				token_type: .normal
				content: line_ending
			}
		}
		mut simple_line := []Token{cap: line.tokens.len}
		for token in line.tokens {
			if token.token_type == .normal && token.content.len == 0 {
				continue
			}
			simple_line << token
		}

		// Check for standalone comment and section tags.
		// The idea is that they are completely removed if they are not inline
		// and the indentation and newlines do not persist.
		if simple_line.len > 0 && simple_line.last().token_type !in [.normal, .tag] {
			if simple_line.len == 2 && simple_line.first().content.trim_space().len == 0 {
				simple_line.delete(0)
				add_newline = false
			} else if simple_line.len == 1 {
				add_newline = false
			} else {
				// It is inline
				add_newline = true
			}
		} else {
			add_newline = true
		}

		tokens << simple_line
	}

	return tokens
}
