module dupt.emmiter;

import std.stdio;
import std.conv;
import std.container.array;

interface IEmittable {
    string emit();
}

class ParseErrorException: Exception {
    this(in string message) {
        super(message);
    }
}

class Emitter {
    string result;

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

    args_foreach:
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
                            continue args_foreach;
                        }
                    } else static if (is(typeof(arg) == Array!IEmittable, IEmittable)) {
                        void emitArray(in char delimiter) {
                            foreach (emittable; arg) {
                                result ~= emittable.emit() ~ delimiter ~ ' ';
                            }

                            result = result[0..$-2];
                        }

                        if (next == 'A') {
                            next = getNext();

                            if (next != '<') {
                                emitArray(',');
                                continue args_foreach;
                            }

                            const delimiter = getNext();
                            next = getNext();

                            if (next != '>') {
                                throw new ParseErrorException("excepted '>'");
                            }

                            emitArray(delimiter);
                            continue args_foreach;
                        }
                    } else {
                        if (next == 'L') {
                            result ~= to!string(arg);
                            getNext();
                            continue args_foreach;
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

        return this;
    }

    Emitter emitln(T...)(in string format, T) {
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
    emitter.emit("Emmitable is: $E, Number is: $L", a, 1);
    assertEquals("Emmitable is: Hello!, Number is: 1", emitter.build());

    emitter.clear();
    emitter.emit("Escaped emmitable is: $$E", 1, a);
    assertEquals("Escaped emmitable is: $E", emitter.build());

    emitter.clear();
    emitter.emit("Escaped emmitable is: $$L", 1, 1);
    assertEquals("Escaped emmitable is: $L", emitter.build());

    emitter.clear();
    emitter.emit("Escaped emmitable is: $$L $L", "Hello world!");
    assertEquals("Escaped emmitable is: $L Hello world!", emitter.build());

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
    assertEquals("Array: 1, 2, 3", emitter.build());

    emitter.clear();
    emitter.emit("Array: $A<;>", list);
    assertEquals("Array: 1; 2; 3", emitter.build());
}
