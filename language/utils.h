#ifndef UTILS_H
#define UTILS_H

#include <string>

class SFC32
{
private:
    unsigned int a;
    unsigned int b;
    unsigned int c;
    unsigned int d;

public:
    SFC32(unsigned int a, unsigned int b, unsigned int c, unsigned int d) : a(a), b(b), c(c), d(d) {}

    unsigned int get_next()
    {
        a >>= 0;
        b >>= 0;
        c >>= 0;
        d >>= 0;

        unsigned int t = (a + b) | 0;
        a = b ^ (b >> 9);
        b = (c + (c << 3)) | 0;
        c = (c << 21) | (c >> 11);
        d = (d + 1) | 0;
        t = (t + d) | 0;
        c = (c + t) | 0;

        return (t >> 0);
    }
};

std::string random_id(
    int len,
    int a,
    int b,
    int c,
    int d)
{
    SFC32 sfc(a, b, c, d);

    std::string res = "";
    std::string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    int num_chars = chars.length();

    for (int i = 0; i < len; i++)
    {
        unsigned int id = sfc.get_next() % num_chars;
        res += chars[id];
    }

    return res;
}

#endif