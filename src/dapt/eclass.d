module dapt.eclass;

import dapt.emitter;
import dapt.type;
import dapt.func;

class EClass : IEmittable {
    string name;
    string body_;

    this (in string name, in string body_) {
        this.name = name;
        this.body_ = body_;
    }

    string emit() {
        auto emitter = new Emitter();
        emitter.emitln("class $L {", name)
            .openScope()
            .emitln(body_)
            .closeScope()
            .emitln("}");

        return emitter.build();
    }

    static class Builder {
        string name;
        Emitter emitter;

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

        EClass build() {
            return new EClass(name, emitter.build());
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
        .addFunction(sumFunc)
        .addFunction(mulFunc)
        .build();

    writeln("Class:");
    writeln(class_.emit());
}
