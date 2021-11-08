#include "gdxlanguagelexer.h"

Token *GDXLanguageLexer::get_token()
{
	if (ImportToken *t = import())
	{
		return t;
	}

	if (VariableToken *t = variable())
	{
		return t;
	}

	if (FunctionToken *t = function())
	{
		return t;
	}

	if (TagToken *t = tag())
	{
		return t;
	}

	return nullptr;
}

ImportToken *GDXLanguageLexer::import()
{
	ImportToken *t = nullptr;

	open_match();

	open_match();
	match("import");
	b_and();
	T_SYMBOL();
	b_and();
	match("from");
	close_match();
	if (found_match())
	{
		Cursor *start = get_range(-4)->start;

		std::string class_name = *get_str(-3);

		expect_next("Expected path string");
		T_STRING();

		std::string path = *get_str(-1);

		Cursor *end = get_range(-1)->end;

		t = new ImportToken(
			new CursorRange(new Cursor(*start), new Cursor(*end)),
			class_name,
			path.substr(1, path.size() - 2)
		);
	}

	close_match();

	return t;
}

VariableToken *GDXLanguageLexer::variable(bool require_prefix)
{
	VariableToken *t = nullptr;

	open_match();

	match("var");
	if (require_prefix)
		b_and();
	T_SYMBOL();

	if (found_match())
	{
		std::string var_name = *get_str(-1);
		Cursor *start = get_range(-2)->start;

		std::string type = "any";
		std::string value = "";

		open_match(true);
		match(":");
		b_and();
		T_SYMBOL();
		if (found_match())
		{
			type = *get_str(-1);
		}
		close_match();

		open_match(true);
		match("=");
		b_and();
		T_LITERAL();
		if (found_match())
		{
			value = *get_str(-1);
		}
		close_match();

		Cursor *end = get_range(-1)->end;

		t = new VariableToken(
			new CursorRange(new Cursor(*start), new Cursor(*end)),
			var_name,
			type,
			value);
	}

	close_match();

	return t;
}

FunctionToken *GDXLanguageLexer::function()
{
	FunctionToken *t = nullptr;

	open_match();

	match("func");
	b_and();
	T_SYMBOL();

	if (found_match())
	{
		std::string func_name = *get_str(-1);
		Cursor *start = get_range(-2)->start;
		std::vector<VariableToken *> args;

		match("(");

		while (VariableToken *arg = variable(false))
		{
			args.push_back(arg);
			match(",");
			if (!found_match())
				break;
		}

		match(")");

		std::string return_type = "any";

		open_match(true);
		match("->");
		b_and();
		T_SYMBOL();
		if (found_match())
		{
			return_type = *get_str(-1);
		}
		close_match();

		Cursor *end = get_range(-1)->end;

		t = new FunctionToken(
			new CursorRange(new Cursor(*start), new Cursor(*end)),
			func_name,
			return_type,
			args);
	}

	close_match();

	return t;
}

TagToken *GDXLanguageLexer::tag()
{
	TagToken *t = nullptr;

	open_match();

	open_match();
	match("</");
	b_or();
	match("<");
	close_match();

	if (found_match())
	{
		std::string tag_open = *get_str(-1);
		Cursor *start = get_range(-1)->start;

		expect_next("Expected tag class name");
		T_SYMBOL();

		TagClassName *class_name = new TagClassName(
			new CursorRange(*get_range(-1)),
			*get_str(-1)
		);

		std::vector<TagProperty *> props = tag_properties();

		expect_next("Expected tag close \"/>\" or \">\"");
		open_match();
		match("/>");
		b_or();
		match(">");
		close_match();

		std::string tag_close = *get_str(-1);
		Cursor *end = get_range(-1)->end;
		Cursor *tag_close_start = get_range(-1)->start;

		std::string tag_type = "";

		if (tag_open == "<")
		{
			if (tag_close == ">")
			{
				tag_type = "OPEN";
			}
			else
			{
				tag_type = "SINGLE";
			}
		}
		else
		{
			if (tag_close == ">")
			{
				tag_type = "CLOSE";
			}
			else
			{
				throw ParseException("Can't end closing tag with \"/>\"", tag_close_start);
			}
		}

		t = new TagToken(
			new CursorRange(new Cursor(*start), new Cursor(*end)),
			tag_type, class_name, props);
	}

	close_match();

	return t;
}

std::vector<TagProperty *> GDXLanguageLexer::tag_properties()
{
	std::vector<TagProperty *> props;

	open_match(true);

	while (!cursor()->eof)
	{
		open_match();
		T_SYMBOL(true);
		b_and();
		match("=");
		close_match();
		if (found_match())
		{
			std::string prop_name = *get_str(-3);
			Cursor start = *get_range(-3)->start;

			this->match("$");
			bool dollarSign = found_match();

			open_match();
			T_LITERAL();
			b_or();
			T_FUNCTION();
			b_or();
			T_SYMBOL();
			b_or();
			T_GDBLOCK();
			expect_prev("Expected value");
			close_match();

			std::string prop_value = dollarSign ? "$" + *get_str(-2) : *get_str(-2);
			Cursor end = *get_range(-2)->end;

			props.push_back(new TagProperty(
				new CursorRange(new Cursor(start), new Cursor(end)),
				prop_name, prop_value
			));
		}
		else
			break;
	}

	close_match();

	return props;
}

void GDXLanguageLexer::T_SYMBOL(bool prop)
{
	if (prop)
	{
		match(std::regex("(_|[a-z]|[A-Z])(_|:|\\.|[a-z]|[A-Z]|[0-9])*"));
	}
	else
	{
		match(std::regex("(_|[a-z]|[A-Z])(_|\\.|[a-z]|[A-Z]|[0-9])*"));
	}
}

void GDXLanguageLexer::T_LITERAL()
{
	open_match();

	T_STRING();
	b_or();
	T_FLOAT();
	b_or();
	T_INT();

	close_match();
}

void GDXLanguageLexer::T_STRING(bool multiline)
{
	open_match();

	if (multiline)
	{
		match(std::regex("\"\"\"(.|\n)*\"\"\""));
		if (found_match())
		{
			std::string ss = *get_str(-1);
			ss = ss.substr(2, ss.size() - 4);
			ss = std::regex_replace(ss, std::regex("\t"), "");
			ss = std::regex_replace(ss, std::regex("\n"), " ");
			ss = std::regex_replace(ss, std::regex(" +"), " ");
			set_str(-1, new std::string(ss));
		}
	}

	if (!found_match())
	{
		match(std::regex("\".*?\"|\'.*?\'"));
	}

	close_match();
}

void GDXLanguageLexer::T_FLOAT()
{
	open_match();

	//std::regex("\"\"\"(.|\n)*\"\"\"")
	match(std::regex("[+-]?[0-9]+\\.[0-9]*e[+-]?[0-9]+"));
	b_or();
	match(std::regex("[+-]?[0-9]+\\.[0-9]*[fF]?"));

	close_match();
}

void GDXLanguageLexer::T_INT()
{
	open_match();

	match(std::regex("[+-]?0x([0-9]|[a-f]|[A-F])+"));
	b_or();
	match(std::regex("[+-]?0b[01]+"));
	b_or();
	match(std::regex("[+-]?[0-9]+"));

	close_match();
}

void GDXLanguageLexer::T_GDBLOCK()
{
	open_match();

	bool found = false;

	match("{");

	if (found_match())
	{
		int lvl = 0;

		while (!cursor()->eof)
		{
			bool walk = true;
			match("{");
			if (found_match())
			{
				lvl++;
				walk = false;
			}
			match("}");
			if (found_match())
			{
				lvl--;
				walk = false;
				if (lvl < 0)
					break;
			}
			if (walk)
				cursor()->walk();
		}
		if (lvl >= 0)
		{
			throw ParseException("Couldn't find GD block end", cursor());
		}

		found = true;
	}

	close_match();

	if (found)
	{
		std::string s = *get_str(-1);
		CursorRange *r = get_range(-1);
		set_str(
			-1,
			new std::string(s.substr(1, s.size() - 2)));
		Cursor *start = new Cursor(*r->start);
		Cursor *end = new Cursor(*r->end);
		start->move(start->pos + 1);
		end->move(end->pos - 1);
		set_range(-1, new CursorRange(start, end));
	}
}

void GDXLanguageLexer::T_FUNCTION()
{
	open_match();

	T_SYMBOL();
	b_and();
	match("(");

	if (found_match())
	{
		int i = 0;
		while (!cursor()->eof)
		{
			if (i % 2 == 0)
			{
				open_match();
				T_LITERAL();
				b_or();
				T_FUNCTION();
				b_or();
				T_SYMBOL();
				b_or();
				T_GDBLOCK();
				if (i > 0)
				{
					expect_prev("Expected value");
				}
				close_match();
				if (!found_match())
					break;
			}
			else
			{
				match(",");
				if (!found_match())
					break;
			}
			i++;
		}
		expect_next("Expected \")\"");
		match(")");
	}

	close_match();
}
