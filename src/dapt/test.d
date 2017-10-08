module dapt.test;

import dapt.stream;
import dapt.lexer;
import dapt.parser;

struct TestData {
    IStream stream;
    Lexer lexer;
    Parser parser;

    struct Nested {
    }

    this(in string input) {
        stream = new StringStream(input);
        lexer = new Lexer(stream);
        parser = new Parser(lexer);
    }
}
