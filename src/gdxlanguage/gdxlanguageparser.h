#ifndef GDXLANGUAGEPARSER_H
#define GDXLANGUAGEPARSER_H

#include "gdxlanguagelexer.h"

class GDXLanguageParser
{
private:
    GDXLanguageLexer *lexer;
    std::string source;
    std::vector<VariableToken *> variables;
    std::vector<FunctionToken *> functions;
    int off;
    std::vector<TagToken *> tree_stack;

    void replace_range(CursorRange *range, std::string s);
    void get_declarations();
    void parse_tag(TagToken *tag);

public:
    GDXLanguageParser(GDXLanguageLexer *lexer) : lexer(lexer) {}

    std::string parse(std::string source, std::string path);
};

#endif