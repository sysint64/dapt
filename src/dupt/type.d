module dupt.type;

import dupt.emitter;

class Type : IEmittable {
    enum Which {
        primitive_,
        enum_,
        struct_,
        union_,
        class_,
        array_,
        pointer_,
    }

    bool primitive;
    string name;
    Which which;

    this(in bool primitive, in string name, in Which which) {
        this.primitive = primitive;
        this.name = name;
        this.which = which;
    }

    string emit() {
        return this.name;
    }

    static Type createPrimitiveType(in string name) {
        return new Type(true, name, Which.primitive_);
    }

    static Type createType(in string name, in Which which) {
        return new Type(false, name, which);
    }
}

// class TypeArray : Type {
// }

// class TypePointer : Type {
// }

// class TypeFunction : Type {
// }
