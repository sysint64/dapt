module dapt.ast;

import std.container.array;

import dapt.type;
import dapt.emitter;

abstract class ASTNode : IEmittable {}

class ASTScope : ASTNode {
    ASTScope parent = null;
    Array!ASTNode nodes;

    string emit() {
        string result = "";

        foreach (node; nodes) {
            result ~= node.emit();
        }

        return result;
    }
}

class ASTText : ASTNode {
    private string text;

    this(in string text) {
        this.text = text;
    }

    string emit() {
        return text;
    }
}

interface ASTTypeHolder {
    Type getType();
}

class ASTForeachMacro : ASTScope, ASTTypeHolder {
    private Array!Type types;
    private Type currentType = null;
    private int indent = 0;

    Type getType() {
        return currentType;
    }

    this (in int indent, Array!Type types) {
        this.types = types;
        this.indent = indent;

        if (types.length > 0)
            this.currentType = types.front();
    }

    override string emit() {
        string result;

        void emitIndent() {
            for (int i = 0; i < indent; ++i)
                result ~= " ";
        }

        foreach (type; types) {
            currentType = type;

            result ~= "\n";
            emitIndent();
            result ~= "{\n";

            foreach (node; nodes) {
                result ~= node.emit();
            }

            result ~= "\n";
            emitIndent();
            result ~= "}\n";
        }

        return result;
    }
}

class ASTImportTypeMacro : ASTNode {
    ASTTypeHolder typeHolder;

    this(ASTTypeHolder typeHolder) {
        this.typeHolder = typeHolder;
    }

    string emit() {
        assert(typeHolder !is null);
        return typeHolder.getType().generateImport();
    }
}

class ASTTypeMacro : ASTNode {
    ASTTypeHolder typeHolder;

    this(ASTTypeHolder typeHolder) {
        this.typeHolder = typeHolder;
    }

    string emit() {
        return typeHolder.getType().emit();
    }
}

class ASTTypeModuleNameMacro : ASTNode {
    ASTTypeHolder typeHolder;

    this(ASTTypeHolder typeHolder) {
        this.typeHolder = typeHolder;
    }

    string emit() {
        return typeHolder.getType().moduleName;
    }
}

class ASTTypeModuleFileMacro : ASTNode {
    ASTTypeHolder typeHolder;

    this(ASTTypeHolder typeHolder) {
        this.typeHolder = typeHolder;
    }

    string emit() {
        return typeHolder.getType().moduleFileName;
    }
}
