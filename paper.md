---
title: "Tuple-like interface for C-style arrays"
document: P???
date: today
audience: Evolution
author:
    - name: Paolo Di Giglio
      email: p.digiglio91@gmail.com
---

<!-- I. Table of Contents -->

# Abstract

I propose the standard library should implement the tuple protocol for C-style
arrays `T[N]`.
The implementation I propose is designed after the existing implementation of
the tuple protocol for `std::array<T, N>`. 
<span style="color:red">Why this proposal?</span>

# Introduction

For a type `T` to be tuple-like:

 * The qualified-id `std::tuple_size<T>`{.cpp} names a complete class type with
a well-formed integral constant expression member named `value`;

 * Given a prvalue index `i` of type `std::size_t`{.cpp}, 
   * a search for the name `get` in the scope of `T` finds at least one declaration that is a function template whose first template parameter is a non-type parameter, the initializer is `e.get<i>()`{.cpp}.
   * Otherwise, the initializer is `get<i>(e)`{.cpp}, where get undergoes argument-dependent lookup.  In either case, `get<i>` is interpreted as a template-id.

 * Given a prvalue index `i` of type `std::size_t`{.cpp}, the qualified-id
`std::tuple_element<i, T>`{.cpp} names a complete class type with a member
`typedef type`{.cpp};


Type `U` is tuple-like if:

 * `std::tuple_size<U>`;
 * `std::tuple_element<I, U>`;
 * `std::get<I>(U{})`;



As of now, the standard library implements the tuple protocol for the following
types:

 * `std::tuple` (since C++11).
 * `std::pair` (since C++11);
 * `std::ranges::subrange` (since C++20);
 * `std::span` <span style="color:red">(?) check this</span>;
 * `std::array` (since C++11).

Users may introduce specializations of `tuple_size`, and `tuple_element`, and
`get` <span style="color:red">(in `std` or with ADL?)</span> for
program-defined types, if they need make them tuple like.

I propose the standard library should implement the tuple protocol for C-style
array types `T[N]`. The implementation should be consistent to the one that
already exists for `std::array<T,N>`.

In particular:

 * ...







<span style="color:red">What can be done with tuple-like types?</span>
(As a side note, it would provide compile-time checked accessors for `T[N]`).


# Motivation and Scope

```cpp
std::array<int, 3> a { 0, 1, 2 };
std::get<0>(a); // Ok: 0
std::get<1>(a); // Ok: 1
std::get<2>(a); // Ok: 2

// Ok: compilation error: index out of bounds
// std::get<3>(a); // Ok: 0


int a[] = { 0, 1, 2 };

```

```
int a[] = {1,2,3 /*, ... */ };
std::tupe t {a}; // ? 
```


_Why is this important? What kinds of problems does it address? What is the
intended user community? What level of programmers (novice, experienced,
expert) is it intended to support? What existing practice is it based on? How
widespread is its use? How long has it been in use? Is there a reference
implementation and test suite available for inspection?_

# Impact On the Standard

This proposal is a pure library extension.
It does not require changes to any standard classes or functions.
It has been implemented in standard C++.

This proposal does not require changes in the core language.
It does not produce changes in the core language either.
Even though the tuple protocol interferes with the core language, which provides structured-binding support for tuple-like types, the standard already defines special rules for structured bindings to C-style arrays.

# Design Decisions

_Why did you choose the specific design that you did? What alternatives did you
consider, and what are the tradeoffs? What are the consequences of your choice,
for users and implementers? What decisions are left up to implementers? If
there are any similar libraries in use, how do their design decisions compare
to yours?_

```cpp
#include <utility>

namespace std {

// Note: since T[N] is not a class type, the following 2 specializations of
// std::get must be defined before the definition of std::apply (in header
// <tuple>). See: https://clang.llvm.org/compatibility.html#dep_lookupd
template <std::size_t Idx, typename T, std::size_t N>
constexpr T& get(T (&arr)[N]) noexcept {
    static_assert(Idx < N, "Index out of bounds");
    return arr[Idx];
}

template <std::size_t Idx, typename T, std::size_t N>
constexpr T&& get(T (&&arr)[N]) noexcept {
    static_assert(Idx < N, "Index out of bounds");
    //return std::move(arr)[Idx];
    return std::move(arr[Idx]);
}

}  // namespace std
#include <tuple>

namespace std {

template <typename T, size_t N>
struct tuple_size<T[N]> : public integral_constant<size_t, N> {};

// I have to add the following explicit specialization. If I don't,
// tuple_size<T const[N]> would match both the following
// specializations:
//
//  1. <U[N]> with U = T const (i.e. the specialization above);
//  2. <U const> with U = T[N] (alredy in the standard).
//
// Resulting in a compiler error.
template <typename T, size_t N>
struct tuple_size<T const[N]> : public tuple_size<T[N]> {};

template <typename T, size_t N>
struct tuple_size<T volatile[N]> : public tuple_size<T[N]> {};

template <typename T, size_t N>
struct tuple_size<T const volatile[N]> : public tuple_size<T[N]> {};
// --

namespace detail {
template <size_t Idx, typename T>
struct array_tuple_element;

template <size_t Idx, typename T, size_t N>
struct array_tuple_element<Idx, T[N]> {
    static_assert(Idx < N, "Index out of bounds");
    using type = T;
};
}  // namespace detail

template <size_t Idx, typename T, size_t N>
struct tuple_element<Idx, T[N]>
    : public detail::array_tuple_element<Idx, T[N]> {};

// -- I have to specify those for the same reason above.
template <size_t Idx, typename T, size_t N>
struct tuple_element<Idx, T const[N]>
    : public detail::array_tuple_element<Idx, T const [N]> {};

template <size_t Idx, typename T, size_t N>
struct tuple_element<Idx, T volatile[N]>
    : public detail::array_tuple_element<Idx, T volatile [N]> {};

template <size_t Idx, typename T, size_t N>
struct tuple_element<Idx, T const volatile[N]>
    : public detail::array_tuple_element<Idx, T const volatile [N]> {};
// --

// NOTE: GCC-specific
template <typename T, std::size_t N>
struct __is_tuple_like_impl<T[N]> : public true_type {};

}  // namespace std

#include <cstdio>
#include <iostream>

struct Point
{
    explicit Point(float x_, float y_, float z_)
        : x(x_), y(y_), z(z_)
    { }

    float x{0}, y{0}, z{0};
};

void print_as_point(float x, float y, float z) {
    std::printf("(%f,%f,%f)\n", x, y, z);
}

void print(Point const& p)
{
    print_as_point(p.x, p.y, p.z);
}

template <typename ... Args>
void print(Args&& ... args)
{
    std::size_t n {0};
    constexpr static auto const arg_count = sizeof...(Args);

    std::cout << "tuple: [";
    ((std::cout << '\'' << args << "'" << (++n != arg_count ? ',' : '\0')), ...);
    std::cout << "]\n";
}

int main() {
    float const pointArray[] = {0, 1, 2};
    std::apply(print_as_point, pointArray);

    auto const point = std::make_from_tuple<Point>(pointArray);
    print(point);

    auto const tuple = std::tuple_cat(std::make_tuple(1,1.0), std::array<float,2>{0,0}, "bye");
    static_assert(std::is_same_v<std::tuple_element_t<0, decltype(tuple)>, const int>, "");
    static_assert(std::is_same_v<std::tuple_element_t<1, decltype(tuple)>, const double>, "");
    static_assert(std::is_same_v<std::tuple_element_t<2, decltype(tuple)>, const float>, "");
    static_assert(std::is_same_v<std::tuple_element_t<3, decltype(tuple)>, const float>, "");
    static_assert(std::is_same_v<std::tuple_element_t<4, decltype(tuple)>, const char>, "");
    static_assert(std::is_same_v<std::tuple_element_t<5, decltype(tuple)>, const char>, "");
    static_assert(std::is_same_v<std::tuple_element_t<6, decltype(tuple)>, const char>, "");
    static_assert(std::is_same_v<std::tuple_element_t<7, decltype(tuple)>, const char>, "");
    std::apply([](auto ... args) { print(args...); }, tuple);
}
```

# Technical Specifications

The committee needs technical specifications to be able to fully evaluate your
proposal. Eventually these technical specifications will have to be in the form
of full text for the standard or technical report, often known as
“Standardese”, but for an initial proposal there are several possibilities:

Provide some limited technical documentation. This might be OK for a very
simple proposal such as a single function, but for anything beyond that the
committee will likely ask for more detail.

Provide technical documentation that is complete enough to fully evaluate your
proposal. This documentation can be in the proposal itself or you can provide a
link to documentation available on the web. If the committee likes your
proposal, they will ask for a revised proposal with formal standardese wording.
The committee recognizes that writing the formal ISO specification for a
library component can be daunting and will make additional information and help
available to get you started.

Provide full “Standardese.” A standard is a contract between implementers and
users, to make it possible for users to write portable code with specified
semantics. It says what implementers are permitted to do, what they are
required to do, and what users can and can’t count on. The “standardese” should
match the general style of exposition of the standard, and the specific rules
set out in the Specification Style Guidelines, but it does not have to match
the exact margins or fonts or section numbering; those things will all be
changed anyway if the proposal gets accepted into the working draft for the
next C++ standard.

# Acknowledgements

# References

http://open-std.org/JTC1/SC22/WG21/docs/papers/2020/p2116r0.html

https://cplusplus.github.io/LWG/issue3212
