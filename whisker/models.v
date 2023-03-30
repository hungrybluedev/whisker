module whisker

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
