#include "gdxlanguageparser.h"
#include <sstream>
#include "../utils.h"

void GDXLanguageParser::replace_range(CursorRange range, std::string s)
{
    std::string prefix = source.substr(0, off + range.start.pos);
    std::string suffix = source.substr(off + range.end.pos + 1);

    source = prefix + s + suffix;

    int prevLen = range.length();
    int newLen = s.length();

    off += newLen - prevLen;
}

void GDXLanguageParser::get_declarations()
{
    variables.clear();
    functions.clear();

    Token *tk;

    while (!lexer->cursor().eof)
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

void GDXLanguageParser::parse_tag(TagToken *tag, bool first, bool last)
{
    if (tag->type == "SINGLE" || tag->type == "OPEN")
    {
        std::string class_name = tag->class_name->name;
        if (class_name == "self")
            class_name = "get_script()";

        Cursor start = tag->range.start;
        Cursor end = start;

        replace_range(CursorRange(start, end), "");

        start = tag->class_name->range.start;
        end = tag->class_name->range.end;
        std::vector<TagProperty *> props = tag->properties;
        
        /*std::string id = random_id(
            10,
            tag->range.start.line,
            tag->range.start.column,
            tag->range.end.line,
            tag->range.end.column
        );*/
        std::stringstream idss;
        idss << class_name << "_" << start.line << "_" << start.column;

        std::string repl = "ReactGD.create_node(\"" + idss.str() + "\", " + class_name;
        if (props.size() == 0) {
            repl += ", {}";
        } else {
            repl += ", {";
        }
        if (first) {
            repl = "[" + repl;
        }

        replace_range(CursorRange(start, end), repl);

        int i = 0;

        for (TagProperty *p : props)
        {
            start = p->range.start;
            end = p->range.end;

            std::stringstream ss;

            std::string name = p->name;
            std::string value = p->value;

            if (name.rfind("on_", 0) == 0) {
                value = "[self, \"" + value + "\"]";
            }

            ss << "\"" << name << "\": ";
            ss << value;

            if (i != props.size() - 1)
            {
                ss << ",";
            }
            else
            {
                ss << "}";
            }

            replace_range(CursorRange(start, end), ss.str());

            i++;
        }

        if (tag->type == "SINGLE")
        {
            end = tag->range.end;
            start = end;
            start.move(end.pos - 1);
            
            if (!last) {
                replace_range(CursorRange(start, end), ", []),");
            } else {
                replace_range(CursorRange(start, end), ", [])]");
            }
        }
        else
        {
            end = tag->range.end;
            start = end;
            replace_range(CursorRange(start, end), ", [");
        }
    }
    else
    {
        if (!last) {
            replace_range(tag->range, "]),");
        } else {
            replace_range(tag->range, "])]");
        }
    }
}

void GDXLanguageParser::parse(std::string &source, std::string base_dir)
{
    if (source.size() == 0) return;

    this->source = source;

    lexer->set_source(new std::string(source));

    //get_declarations();

    lexer->reset();
    off = 0;
    tree_stack.clear();

    Token *tk;

    while (!lexer->cursor().eof)
    {
        if (lexer->get_next_token(tk))
        {
            if (!tk) continue;

            ImportToken *import = dynamic_cast<ImportToken *>(tk);
            TagToken *tag = dynamic_cast<TagToken *>(tk);

            if (import != nullptr) {
                replace_range(
                    import->range,
                    "var " + import->class_name + " := ResourceLoader.load(\"" + base_dir + import->relative_path + "\".simplify_path()) as Script"
                );
            }
            if (tag != nullptr) {
                bool first = tree_stack.size() == 0;
                bool last = false;
                if (tag->type == "OPEN") {
                    tree_stack.push_back(tag);
                } else if (tag->type == "CLOSE") {
                    if (tree_stack.size() == 0) {
                        throw ParseException("Excess close tag", tag->range.start);
                    }
                    TagToken *parent = tree_stack[tree_stack.size() - 1];
                    if (tag->class_name->name != parent->class_name->name) {
                        throw ParseException("This tag is not closing parent tag \'" + parent->class_name->name + "\'", tag->range.start);
                    }
                    tree_stack.pop_back();
                    last = tree_stack.size() == 0;
                }
                parse_tag(tag, first, last);
            }
        }
    }

    if (tree_stack.size() > 0) {
        TagToken *first = tree_stack[tree_stack.size() - 1];
        throw ParseException("\'" + first->class_name->name + "\' closing tag expected", first->range.end);
    }

    source = this->source;
}
