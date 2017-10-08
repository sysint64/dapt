module dapt.type;

import dapt.emitter;
import dapt.parser : Scope;

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
    Scope scope_ = null;

    this(in bool primitive, in string name, in Which which, Scope scope_ = null) {
        this.primitive = primitive;
        this.name = name;
        this.which = which;
        this.scope_ = scope_;
    }

    string emit() {
        switch (which) {
            case Which.struct_: case Which.class_:
                if (scope_ is null)
                    return this.name;

                return scope_.toString()[scope_.root.name.length + 1 .. $];

            // case Which.struct_:
            //     return "struct " ~ this.name;

            // case Which.class_:
            //     return "class " ~ this.name;

            default:
                return this.name;
        }
    }

    string generateImport() {
        if (scope_ is null)
            return "";

        switch (which) {
            case Which.struct_: case Which.class_:
                if (scope_.root != scope_.parent) {
                    auto baseScope = scope_;
                    string baseName;

                    while (baseScope != scope_.root) {
                        baseName = baseScope.name;
                        baseScope = baseScope.parent;
                    }

                    return "import " ~ scope_.root.name ~ " : " ~ baseName;
                }

                return "import " ~ scope_.root.name ~ " : " ~ name;

            default:
                return "";
        }
    }

    static Type createPrimitiveType(in string name) {
        return new Type(true, name, Which.primitive_);
    }

    static Type createType(in string name, in Which which, Scope scope_ = null) {
        return new Type(false, name, which, scope_);
    }
}

// class TypeArray : Type {
// }

// class TypePointer : Type {
// }

// class TypeFunction : Type {
// }
