module dapt.emitter;

import std.stdio;
import std.string;
import std.conv;
import std.container.array;

interface IEmittable {
    string emit();
}

class StringEmittable : IEmittable {
    const string output;

    this(in string output) {
        this.output = output;
    }

    string emit() {
        return output;
    }
}

class ParseErrorException: Exception {
    this(in string message) {
        super(message);
    }
}

class Emitter {
    string result;
    private int indent = 0;
    enum spaces = 4;
    bool autoIndent = true;

    void emitArray(T)(in char delimiter, T arg) {
        foreach (emittable; arg) {
            if (delimiter == ' ') {
                result ~= emittable.emit() ~ delimiter;
            } else {
                result ~= emittable.emit() ~ delimiter ~ ' ';
            }
        }

        if (arg.length != 0)
            result = result[0..$-2];
    }

    void openScope() {
        indent += spaces;
    }

    void closeScope() {
        indent -= spaces;
    }

    void emitIndent() {
        if (!autoIndent)
            return;

        for (int i; i < indent; ++i) {
            result ~= " ";
        }
    }

    Emitter emit(E...)(in string format, E args) {
        size_t index = 0;
        string input = format;
        bool escaped = false;

        char getNext() {
            if (input.length > 0) {
                input = input[1..$];
                return input.length > 0 ? input[0] : '\0';
            } else {
                return '\0';
            }
        }

    LArgsForeach:
        foreach (arg; args) {
            while (input.length > 0) {
                char next = input[0];

                if (!escaped && next == '$' && input.length > 1) {
                    next = getNext();

                    if (next == '$') {
                        escaped = true;
                        input = input[1..$];
                        result ~= '$';
                        continue;
                    }

                    static if (is(typeof(arg) : IEmittable)) {
                        if (next == 'E') {
                            result ~= arg.emit();
                            getNext();
                            continue LArgsForeach;
                        }
                    } else static if (is(typeof(arg) == Array!IEmittable, IEmittable)) {
                        if (next == 'A') {
                            next = getNext();

                            if (next != '<') {
                                if (arg.length != 0) {
                                    emitArray(',', arg);
                                } else { // rm trailing spaces
                                    while (next == ' ')
                                        next = getNext();
                                }
                                continue LArgsForeach;
                            }

                            const delimiter = getNext();
                            next = getNext();

                            if (next != '>') {
                                throw new ParseErrorException("excepted '>'");
                            }

                            if (arg.length != 0) {
                                emitArray(delimiter, arg);
                                next = getNext();
                            } else { // rm trailing spaces
                                next = getNext();

                                while (next == ' ') {
                                    next = getNext();
                                }
                            }

                            continue LArgsForeach;
                        }
                    } else {
                        if (next == 'L') {
                            result ~= to!string(arg);
                            getNext();
                            continue LArgsForeach;
                        }

                        result ~= "$" ~ next;
                        continue;
                    }
                }

                escaped = false;
                result ~= next;
                getNext();
            }
        }

        result ~= input;
        return this;
    }

    Emitter emitln(T...)(in string format, T args) {
        emitIndent();
        emit(format ~ "\n", args);
        return this;
    }

    Emitter emitBlock(in string block) {
        foreach (line; splitLines(block)) {
            emitln(line);
        }

        return this;
    }

    Emitter clear() {
        result = "";
        return this;
    }

    string build() {
        return result;
    }
}

unittest {
    import dunit.assertion;

    class A : IEmittable {
        string emit() {
            return "Hello!";
        }
    }

    auto a = new A();
    auto emitter = new Emitter();
    emitter.autoIndent = false;
    emitter.emit("$E", a);
    assertEquals(a.emit(), emitter.build());

    emitter.clear();
    emitter.emit("$", a);
    assertEquals("$", emitter.build());

    emitter.clear();
    emitter.emit("Hello world!", 1);
    assertEquals("Hello world!", emitter.build());

    emitter.clear();
    emitter.emit("Number is: $L", 1);
    assertEquals("Number is: 1", emitter.build());

    emitter.clear();
    emitter.emit("Emittable is: $E, Number is: $L", a, 1);
    assertEquals("Emittable is: Hello!, Number is: 1", emitter.build());

    emitter.clear();
    emitter.emit("Escaped emittable is: $$E", 1, a);
    assertEquals("Escaped emittable is: $E", emitter.build());

    emitter.clear();
    emitter.emit("Escaped emittable is: $$L", 1, 1);
    assertEquals("Escaped emittable is: $L", emitter.build());

    emitter.clear();
    emitter.emit("Escaped emittable is: $$L $L", "Hello world!");
    assertEquals("Escaped emittable is: $L Hello world!", emitter.build());

    class B : IEmittable {
        string res;

        this(in string res) {
            this.res = res;
        }

        string emit() {
            return this.res;
        }
    }

    Array!B list;
    list.insert(new B("1"));
    list.insert(new B("2"));
    list.insert(new B("3"));

    emitter.clear();
    emitter.emit("Array: $A 1", list);
    assertEquals("Array: 1, 2, 3 1", emitter.build());

    emitter.clear();
    emitter.emit("Array: $A<;>", list);
    assertEquals("Array: 1; 2; 3", emitter.build());
}
