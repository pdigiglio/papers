// vim: set ft=cpp:
// Compiler flags: -std=c++20

#include <array>
#include <cstdio>

struct S
{
    S() { std::puts(__PRETTY_FUNCTION__); }
    ~S() { std::puts(__PRETTY_FUNCTION__); }
    S(S const&) { std::puts(__PRETTY_FUNCTION__); }
    S(S&&) = delete; // { std::puts(__PRETTY_FUNCTION__); }
    S& operator=(S const&) { std::puts(__PRETTY_FUNCTION__); return *this; }
    S& operator=(S&&) = delete; // { std::puts(__PRETTY_FUNCTION__); return *this; }
};

int main()
{
    {
        // Direct initialization of all elements.
        S c_arr[] = { {}, {}, {} };
    }

    std::puts("");

    {
        // Direct initialization of all elements.
        // Cannot omit S.
        std::array cpp_arr = { S{}, S{}, S{} };
    }

    std::puts("");

    {
        // to_array needs a C-style array as a temporary buffer.


        S c_arr[] = { {}, {}, {} };
        auto cpp_arr = std::to_array<S>(c_arr);

        // This doesn't compile for non-movable types. WTF
        //auto cpp_arr = std::to_array<S>({ {}, {}, {} });
    }
}
