module dapt.parser;

import std.stdio;
import std.format : formattedWrite;
import std.array : appender;
import std.container.array;

import dapt.stream;
import dapt.lexer;
import dapt.token;
import dapt.type;
import dapt.emitter;

class ParseError : Exception {
    this(in uint line, in uint pos, in string details) {
        auto writer = appender!string();
        formattedWrite(writer, "line %d, pos %d: %s", line, pos, details);
        super(writer.data);
    }
}

class Scope {
    Scope parent = null;
    string name;

    @property Scope root() {
        Scope parentScope = this;
        Scope rootScope = null;

        while (parentScope !is null) {
            rootScope = parentScope;
            parentScope = parentScope.parent;
        }

        return rootScope;
    }

    this(in string name) {
        this.name = name;
    }

    this(in string name, Scope parent) {
        this.name = name;
        this.parent = parent;
    }

    override string toString() {
        string result = "";
        Scope parentScope = this;

        if (parent is null) {
            return this.name;
        } else {
            return parent.toString() ~ "." ~ this.name;
        }
    }
}

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

class Parser {
    Lexer lexer;
    Scope currentScope = null;

    this(Lexer lexer) {
        this.lexer = lexer;
    }

    this(Lexer lexer, Array!Type types) {
        this.lexer = lexer;
        this.types = types;
    }

    void collectTypes() {
        try {
            lexer.skipWhitspaces = true;
            lexer.lexStrings = true;
            lexer.nextToken();

            while (lexer.currentToken.code != Token.Code.none) {
                handleCollectTypesTokens();
            }
        } catch (EndOfStreamException e) {
            writeln("End of stream");
            // closeScope();
        }
    }

    string macroTransform() {
        try {
            rootASTScope = new ASTScope();
            currentASTScope = rootASTScope;
            currentMacroType = types.front();

            lexer.skipWhitspaces = false;
            lexer.lexStrings = false;
            lexer.nextToken();

            while (lexer.currentToken.code != Token.Code.none) {
                handleMacroTransformTokens();
            }
        } catch (EndOfStreamException e) {
            addTextASTToCurrentScope();
            writeln("End of stream");
        }

        return rootASTScope.emit();
    }

    @property int line() { return lexer.currentToken.line; }
    @property int pos() { return lexer.currentToken.pos; }

private:
    public Array!Type types;

// Macro transform ---------------------------------------------------------------------------------

    private Type currentMacroType;
    private string text = "";
    private ASTScope rootASTScope;
    private ASTScope currentASTScope;

    void addTextASTToCurrentScope() {
        currentASTScope.nodes.insert(new ASTText(text));
        text = "";
    }

    void handleMacroTransformTokens() {
        switch (lexer.currentToken.code) {
            case Token.Code.macroForeachTypes:
                addTextASTToCurrentScope();
                parseForeachMacro();
                break;

            case Token.Code.macroImportType:
                addTextASTToCurrentScope();
                parseMacroImportType();
                break;

            case Token.Code.macroType:
                addTextASTToCurrentScope();
                parseMacroType();
                break;

            case Token.Code.symbol:
                if (lexer.currentToken.symbol == '{') {
                    parseScope();
                } else {
                    goto default;
                }

                break;

            default:
                text ~= lexer.currentToken.identifier;
                lexer.nextToken();
        }
    }

    void parseMacroImportType() {
        lexer.nextToken();

        if (!cast(ASTTypeHolder) currentASTScope) {
            throw new ParseError(pos, line, "import macro can be only inside foreach macro");
        }

        currentASTScope.nodes.insert(new ASTImportTypeMacro(cast(ASTTypeHolder) currentASTScope));
    }

    void parseMacroType() {
        lexer.nextToken();

        if (!cast(ASTTypeHolder) currentASTScope)
            throw new ParseError(pos, line, "type macro can be only inside foreach macro");

        currentASTScope.nodes.insert(new ASTTypeMacro(cast(ASTTypeHolder) currentASTScope));
    }

    void parseForeachMacro() {
        auto foreachScope = new ASTForeachMacro(lexer.indent, types);
        auto lastASTScope = currentASTScope;
        currentASTScope = foreachScope;

        while (lexer.currentToken.symbol != '{') {
            lexer.nextToken();
        }

        lexer.nextToken();
        while (lexer.currentToken.symbol != '}') {
            handleMacroTransformTokens();
        }

        lexer.nextToken();
        addTextASTToCurrentScope();
        currentASTScope = lastASTScope;
        currentASTScope.nodes.insert(foreachScope);
    }

    void parseScope() {
        text ~= lexer.currentToken.identifier;
        lexer.nextToken();

        while (lexer.currentToken.symbol != '}') {
            handleMacroTransformTokens();
        }

        text ~= lexer.currentToken.identifier;
        lexer.nextToken();
    }

// Collect types -----------------------------------------------------------------------------------

    void handleCollectTypesTokens() {
        switch (lexer.currentToken.code) {
            case Token.Code.module_:
                writeln("Parsing module");
                parseModule();
                break;

            case Token.Code.struct_:
                parseStruct();
                break;

            case Token.Code.class_:
                parseClass();
                break;

            case Token.Code.symbol:
                if (lexer.currentToken.symbol == '{') {
                    skipScope();
                } else {
                    lexer.nextToken();
                }

                break;

            default:
                lexer.nextToken();
        }
    }

    void parseModule() {
        lexer.nextToken();
        string moduleName = "";

        while (lexer.currentToken.symbol != ';') {
            moduleName ~= lexer.currentToken.identifier;
            lexer.nextToken();
        }

        writeln(moduleName);
        openScope(moduleName);
    }

    void parseStruct() {
        lexer.nextToken();
        const typeName = lexer.currentToken.identifier;
        openScope(typeName);

        types.insert(Type.createType(typeName, Type.Which.struct_, currentScope));
        bool end = false;

        while (lexer.currentToken.symbol != '{' && lexer.currentToken.symbol != ';') {
            lexer.nextToken();
        }

        lexer.nextToken();

        while (lexer.currentToken.symbol != '}') {
            handleCollectTypesTokens();
        }

        closeScope();
    }

    void parseClass() {
        lexer.nextToken();
        const typeName = lexer.currentToken.identifier;
        openScope(typeName);

        types.insert(Type.createType(typeName, Type.Which.class_, currentScope));
        bool end = false;

        while (lexer.currentToken.symbol != '{' && lexer.currentToken.symbol != ';') {
            lexer.nextToken();
        }

        lexer.nextToken();

        while (lexer.currentToken.symbol != '}') {
            handleCollectTypesTokens();
        }

        closeScope();
    }

    void skipScope() {
        lexer.nextToken();
        writeln("Skiping scope");

        while (lexer.currentToken.symbol != '}') {
            handleCollectTypesTokens();
        }

        // lexer.nextToken();
    }

    void openScope(in string scopeName) {
        if (currentScope !is null) {
            auto newScope = new Scope(scopeName);
            newScope.parent = currentScope;
            currentScope = newScope;
        } else {
            currentScope = new Scope(scopeName);
        }

        writeln("open scope: ", currentScope.toString());
    }

    void closeScope() {
        writeln("close scope: ", currentScope.toString());
        currentScope = currentScope.parent;
    }
}

unittest {
    import dunit.assertion;
    import dapt.test;

    const source = q{
        module tests.simple;

        @Tag
        struct A {
            void greet() {
                writeln("Hello world!");
            }

            struct Nested {
                struct InNester;
            }
        }

        class B {
            void test() {
                writeln("Hello world!");
            }

            void aaa() {
            }
        }

        @nogc @safe struct C {
        }
    };

    auto testData = TestData(source);

    with (testData) {
        // lexer.nextToken();
        // assertEquals(lexer.currentToken.code, Token.Code.module_);

        parser.collectTypes();

        // foreach (Type type; parser.types) {
        //     writeln("{");
        //     writeln("  ", type.generateImport());
        //     writeln("  ", "emit ", type.emit());
        //     writeln("}");
        // }
        // parser.parseModule();
        // assertEquals("tests.simple", parser.currentScope.name);
    }
}
