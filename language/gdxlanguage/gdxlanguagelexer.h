#ifndef GDXLANGUAGELEXER_H
#define GDXLANGUAGELEXER_H

#include "../language/languagelexer.h"
#include <map>

struct ImportToken : public Token
{
public:
	std::string class_name;
	std::string relative_path;

	ImportToken(CursorRange *range,
				std::string class_name,
				std::string relative_path) : Token(range),
											 class_name(class_name),
											 relative_path(relative_path) {}
};

struct VariableToken : public Token
{
public:
	std::string name;
	std::string type;
	std::string value;

	VariableToken(
		CursorRange *range,
		std::string name,
		std::string type,
		std::string value) : Token(range),
							 name(name),
							 type(type),
							 value(value) {}
};

struct FunctionToken : public Token
{
public:
	std::string name;
	std::string return_type;
	std::vector<VariableToken *> args;

	FunctionToken(
		CursorRange *range,
		std::string name,
		std::string return_type,
		std::vector<VariableToken *> args) : Token(range), name(name), return_type(return_type), args(args) {}
};

struct TagClassName : public Token
{
public:
	std::string name;

	TagClassName(
		CursorRange *range,
		std::string name) : Token(range), name(name) {}
};

struct TagProperty : public Token
{
public:
	std::string name;
	std::string value;

	TagProperty(
		CursorRange *range,
		std::string name,
		std::string value) : Token(range), name(name), value(value) {}
};

struct TagToken : public Token
{
public:
	std::string type;
	TagClassName *class_name;
	std::vector<TagProperty *> properties;

	TagToken(
		CursorRange *range,
		std::string type,
		TagClassName *class_name,
		std::vector<TagProperty *> properties) : Token(range), type(type), class_name(class_name), properties(properties) {}
};

class GDXLanguageLexer : public LanguageLexer
{
public:
	virtual Token *get_token();
	ImportToken *import();
	VariableToken *variable(bool require_prefix = true);
	FunctionToken *function();
	TagToken *tag();

private:
	std::vector<TagProperty *> tag_properties();
	void T_SYMBOL(bool prop = false);
	void T_LITERAL();
	void T_STRING(bool multiline = false);
	void T_FLOAT();
	void T_INT();
	void T_GDBLOCK();
	void T_FUNCTION();
};

#endif