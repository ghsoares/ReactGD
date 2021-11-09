#include "cursor.h"

Cursor::Cursor(std::string *input)
{
	this->input = input;
	this->input_length = input->size();
	this->pos = 0;
	this->character = input->at(0);
	this->line = 0;
	this->column = 0;
	this->indent = "";
	this->indenting = true;
	this->eof = false;
	this->line_break = character == '\n';
}

char Cursor::get_char(int p)
{
	if (p < 0 || p >= input_length)
	{
		return EOF;
	}
	return input->at(p);
}

void Cursor::walk()
{
	pos++;
	column++;

	if (line_break)
	{
		line++;
		column = 0;
	}

	character = get_char(pos);
	eof = character == EOF;
	line_break = character == '\n';

	if (indenting)
	{
		if (character == '\t' || character == ' ')
			indent += character;
		else
			indenting = false;
	}

	if (line_break)
	{
		indenting = true;
		indent = "";
	}
}

void Cursor::walk_times(int times)
{
	for (int i = 0; i < times; i++)
		walk();
}

void Cursor::move(int pos)
{
	if (pos < 0)
		pos = 0;
	if (pos > input_length - 1)
		pos = input_length - 1;
	if (pos == this->pos)
		return;

	this->pos = 0;
	this->character = input->at(0);
	this->line = 0;
	this->column = 0;
	this->eof = false;
	this->line_break = character == '\n';

	while (this->pos < pos)
		walk();
}

void Cursor::skip_ignore()
{
	while (
			character == ' ' ||
			character == '\n' ||
			character == '\r' ||
			character == '\t')
		walk();

	if (character == '#')
	{
		while (!eof && character != '\n')
			walk();
	}

	while (
			character == ' ' ||
			character == '\n' ||
			character == '\r' ||
			character == '\t')
		walk();
}

void Cursor::print() {
	std::cout << "Char: " << character << "Line: " << line + 1 << " Column: " << column + 1 << " Pos: " << pos << std::endl;
}

