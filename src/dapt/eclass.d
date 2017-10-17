module dapt.eclass;

import std.container.array;

import dapt.emitter;
import dapt.type;
import dapt.func;

class EClass : IEmittable {
    string name;
    string body_;
    Array!Argument arguments;

    this (in string name, in string body_, Array!Argument arguments) {
        this.name = name;
        this.body_ = body_;
        this.arguments = arguments;
    }

    string emit() {
        auto emitter = new Emitter();
        emitter.emitln("class $L {", name)
            .openScope()
            .emitln("$A<;\n>", arguments)
            .emitln(body_)
            .closeScope()
            .emitln("}");

        return emitter.build();
    }

    static class Builder {
        string name;
        Emitter emitter;
        Array!Argument arguments;

        this() {
            emitter = new Emitter();
            emitter.openScope();
        }

        Builder setName(string name) {
            this.name = name;
            return this;
        }

        Builder addFunction(Function func) {
            emitter.emitln(func);
            return this;
        }

        Builder addArgument(Argument argument) {
            this.arguments.insert(argument);
            return this;
        }


        EClass build() {
            return new EClass(name, emitter.build(), arguments);
        }
    }
}


unittest {
    import dunit.assertion;
    import std.stdio;

    auto sumFunc = new Function.Builder()
        .setName("sum")
        .addAttribute(new Attribute("const"))
        .setReturnType(Type.createPrimitiveType("int"))
        .addStatement("return a + b;")
        .addArgument(Argument.create("a", "int", "in"))
        .addArgument(Argument.create("b", "int", "in"))
        .build();

    auto mulFunc = new Function.Builder()
        .setName("mul")
        .addAttribute(new Attribute("const"))
        .setReturnType(Type.createPrimitiveType("int"))
        .addStatement("return a * b;")
        .addArgument(Argument.create("a", "int", "in"))
        .addArgument(Argument.create("b", "int", "in"))
        .build();

    auto class_ = new EClass.Builder()
        .setName("MyModel")
        .addArgument(Argument.create("a", "int"))
        .addArgument(Argument.create("b", "int"))
        .addFunction(sumFunc)
        .addFunction(mulFunc)
        .build();

    writeln("Class:");
    writeln(class_.emit());
}
