#include "gdxlanguageparser.h"
#include <sstream>
#include "../utils.h"

void GDXLanguageParser::replace_range(CursorRange *range, std::string s)
{
    std::string prefix = source.substr(0, off + range->start->pos);
    std::string suffix = source.substr(off + range->end->pos + 1);

    source = prefix + s + suffix;

    int prevLen = range->length();
    int newLen = s.length();

    off += newLen - prevLen;
}

void GDXLanguageParser::get_declarations()
{
    variables.clear();
    functions.clear();

    Token *tk;

    while (!lexer->cursor()->eof)
    {
        if (lexer->get_next_token(tk))
        {
            if (!tk) continue;

            VariableToken *var = dynamic_cast<VariableToken *>(tk);
            FunctionToken *func = dynamic_cast<FunctionToken *>(tk);
            ImportToken *imp = dynamic_cast<ImportToken *>(tk);

            if (var)
            {
                variables.push_back(var);
            }
            if (func)
            {
                functions.push_back(func);
            }
            if (imp)
            {
                variables.push_back(new VariableToken(
                    imp->range,
                    imp->class_name,
                    "any",
                    ""));
            }
        }
    }
}

void GDXLanguageParser::parse_tag(TagToken *tag)
{
    if (tag->type == "SINGLE" || tag->type == "OPEN")
    {
        std::string class_name = tag->class_name->name;
        if (class_name == "self")
            class_name = "get_script()";

        Cursor start = *tag->range->start;
        Cursor end = start;

        replace_range(new CursorRange(new Cursor(start), new Cursor(end)), "");

        start = *tag->class_name->range->start;
        end = *tag->class_name->range->end;
        std::vector<TagProperty *> props = tag->properties;
        
        std::string id = random_id(
            4,
            tag->range->start->line,
            tag->range->start->column,
            tag->range->end->line,
            tag->range->end->column
        );

        std::string repl = "ReactGD.create_node(" + class_name;
        if (props.size() == 0) {
            repl += ", {}";
        } else {
            repl += ", {";
        }

        replace_range(new CursorRange(new Cursor(start), new Cursor(end)), repl);

        int i = 0;

        for (TagProperty *p : props)
        {
            start = *p->range->start;
            end = *p->range->end;

            std::stringstream ss;

            ss << "\"" << p->name << "\": ";
            ss << p->value;

            if (i != props.size() - 1)
            {
                ss << ",";
            }
            else
            {
                ss << "}";
            }

            replace_range(new CursorRange(new Cursor(start), new Cursor(end)), ss.str());

            i++;
        }

        if (tag->type == "SINGLE")
        {
            end = *tag->range->end;
            start = end;
            start.move(end.pos - 1);

            replace_range(new CursorRange(new Cursor(start), new Cursor(end)), ", [])");
        }
        else
        {
            end = *tag->range->end;
            start = end;
            replace_range(new CursorRange(new Cursor(start), new Cursor(end)), ", [");
        }
    }
    else
    {
        replace_range(tag->range, "])");
    }
}

void GDXLanguageParser::parse(std::string &source)
{
    if (source.size() == 0) return;

    this->source = source;

    lexer->set_source(new std::string(source));

    get_declarations();

    lexer->reset();
    off = 0;
    tree_stack.clear();

    Token *tk;

    while (!lexer->cursor()->eof)
    {
        if (lexer->get_next_token(tk))
        {
            if (!tk) continue;

            ImportToken *import = dynamic_cast<ImportToken *>(tk);
            TagToken *tag = dynamic_cast<TagToken *>(tk);

            if (import != nullptr) {
                replace_range(
                    import->range,
                    "var " + import->class_name + " := ResourceLoader.load(\"" + import->relative_path + "\") as Script"
                );
            }
            if (tag != nullptr) {
                parse_tag(tag);
            }
        }
    }

    source = this->source;
}
