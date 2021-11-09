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
		Cursor start = Cursor(get_range(-4).start);

		std::string class_name = get_str(-3);

		expect_next("Expected path string");
		T_STRING();

		std::string path = get_str(-1);

		Cursor end = Cursor(get_range(-1).end);

		t = new ImportToken(
			CursorRange(start, end),
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
		std::string var_name = get_str(-1);
		Cursor start = Cursor(get_range(-2).start);

		std::string type = "any";
		std::string value = "";

		open_match(true);
		match(":");
		b_and();
		T_SYMBOL();
		if (found_match())
		{
			type = get_str(-1);
		}
		close_match();

		open_match(true);
		match("=");
		b_and();
		T_LITERAL();
		if (found_match())
		{
			value = get_str(-1);
		}
		close_match();

		Cursor end = Cursor(get_range(-1).end);

		t = new VariableToken(
			CursorRange(start, end),
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
		std::string func_name = get_str(-1);
		Cursor start = Cursor(get_range(-2).start);
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
			return_type = get_str(-1);
		}
		close_match();

		Cursor end = Cursor(get_range(-1).end);

		t = new FunctionToken(
			CursorRange(start, end),
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
		std::string tag_open = get_str(-1);
		Cursor start = Cursor(get_range(-1).start);

		expect_next("Expected tag class name");
		T_SYMBOL();

		TagClassName *class_name = new TagClassName(
			CursorRange(get_range(-1)),
			get_str(-1)
		);

		std::vector<TagProperty *> props = tag_properties();

		expect_next("Expected tag close \"/>\" or \">\"");
		open_match();
		match("/>");
		b_or();
		match(">");
		close_match();

		std::string tag_close = get_str(-1);
		Cursor end = Cursor(get_range(-1).end);
		Cursor tag_close_start = Cursor(get_range(-1).start);

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
			CursorRange(start, end),
			tag_type, class_name, props);
	}

	close_match();

	return t;
}

std::vector<TagProperty *> GDXLanguageLexer::tag_properties()
{
	std::vector<TagProperty *> props;

	open_match(true);

	while (!cursor().eof)
	{
		open_match();
		T_SYMBOL(true);
		b_and();
		match("=");
		close_match();
		if (found_match())
		{
			std::string prop_name = get_str(-3);
			Cursor start = Cursor(get_range(-3).start);

			this->match("$");
			bool dollarSign = found_match();

			expect_next("Expected value a");
			open_match();
			T_LITERAL();
			b_or();
			T_FUNCTION();
			b_or();
			T_SYMBOL();
			b_or();
			T_GDBLOCK();
			close_match();

			std::string prop_value = dollarSign ? "$" + get_str(-2) : get_str(-2);
			Cursor end = Cursor(get_range(-1).end);

			props.push_back(new TagProperty(
				CursorRange(start, end),
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
		const static std::regex reg = std::regex("(_|[a-z]|[A-Z])(_|:|\\.|[a-z]|[A-Z]|[0-9])*");
		match(reg);
	}
	else
	{
		const static std::regex reg = std::regex("(_|[a-z]|[A-Z])(_|\\.|[a-z]|[A-Z]|[0-9])*");
		match(reg);
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
		const static std::regex reg = std::regex("\"\"\"(.|\n)*\"\"\"");
		const static std::regex treg = std::regex("\t");
		const static std::regex nreg = std::regex("\n");
		const static std::regex wsreg = std::regex(" +");

		match(std::regex(reg));
		if (found_match())
		{
			std::string ss = get_str(-1);
			ss = ss.substr(2, ss.size() - 4);
			ss = std::regex_replace(ss, std::regex(treg), "");
			ss = std::regex_replace(ss, std::regex(nreg), " ");
			ss = std::regex_replace(ss, std::regex(wsreg), " ");
			set_str(-1, ss);
		}
	}

	if (!found_match())
	{
		const static std::regex reg = std::regex("\".*?\"|\'.*?\'");
		match(reg);
	}

	close_match();
}

void GDXLanguageLexer::T_FLOAT()
{
	open_match();

	const static std::regex reg1 = std::regex("[+-]?[0-9]+\\.[0-9]*e[+-]?[0-9]+");
	const static std::regex reg2 = std::regex("[+-]?[0-9]+\\.[0-9]*[fF]?");

	match(std::regex(reg1));
	b_or();
	match(std::regex(reg2));

	close_match();
}

void GDXLanguageLexer::T_INT()
{
	open_match();

	const static std::regex reg1 = std::regex("[+-]?0x([0-9]|[a-f]|[A-F])+");
	const static std::regex reg2 = std::regex("[+-]?0b[01]+");
	const static std::regex reg3 = std::regex("[+-]?[0-9]+");

	match(std::regex(reg1));
	b_or();
	match(std::regex(reg2));
	b_or();
	match(std::regex(reg3));

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

		while (!cursor().eof)
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
				cursor().walk();
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
		std::string s = get_str(-1);
		CursorRange r = get_range(-1);
		set_str(
			-1,
			s.substr(1, s.size() - 2));
		Cursor start = Cursor(r.start);
		Cursor end = Cursor(r.end);
		start.move(start.pos + 1);
		end.move(end.pos - 1);
		set_range(-1, CursorRange(start, end));
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
		while (!cursor().eof)
		{
			if (i % 2 == 0)
			{
				if (i > 0)
				{
					expect_next("Expected value b");
				}
				open_match();
				T_LITERAL();
				b_or();
				T_FUNCTION();
				b_or();
				T_SYMBOL();
				b_or();
				T_GDBLOCK();
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
