import std.stdio;

enum Tag;

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

void main() {
    mixin("@TagGreet");
}
