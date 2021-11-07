#ifndef GDXPARSER_H
#define GDXPARSER_H

#include "gdxlanguage/gdxlanguageparser.h"
#include <Godot.hpp>
#include <String.hpp>
#include <Reference.hpp>

namespace godot
{
	class GDXParser : public Reference
	{
		GODOT_CLASS(GDXParser, Reference)

		private:
			GDXLanguageLexer *lexer;
			GDXLanguageParser *parser;
		public:
			static void _register_methods();

			GDXParser();
    		~GDXParser();

			void _init();

			String parse(String source, String path);
	};

}

#endif