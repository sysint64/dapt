module dupt.parser;

import std.format : formattedWrite;
import std.array : appender;
import std.container.array;

import dupt.stream;
import dupt.lexer;
import dupt.token;
import dupt.ast;

class ParseError : Exception {
    this(in uint line, in uint pos, in string details) {
        auto writer = appender!string();
        formattedWrite(writer, "line %d, pos %d: %s", line, pos, details);
        super(writer.data);
    }
}

class Parser {
    private Lexer lexer;

    this(Lexer lexer) {
        this.lexer = lexer;
    }

    Array!ModuleASTNode parse() {
        Array!ModuleASTNode nodes;
        lexer.nextToken();

        switch (lexer.currentToken.code) {
            case Token.Code.module_:
                nodes.insert(parseModule());
                break;

            default:
                throw new ParseError(line, pos, "unknown identifier");
        }

        return nodes;
    }

    @property int line() { return lexer.currentToken.line; }
    @property int pos() { return lexer.currentToken.pos; }

private:
    ModuleASTNode parseModule() {
        lexer.nextToken();
        string moduleName = "";

        while (lexer.currentToken.symbol != ';') {
            moduleName ~= lexer.currentToken.identifier;
            lexer.nextToken();
        }

        return new ModuleASTNode(moduleName);
    }
}

struct TestData {
    IStream stream;
    Lexer lexer;
    Parser parser;

    this(in string input) {
        stream = new StringStream(input);
        lexer = new Lexer(stream);
        parser = new Parser(lexer);
    }
}

unittest {
    import dunit.assertion;
    TestData testData("module tests.simple;");

    with (testData) {
        lexer.nextToken();
        assertEquals(lexer.currentToken.code, Token.Code.module_);

        ModuleASTNode module_ =  parser.parseModule();
        assertEquals("tests.simple", module_.name);
    }
}
