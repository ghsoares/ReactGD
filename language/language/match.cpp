#include "match.h"
#include "languagelexer.h"

Match::Match(Cursor cursor): cursor(cursor), range(cursor, cursor) {
	this->matching = true;
	this->curr_val = false;
	this->invert = false;
	this->optional = false;
	this->exception_msg = "";
	this->string_stack_size = 0;
	this->range_stack_size = 0;
}

void Match::test_exception() {
	if (!exception_msg.empty() && !curr_val) {
		std::string s = "";

		int p_pos = cursor.pos;
		while (!cursor.eof) {
			if (
				cursor.character == '\n' ||
				cursor.character == '\t' ||
				cursor.character == ' '
			) break;
			s += cursor.character;
			cursor.walk();
		}
		cursor.move(p_pos);

		throw ParseException(
			"Unexpected token " + s + ", " + exception_msg, Cursor(cursor)
		);
	}

	exception_msg = "";
}

void Match::push_string_stack(std::string s) {
	string_stack.push_back(s);
	string_stack_size++;
}

void Match::push_range_stack(CursorRange r) {
	range_stack.push_back(r);
	range_stack_size++;
}

void Match::push_string_stack(std::vector<std::string> new_stack, int len) {
	for (int i = 0; i < len; i++) {
		push_string_stack(new_stack[i]);
	}
}

void Match::push_range_stack(std::vector<CursorRange> new_stack, int len) {
	for (int i = 0; i < len; i++) {
		push_range_stack(new_stack[i]);
	}
}

