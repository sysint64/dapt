module dupt.type;

import dupt.emmiter;
import std.container.array;
import std.array;

class Type : IEmittable {
    string emit() {
        return "";
    }
}

class Argument : IEmittable {
    Type type;
    string name;
    Array!string modificators;

    string emit() {
        return "";
    }
}

class Function : IEmittable {
    Type returnType;
    Array!Argument arguments;
    string name;
    string statements;

    this(in string name, Type returnType, Array!Argument arguments) {
        this.returnType = returnType;
        this.arguments = arguments;
        this.name = name;
    }

    string emit() {
        auto emitter = new Emitter();

        with (emitter) {
            emitln("$E $L($A) {", returnType, name, arguments);
            emitln(statements);
            emitln("}");
        }

        return emitter.build();
    }
}

class FunctionBuilder {
    Type returnType;
    Array!Argument arguments;
    string name;

    FunctionBuilder setReturnType(Type returnType) {
        this.returnType = returnType;
        return this;
    }

    FunctionBuilder addArgument(Argument argument) {
        this.arguments.insert(argument);
        return this;
    }

    FunctionBuilder setName(string name) {
        this.name = name;
        return this;
    }

    Function build() {
        return new Function(name, returnType, arguments);
    }
}
