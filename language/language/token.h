#ifndef TOKEN_H
#define TOKEN_H

#include "cursor.h"

struct Token {
	public:
		CursorRange *range;

		Token(CursorRange *range): range(range) {};
		virtual ~Token() {};
};

#endif