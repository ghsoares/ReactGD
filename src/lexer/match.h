#ifndef MATCH_H
#define MATCH_H

#include "cursor.h"
#include <vector>

struct Match
{
public:
	CursorRange *range;
	Cursor *cursor;
	bool matching;
	bool curr_val;
	bool invert;
	bool optional;
	std::string exception_msg;

	std::vector<std::string *> string_stack;
	std::vector<CursorRange *> range_stack;

	Match(Cursor *cursor);

	void test_exception();

	void push_string_stack(std::string *s);
	void push_range_stack(CursorRange *r);
	void push_string_stack(std::vector<std::string *> new_stack);
	void push_range_stack(std::vector<CursorRange *> new_stack);
};

#endif