module whisker

[heap]
struct Node {
	token Token
mut:
	next &Node = unsafe { nil }
	jump &Node = unsafe { nil }
}

pub fn (node Node) str() string {
	next := if unsafe { node.next == nil } { '' } else { node.next.str() }
	skip := if unsafe { node.jump == nil } { '' } else { node.jump.str() }
	return '{${node.token}}\n${next}\n${skip}'.trim_space()
}

[heap]
struct Program {
	len  int
	head &Node = unsafe { nil }
mut:
	tail &Node = unsafe { nil }
}

pub fn build_node_tree(fragment []Token) !Program {
	if fragment.len == 0 {
		return error('Cannot build a program from an empty fragment.')
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
	for unsafe { current != nil } {
		match current.token.token_type {
			.positive_section, .negative_section, .map_section, .list_section {
				// Found the beginning of a skippable section
				// We save the name of the section and look for the closing section
				name := current.token.content
				mut section := current
				for unsafe { section != nil } && !(section.token.token_type == .close_section
					&& section.token.content == name) {
					section = section.next
				}

				if unsafe { section == nil } {
					return error('Missing a closing section for: ${name}')
				}

				// We now have the corresponding closing section
				current.jump = section.next
				section.jump = current
			}
			else {}
		}
		current = current.next
	}
}
