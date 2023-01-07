module whisker

//
// import math { abs }
// import strings
//
// const (
// 	max_line_length = 200
// )
//
// struct InputLines {
// 	lines   []string
// 	newline string = '\n'
// }
//
// fn extract_lines(input string) !InputLines {
// 	// Identify the line breaks
// 	mut r_count, mut n_count := 0, 0
// 	for ch in input {
// 		match ch {
// 			`\r` {
// 				r_count++
// 			}
// 			`\n` {
// 				n_count++
// 			}
// 			else {}
// 		}
// 	}
//
// 	// Does the template have only one line
// 	if r_count == 0 && n_count == 0 {
// 		return InputLines{
// 			lines: [input]
// 		}
// 	} else if r_count == 0 && n_count != 0 {
// 		return InputLines{
// 			lines: input.split('\n')
// 		}
// 	} else if r_count != 0 && n_count == 0 {
// 		return InputLines{
// 			lines: input.split('\r')
// 			newline: '\r'
// 		}
// 	} else if r_count == n_count {
// 		lines := input.split('\r\n')
// 		if abs(n_count - lines.len) > 2 {
// 			return error('Improper line endings used. Please use only "\\n", "\\r", or "\\r\\n".')
// 		}
// 		return InputLines{
// 			lines: lines
// 			newline: '\r\n'
// 		}
// 	} else {
// 		return error('Mixed line endings used. Please use only "\\n", "\\r", or "\\r\\n".')
// 	}
// }
//
// fn (input_lines InputLines) validate_line_lengths() ! {
// 	for index, line in input_lines.lines {
// 		if line.len > whisker.max_line_length {
// 			return error('Line ${index + 1} is larger than maximum allowed length (${200}).')
// 		}
// 	}
// }
//
// fn extract_indentation(line string) string {
// 	mut indent_buffer := strings.new_builder(line.len)
// 	for ch in line {
// 		if ch in [` `, `\t`] {
// 			indent_buffer.write_u8(ch)
// 		} else {
// 			break
// 		}
// 	}
// 	return indent_buffer.str()
// }
//
// fn (input_lines InputLines) validate_indentation() ! {
// 	mut space_count, mut tab_count := 0, 0
// 	for line in input_lines.lines {
// 		indent := extract_indentation(line)
// 		for ch in indent {
// 			match ch {
// 				` ` {
// 					space_count++
// 				}
// 				`\t` {
// 					tab_count++
// 				}
// 				else {
// 					return error('Indentation processing failed. Obtained a non-whitespace character: "${ch}"')
// 				}
// 			}
// 		}
// 	}
// 	if space_count * tab_count != 0 {
// 		// Both were non-zero indicating mixed character usage
// 		return error('Please use consistent indentation. Do not mix spaces and tabs.')
// 	}
// }
//
// enum TokenType {
// 	normal
// 	indent
// 	newline
// 	delim_left
// 	delim_right
// 	tag
// 	comment
// 	raw_string_tag
// 	open_section_tag
// 	close_section_tag
// }
//
// struct Token {
// 	content    string
// 	token_type TokenType
// }
//
// fn (token Token) str() string {
// 	return '${token.token_type}: "${token.content}"'
// }
//
// enum TokenizerState {
// 	// Normal state outside delimiters
// 	normal
// 	// Delimiter processing states
// 	delim_left_started
// 	delim_right_started
// 	// Active states inside delimiters
// 	active_delim_swap_left
// 	active_delim_swap_break
// 	active_delim_swap_right
// 	active_normal_tag
// 	active_comment_tag
// 	active_curly_raw_string_tag
// 	active_amp_raw_string_tag
// 	active_section_open_tag
// 	active_section_close_tag
// }
//
// struct Tokenizer {
// mut:
// 	buffer                 strings.Builder = strings.new_builder(whisker.max_line_length)
// 	tokens                 []Token = []Token{cap: 256}
// 	delim_left             string  = '{{'
// 	delim_right            string  = '}}'
// 	delim_offset           int
// 	swap_padding_skipped   bool
// 	incoming_closing_delim string
// 	current_state          TokenizerState = .normal
// 	previous_state         TokenizerState = .normal
// }
//
// fn (mut tokenizer Tokenizer) set_state(new_state TokenizerState) {
// 	tokenizer.previous_state = tokenizer.current_state
// 	tokenizer.current_state = new_state
// }
//
// fn (mut tokenizer Tokenizer) accept(input u8) ! {
// 	match tokenizer.current_state {
// 		.normal {
// 			// We are in the normal state. What we need to do is look out for
// 			// delimiter opening sequences and nothing else. Note that the delimiter
// 			// can be of varying lengths. So we must proceed accordingly.
// 			// This is where having the offset helps avoid excess computation.
// 			match input {
// 				tokenizer.delim_left[0] {
// 					// We found the first character of an opening delimiter.
//
// 					// Dump whatever was in the buffer until now to a normal token and save it.
// 					tokenizer.tokens << Token{
// 						content: tokenizer.buffer.str()
// 						token_type: .normal
// 					}
// 					tokenizer.buffer.clear()
//
// 					// Get ready to scan the entire delimiter opening string.
// 					tokenizer.set_state(.delim_left_started)
// 					tokenizer.delim_offset = 1
// 				}
// 				else {
// 					// Normal character. Write it to the buffer.
// 					tokenizer.buffer.write_u8(input)
// 				}
// 			}
// 		}
// 		.delim_left_started {
// 			// We have encountered characters so far that match with the opening delimiter string
// 			// until the delim_offset. If the delim_offset is the entire length of the string,
// 			// we have successfully matched the entire opening delimiter.
// 			if tokenizer.delim_offset == tokenizer.delim_left.len {
// 				tokenizer.tokens << Token{
// 					content: tokenizer.delim_left
// 					token_type: .delim_left
// 				}
// 				tokenizer.delim_offset = 0
// 				// We've successfully scanned a complete open delimiter.
// 				match input {
// 					`=` {
// 						// Delimiter change requested
// 						tokenizer.set_state(.active_delim_swap_left)
// 						tokenizer.swap_padding_skipped = false
// 					}
// 					`!` {
// 						// Comment block found
// 						tokenizer.set_state(.active_comment_tag)
// 					}
// 					`{` {
// 						// Triple braces raw string requested
// 						tokenizer.set_state(.active_curly_raw_string_tag)
// 					}
// 					`&` {
// 						// Ampersand prefixed raw string requested
// 						tokenizer.set_state(.active_amp_raw_string_tag)
// 					}
// 					`#` {
// 						// Section opening requested
// 						tokenizer.set_state(.active_section_open_tag)
// 					}
// 					`/` {
// 						// Section closing requested
// 						tokenizer.set_state(.active_section_close_tag)
// 					}
// 					// TODO: Add more active states here
// 					else {
// 						tokenizer.set_state(.active_normal_tag)
// 						tokenizer.buffer.write_u8(input)
// 					}
// 				}
// 			} else {
// 				// We haven't matched the entire opening delimiter yet.
// 				match input {
// 					tokenizer.delim_left[tokenizer.delim_offset] {
// 						// So far so good. We found the next character to match the expected
// 						// delimiter character here.
// 						tokenizer.delim_offset++
// 					}
// 					else {
// 						// False alarm. The character is different from what was expected.
// 						// Reset the state to normal and write the incomplete delimiter string to buffer.
// 						tokenizer.buffer.write_string(tokenizer.delim_left[0..tokenizer.delim_offset])
// 						tokenizer.buffer.write_u8(input)
// 						tokenizer.set_state(.normal)
// 						tokenizer.delim_offset = 0
// 					}
// 				}
// 			}
// 		}
// 		.active_normal_tag {
// 			match input {
// 				tokenizer.delim_right[0] {
// 					// The tag is starting to be closed
// 					tokenizer.tokens << Token{
// 						content: tokenizer.buffer.str()
// 						token_type: .tag
// 					}
// 					tokenizer.buffer.clear()
// 					tokenizer.set_state(.delim_right_started)
// 					tokenizer.delim_offset = 1
// 				}
// 				else {
// 					// Normally keep adding to the buffer
// 					tokenizer.buffer.write_u8(input)
// 				}
// 			}
// 		}
// 		.active_comment_tag {
// 			match input {
// 				tokenizer.delim_right[0] {
// 					tokenizer.tokens << Token{
// 						token_type: .comment
// 						content: ''
// 					}
// 					tokenizer.set_state(.delim_right_started)
// 					tokenizer.delim_offset = 1
// 				}
// 				else {
// 					// Do not process comment contents
// 				}
// 			}
// 		}
// 		.active_delim_swap_left {
// 			// We are acquiring information about the new opening delimiter
// 			if input in [` `, `\t`] {
// 				// Encountered a whitespace.
// 				if tokenizer.swap_padding_skipped {
// 					// This means the opening delimiter string is complete.
// 					tokenizer.delim_left = tokenizer.buffer.str()
// 					tokenizer.buffer.clear()
// 					tokenizer.set_state(.active_delim_swap_break)
// 					tokenizer.swap_padding_skipped = false
// 				}
// 			} else {
// 				// The opening delimiter definition continues
// 				tokenizer.buffer.write_u8(input)
// 				tokenizer.swap_padding_skipped = true
// 			}
// 		}
// 		.active_delim_swap_break {
// 			// We now need to skip ahead to when the closing delimiter begins
// 			if input !in [` `, `\t`] {
// 				// Found the first character for the closing delimiter
// 				tokenizer.buffer.write_u8(input)
// 				tokenizer.set_state(.active_delim_swap_right)
// 			}
// 		}
// 		.active_delim_swap_right {
// 			// Process the closing remaining characters of the delimiter
// 			match input {
// 				`=` {
// 					// The closing delimiter is complete
// 					tokenizer.incoming_closing_delim = tokenizer.buffer.str()
// 					tokenizer.buffer.clear()
// 					tokenizer.set_state(.delim_right_started)
// 					tokenizer.delim_offset = 0
// 				}
// 				// tokenizer.delim_right[0] {
// 				// 	// We've encountered the first character of the closing delimiter
// 				//
// 				// }
// 				` `, `\t` {
// 					// Skip trailing whitespace
// 				}
// 				else {
// 					// The new closing delimiter continues
// 					tokenizer.buffer.write_u8(input)
// 				}
// 			}
// 		}
// 		.active_curly_raw_string_tag {
// 			match input {
// 				`}` {
// 					tokenizer.tokens << Token{
// 						content: tokenizer.buffer.str()
// 						token_type: .raw_string_tag
// 					}
// 					tokenizer.buffer.clear()
// 					tokenizer.set_state(.delim_right_started)
// 					tokenizer.delim_offset = 0
// 				}
// 				else {
// 					tokenizer.buffer.write_u8(input)
// 				}
// 			}
// 		}
// 		.active_amp_raw_string_tag {
// 			match input {
// 				tokenizer.delim_right[0] {
// 					// The tag is starting to be closed
// 					tokenizer.tokens << Token{
// 						content: tokenizer.buffer.str()
// 						token_type: .raw_string_tag
// 					}
// 					tokenizer.buffer.clear()
// 					tokenizer.set_state(.delim_right_started)
// 					tokenizer.delim_offset = 1
// 				}
// 				else {
// 					// Normally keep adding to the buffer
// 					tokenizer.buffer.write_u8(input)
// 				}
// 			}
// 		}
// 		.active_section_open_tag {
// 			match input {
// 				tokenizer.delim_right[0] {
// 					// The tag is starting to be closed
// 					tokenizer.tokens << Token{
// 						content: tokenizer.buffer.str()
// 						token_type: .open_section_tag
// 					}
// 					tokenizer.buffer.clear()
// 					tokenizer.set_state(.delim_right_started)
// 					tokenizer.delim_offset = 1
// 				}
// 				else {
// 					// Normally keep adding to the buffer
// 					tokenizer.buffer.write_u8(input)
// 				}
// 			}
// 		}
// 		.active_section_close_tag {
// 			match input {
// 				tokenizer.delim_right[0] {
// 					// The tag is starting to be closed
// 					tokenizer.tokens << Token{
// 						content: tokenizer.buffer.str()
// 						token_type: .close_section_tag
// 					}
// 					tokenizer.buffer.clear()
// 					tokenizer.set_state(.delim_right_started)
// 					tokenizer.delim_offset = 1
// 				}
// 				else {
// 					// Normally keep adding to the buffer
// 					tokenizer.buffer.write_u8(input)
// 				}
// 			}
// 		}
// 		.delim_right_started {
// 			if tokenizer.delim_offset == tokenizer.delim_right.len {
// 				tokenizer.tokens << Token{
// 					content: tokenizer.delim_right
// 					token_type: .delim_right
// 				}
// 				if tokenizer.previous_state == .active_delim_swap_right {
// 					tokenizer.delim_right = tokenizer.incoming_closing_delim
// 					tokenizer.incoming_closing_delim = ''
// 					tokenizer.buffer.clear()
// 				}
// 				match input {
// 					tokenizer.delim_left[0] {
// 						// New delimiter starts immediately
// 						tokenizer.set_state(.delim_left_started)
// 						tokenizer.delim_offset = 1
// 					}
// 					else {
// 						tokenizer.buffer.write_u8(input)
// 						tokenizer.set_state(.normal)
// 					}
// 				}
// 			} else {
// 				match input {
// 					tokenizer.delim_right[tokenizer.delim_offset] {
// 						tokenizer.delim_offset++
// 					}
// 					else {
// 						tokenizer.buffer.write_string(tokenizer.delim_right[0..tokenizer.delim_offset])
// 						tokenizer.set_state(tokenizer.previous_state)
// 						tokenizer.delim_offset = 0
// 					}
// 				}
// 			}
// 		}
// 	}
// }
//
// fn (mut tokenizer Tokenizer) tokenize_line(line string) ! {
//
// }
//
// fn (mut tokenizer Tokenizer) tokenize(input_lines InputLines) ! {
// 	for line in input_lines.lines {
// 		indent := extract_indentation(line)
// 		dump(line)
// 		dump(tokenizer.current_state)
// 		if indent.len > 0 {
// 			tokenizer.tokens << Token{
// 				content: indent
// 				token_type: .indent
// 			}
// 		}
//
// 		for index := indent.len; index < line.len; index++ {
// 			// tokenizer.accept(line[index])!
// 		}
//
// 		// // Append a newline token
// 		// match tokenizer.current_state {
// 		// 	.normal {
// 		// 		tokenizer.tokens << Token{
// 		// 			token_type: .normal
// 		// 			content: tokenizer.buffer.str()
// 		// 		}
// 		// 		tokenizer.buffer.clear()
// 		// 		tokenizer.tokens << Token{
// 		// 			token_type: .newline
// 		// 			content: input_lines.newline
// 		// 		}
// 		// 	}
// 		// 	.delim_right_started {
// 		// 		match tokenizer.previous_state {
// 		// 			.active_comment_tag {
// 		// 				// Skip the line ending if we've just finished a comment
// 		// 				tokenizer.tokens << Token{
// 		// 					content: ''
// 		// 					token_type: .comment
// 		// 				}
// 		// 			}
// 		// 			.active_delim_swap_right {
// 		// 				tokenizer.delim_right = tokenizer.incoming_closing_delim
// 		// 				tokenizer.tokens << Token{
// 		// 					token_type: .delim_right
// 		// 					content: tokenizer.delim_right
// 		// 				}
// 		// 				tokenizer.buffer.clear()
// 		// 				tokenizer.tokens << Token{
// 		// 					token_type: .newline
// 		// 					content: input_lines.newline
// 		// 				}
// 		// 				tokenizer.set_state(.normal)
// 		// 			}
// 		// 			else {
// 		// 				tokenizer.tokens << Token{
// 		// 					token_type: .delim_right
// 		// 					content: tokenizer.delim_right
// 		// 				}
// 		// 				tokenizer.buffer.clear()
// 		// 				tokenizer.tokens << Token{
// 		// 					token_type: .newline
// 		// 					content: input_lines.newline
// 		// 				}
// 		// 				tokenizer.set_state(.normal)
// 		// 			}
// 		// 		}
// 		// 	}
// 		// 	.active_comment_tag {
// 		// 		// Continue processing
// 		// 	}
// 		// 	else {
// 		// 		println(tokenizer)
// 		// 		return error('Tokenizer in an invalid state: ${tokenizer}')
// 		// 	}
// 		// }
// 	}
//
// 	tokenizer.simplify_token_list()!
// }
//
// fn (mut tokenizer Tokenizer) simplify_token_list() ! {
// 	// Exit if there are no tokens to process
// 	if tokenizer.tokens.len == 0 {
// 		return
// 	}
// 	mut simplified_tokens := []Token{cap: tokenizer.tokens.len}
//
// 	// Keep the non-empty normal tokens and tags. Skip the delimiters
// 	for index := 0; index < tokenizer.tokens.len; index++ {
// 		token := tokenizer.tokens[index]
// 		match token.token_type {
// 			.normal {
// 				if token.content.len > 0 {
// 					simplified_tokens << token
// 				}
// 			}
// 			.delim_left {
// 				// Skip
// 			}
// 			.delim_right {
// 				// Skip
// 			}
// 			else {
// 				simplified_tokens << token
// 			}
// 		}
// 	}
//
// 	// Remove comments and indented comment blocks
// 	mut comment_free_tokens := []Token{cap: simplified_tokens.len}
// 	dump(simplified_tokens)
// 	for index, token in simplified_tokens {
// 		match token.token_type {
// 			.indent {
// 				if index < simplified_tokens.len - 1
// 					&& simplified_tokens[index + 1].token_type != .comment {
// 					comment_free_tokens << token
// 				}
// 			}
// 			.comment {
// 				// Skip comment
// 			}
// 			else {
// 				comment_free_tokens << token
// 			}
// 		}
// 	}
//
// 	// Concatenate consecutive normal tokens
// 	mut normal_buffer := strings.new_builder(whisker.max_line_length)
// 	mut concatenated_tokens := []Token{cap: comment_free_tokens.len}
// 	for token in comment_free_tokens {
// 		match token.token_type {
// 			.normal {
// 				normal_buffer.write_string(token.content)
// 			}
// 			else {
// 				if normal_buffer.len > 0 {
// 					concatenated_tokens << Token{
// 						content: normal_buffer.str()
// 						token_type: .normal
// 					}
// 					normal_buffer.clear()
// 				}
// 				concatenated_tokens << token
// 			}
// 		}
// 	}
// 	if normal_buffer.len > 0 {
// 		concatenated_tokens << Token{
// 			content: normal_buffer.str()
// 			token_type: .normal
// 		}
// 	}
//
// 	tokenizer.tokens = concatenated_tokens
// }
