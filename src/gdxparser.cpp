#include "gdxparser.h"

using namespace godot;

void GDXParser::_register_methods()
{
	register_method("parse", &GDXParser::parse);
}

GDXParser::GDXParser()
{
}

GDXParser::~GDXParser()
{
}

void GDXParser::_init()
{
	this->lexer = new GDXLanguageLexer();
	this->parser = new GDXLanguageParser(lexer);
}

String GDXParser::parse(String s_source, String s_path)
{
	std::string source = std::string(s_source.utf8().get_data());
	std::string path = std::string(s_path.utf8().get_data());

	std::string ss = this->parser->parse(source, path);

	return String(ss.c_str());
}
