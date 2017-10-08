module dapt.parser;

import std.stdio;
import std.format : formattedWrite;
import std.array : appender;
import std.container.array;

import dapt.stream;
import dapt.lexer;
import dapt.token;
import dapt.type;

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

class Parser {
    Lexer lexer;
    Scope currentScope = null;

    this(Lexer lexer) {
        this.lexer = lexer;
    }

    void parse() {
        try {
            lexer.nextToken();

            while (lexer.currentToken.code != Token.Code.none) {
                handleTokens();
            }
        } catch (EndOfStreamException e) {
            writeln("End of stream");
            closeScope();
        }
    }

    @property int line() { return lexer.currentToken.line; }
    @property int pos() { return lexer.currentToken.pos; }

private:
    public Array!Type types;

    void handleTokens() {
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
            handleTokens();
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
            handleTokens();
        }

        closeScope();
    }

    void skipScope() {
        lexer.nextToken();
        writeln("Skiping scope");

        while (lexer.currentToken.symbol != '}') {
            handleTokens();
        }

        lexer.nextToken();
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

        parser.parse();

        foreach (Type type; parser.types) {
            writeln("{");
            writeln("  ", type.generateImport());
            writeln("  ", "emit ", type.emit());
            writeln("}");
        }
        // parser.parseModule();
        // assertEquals("tests.simple", parser.currentScope.name);
    }
}
