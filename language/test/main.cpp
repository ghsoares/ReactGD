#include "../gdxlanguage/gdxlanguagelexer.h"
#include "../gdxlanguage/gdxlanguageparser.h"
#include <fstream>
#include <sstream>
#include <chrono>

int main() {
	std::ifstream file;
	std::stringstream ss;
	file.open("test.gdx", std::ios::in);
	ss << file.rdbuf();

	GDXLanguageLexer *lexer = new GDXLanguageLexer();
	GDXLanguageParser *parser = new GDXLanguageParser(lexer);

	std::string source = ss.str();

	std::cout << "Input: " << std::endl;
	std::cout << source << std::endl;

	try {
		std::chrono::steady_clock::time_point begin = std::chrono::steady_clock::now();
		
		parser->parse(source);

		std::chrono::steady_clock::time_point end = std::chrono::steady_clock::now();
		auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(end - begin).count();
		
		std::cout << "Output: " << std::endl;
		std::cout << source << std::endl;

		std::cout << "Elapsed: " << elapsed << " ms" << std::endl;
	} catch (ParseException &e) {
		std::cerr << e.what() << std::endl;
	}

	return 0;
}