#include "match.h"
#include "languagelexer.h"

Match::Match(Cursor *cursor) {
	this->cursor = cursor;
	this->range = new CursorRange(
		new Cursor(*cursor), new Cursor(*cursor)
	);
	this->matching = true;
	this->curr_val = false;
	this->invert = false;
	this->optional = false;
	this->exception_msg = "";
}

void Match::test_exception() {
	if (!exception_msg.empty() && !curr_val) {
		std::string s = "";

		int p_pos = cursor->pos;
		while (!cursor->eof) {
			if (
				cursor->character == '\n' ||
				cursor->character == '\t' ||
				cursor->character == ' '
			) break;
			s += cursor->character;
			cursor->walk();
		}
		cursor->move(p_pos);

		throw ParseException(
			exception_msg, new Cursor(*cursor)
		);

		exception_msg = "";
	}
}

void Match::push_string_stack(std::string *s) {
	string_stack.push_back(s);
}

void Match::push_range_stack(CursorRange *r) {
	range_stack.push_back(r);
}

void Match::push_string_stack(std::vector<std::string *> new_stack) {
	for (int i = 0; i < new_stack.size(); i++) {
		push_string_stack(new_stack[i]);
	}
}

void Match::push_range_stack(std::vector<CursorRange *> new_stack) {
	for (int i = 0; i < new_stack.size(); i++) {
		push_range_stack(new_stack[i]);
	}
}

