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
import dapt.ast;

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
    string moduleName;
    string fileName;

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
    string moduleName = "";
    string fileName = "";

    this(Lexer lexer) {
        this.lexer = lexer;

        if (cast(FileStream) lexer.stream) {
            fileName = (cast(FileStream) lexer.stream).fileName;
        }
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
            case Token.Code.module_:
                parseTransformModule();
                break;

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

            case Token.Code.macroTypeModuleFile:
                addTextASTToCurrentScope();
                parseMacroTypeModuleFile();
                break;

            case Token.Code.macroTypeModuleName:
                addTextASTToCurrentScope();
                parseTypeModuleName();
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

    void parseTransformModule() {
        text ~= lexer.currentToken.identifier;
        lexer.nextToken();

        while (lexer.currentToken.symbol != ';') {
            if (lexer.currentToken.symbol != ' ')
                moduleName ~= lexer.currentToken.identifier;

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

    void parseTypeModuleName() {
        lexer.nextToken();

        if (!cast(ASTTypeHolder) currentASTScope)
            throw new ParseError(pos, line, "typeModuleName macro can be only inside foreach macro");

        currentASTScope.nodes.insert(new ASTTypeModuleNameMacro(cast(ASTTypeHolder) currentASTScope));
    }

    void parseMacroTypeModuleFile() {
        lexer.nextToken();

        if (!cast(ASTTypeHolder) currentASTScope)
            throw new ParseError(pos, line, "typeModuleFile macro can be only inside foreach macro");

        currentASTScope.nodes.insert(new ASTTypeModuleFileMacro(cast(ASTTypeHolder) currentASTScope));
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

        while (lexer.currentToken.symbol != ';') {
            moduleName ~= lexer.currentToken.identifier;
            lexer.nextToken();
        }

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

        while (lexer.currentToken.symbol != '}') {
            handleCollectTypesTokens();
        }

        // lexer.nextToken();
    }

    void openScope(in string scopeName) {
        if (currentScope !is null) {
            auto newScope = new Scope(scopeName);
            newScope.parent = currentScope;
            newScope.moduleName = currentScope.moduleName;
            currentScope = newScope;
        } else {
            currentScope = new Scope(scopeName);
            currentScope.moduleName = moduleName;
        }

        currentScope.fileName = fileName;
    }

    void closeScope() {
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
