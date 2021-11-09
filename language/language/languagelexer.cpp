#include "languagelexer.h"

void LanguageLexer::reset()
{
	current_match = Match(
		Cursor(get_source()));
	match_stack.clear();
}

void LanguageLexer::set_source(std::string *source)
{
	this->source = source;
	reset();
}

std::string *LanguageLexer::get_source()
{
	return source;
}

std::string LanguageLexer::get_str(int pos)
{
	std::vector<std::string> &stack = current_match.string_stack;

	if (stack.size() == 0)
		return *source;
	while (pos < 0)
		pos += stack.size();
	while (pos >= stack.size())
		pos -= stack.size();

	return stack[pos];
}

CursorRange LanguageLexer::get_range(int pos)
{
	std::vector<CursorRange> &stack = current_match.range_stack;

	if (stack.size() == 0)
		return CursorRange();
	while (pos < 0)
		pos += stack.size();
	while (pos >= stack.size())
		pos -= stack.size();

	return stack[pos];
}

void LanguageLexer::set_str(int pos, std::string str)
{
	std::vector<std::string> &stack = current_match.string_stack;

	if (stack.size() == 0)
		return;
	while (pos < 0)
		pos += stack.size();
	while (pos >= stack.size())
		pos -= stack.size();

	stack[pos] = str;
}

void LanguageLexer::set_range(int pos, CursorRange range)
{
	std::vector<CursorRange> &stack = current_match.range_stack;

	if (stack.size() == 0)
		return;
	while (pos < 0)
		pos += stack.size();
	while (pos >= stack.size())
		pos -= stack.size();

	stack[pos] = range;
}

void LanguageLexer::open_match(bool optional)
{
	match_stack.push_back(current_match);
	current_match.cursor.skip_ignore();
	current_match = Match(current_match.cursor);
	current_match.optional = optional;
}

Cursor &LanguageLexer::cursor()
{
	return current_match.cursor;
}

void LanguageLexer::b_and()
{
	if (!current_match.matching)
		return;

	if (!current_match.curr_val)
	{
		current_match.matching = false;
	}

	return;
}

void LanguageLexer::b_or()
{
	if (!current_match.matching)
		return;

	if (current_match.curr_val)
	{
		current_match.matching = false;
	}

	return;
}

void LanguageLexer::b_not()
{
	if (!current_match.matching)
		return;

	current_match.invert = true;

	return;
}

void LanguageLexer::expect_next(const std::string msg)
{
	if (!current_match.matching)
		return;

	current_match.exception_msg = msg;

	return;
}

void LanguageLexer::expect_prev(const std::string msg)
{
	if (!current_match.matching)
		return;

	current_match.exception_msg = msg;
	current_match.test_exception();

	return;
}

void LanguageLexer::match(const std::string str)
{
	if (!current_match.matching)
		return;
	current_match.cursor.skip_ignore();

	current_match.curr_val = false;

	std::string s = source->substr(current_match.cursor.pos, str.length());

	current_match.curr_val = s == str;

	if (current_match.invert)
	{
		current_match.curr_val = !current_match.curr_val;
	}
	else if (current_match.curr_val)
	{
		Cursor start = Cursor(current_match.cursor);
		current_match.cursor.walk_times(str.length() - 1);
		Cursor end = Cursor(current_match.cursor);

		current_match.push_string_stack(std::string(s));
		current_match.push_range_stack(CursorRange(start, end));

		current_match.range.end = end;
		current_match.cursor.walk();
	}

	current_match.test_exception();
	current_match.invert = false;

	return;
}

void LanguageLexer::match(const std::regex reg)
{
	if (!current_match.matching)
		return;
	current_match.cursor.skip_ignore();

	current_match.curr_val = false;

	std::string ss = source->substr(current_match.cursor.pos);
	std::smatch m;

	bool found = std::regex_search(ss, m, reg);
	current_match.curr_val = found && m.position() == 0;

	if (current_match.invert)
	{
		current_match.curr_val = !current_match.curr_val;
	}
	else if (current_match.curr_val)
	{
		Cursor start = Cursor(current_match.cursor);
		current_match.cursor.walk_times(m.length() - 1);
		Cursor end = Cursor(current_match.cursor);

		current_match.push_string_stack(std::string(m[0]));
		current_match.push_range_stack(CursorRange(start, end));

		current_match.range.end = end;
		current_match.cursor.walk();
	}

	current_match.test_exception();
	current_match.invert = false;

	return;
}

bool LanguageLexer::found_match()
{
	return current_match.curr_val;
}

void LanguageLexer::close_match()
{
	if (match_stack.size() == 0)
	{
		throw "Closing more matches than opening";
	}

	Match prev_match = current_match;
	current_match = match_stack[match_stack.size() - 1];
	match_stack.pop_back();

	if (current_match.matching)
	{
		current_match.curr_val = prev_match.curr_val || prev_match.optional;
		current_match.test_exception();

		if (prev_match.curr_val || prev_match.optional)
		{
			current_match.cursor.move(prev_match.cursor.pos);

			current_match.push_string_stack(prev_match.string_stack);
			current_match.push_range_stack(prev_match.range_stack);

			std::string ss = source->substr(
				prev_match.range.start.pos,
				prev_match.range.length());

			current_match.push_string_stack(std::string(ss));
			current_match.push_range_stack(prev_match.range);

			current_match.range.end = prev_match.range.end;
		}
	}
}

bool LanguageLexer::get_next_token(Token *&token)
{
	if (!current_match.cursor.eof)
	{
		Token *tk = get_token();
		if (match_stack.size() > 0)
		{
			throw "Not closing all opened matches!";
		}
		if (tk)
		{
			token = tk;
		}
		else
		{
			token = nullptr;
			current_match.cursor.walk();
		}

		return true;
	}
	else
	{
		return false;
	}
}
