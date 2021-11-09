#ifndef LANGUAGELEXER_H
#define LANGUAGELEXER_H

#include "match.h"
#include "token.h"
#include <vector>
#include <regex>

struct ParseException : public std::exception
{
public:
	std::string msg;
	Cursor cursor;

	explicit ParseException(std::string msg, Cursor cursor) : cursor(cursor)
	{
		std::stringstream ss;

		ss << "Parse exception at line " << cursor.line + 1 << " column " << cursor.column + 1;
		ss << " : " << msg;

		this->msg = ss.str();
	}

	const char *what() const throw()
	{
		return msg.c_str();
	}
};

class LanguageLexer
{
private:
	std::string *source;
	Match current_match;
	std::vector<Match> match_stack;

public:
	LanguageLexer() {}

	void reset();
	void set_source(std::string *source);
	std::string *get_source();

	std::string get_str(int pos);
	CursorRange get_range(int pos);
	void set_str(int pos, std::string str);
	void set_range(int pos, CursorRange range);

	void open_match(bool optional = false);

	Cursor &cursor();

	void b_and();
	void b_or();
	void b_not();
	void expect_next(const std::string msg);
	void expect_prev(const std::string msg);

	void match(const std::string str);
	void match(const std::regex reg);

	bool found_match();
	void close_match();

	bool get_next_token(Token* &token);

	virtual Token *get_token() = 0;
};

#endif