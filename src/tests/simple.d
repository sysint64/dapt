module tests.simple;

import std.stdio;
import tests.simple_uda;

@Tag
struct A {
    void greet() {
        writeln("Hello world!");
    }
}

@Tag
struct B {
    void greet() {
        writeln("Hello world!");
    }
}
