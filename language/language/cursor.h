#ifndef CURSOR_H
#define CURSOR_H

#include <iostream>
#include <sstream>

struct Cursor
{
private:
	std::string *input;
	int input_length;
	int indent_size;
	bool indenting;

	char get_char(int p);

public:
	char character;
	int pos;
	int line;
	int column;
	std::string indent;
	bool eof;
	bool line_break;

	Cursor() {}
	Cursor(std::string *i, int indent_size = 1);

	void walk();
	void walk_times(int times);
	void move(int toPos);
	void skip_ignore();
	void print();
};

struct CursorRange
{
public:
	Cursor start;
	Cursor end;

	CursorRange() {}
	CursorRange(Cursor start, Cursor end) : start(start), end(end) {}
	const int length() {
		return (end.pos - start.pos) + 1;
	}
};

#endif