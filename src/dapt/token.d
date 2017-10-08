module dapt.token;

import std.ascii;
import std.uni : toLower;
import std.algorithm.iteration : map;
import std.conv;

import dapt.stream;
import dapt.lexer : LexerError;

class Token {
    enum Code {
        none, symbol, id, number, string, boolean,
        module_, struct_, class_, enum_,
        macroForeachTypes, macroImportType, macroType
    };

    this(IStream stream) {
        this.p_stream = stream;
        this.p_line = stream.line;
        this.p_pos = stream.pos;
    }

    @property string identifier() { return p_identifier; }
    @property float number() { return p_number; }
    @property bool boolean() { return p_boolean; }
    @property string str() { return p_string; }
    @property dstring utfStr() { return p_utfstring; }
    @property Code code() { return p_code; }
    @property char symbol() { return p_symbol; }
    @property int line() { return p_line; }
    @property int pos() { return p_pos; }
    @property IStream stream() { return p_stream; }

private:
    IStream p_stream;
    char p_symbol;
    Code p_code;
    int p_line;
    int p_pos;

protected:
    string p_identifier;
    float p_number;
    bool p_boolean;
    string p_string;
    dstring p_utfstring;
}


class SymbolToken : Token {
    this(IStream stream, in char symbol) {
        super(stream);
        this.p_symbol = symbol;
        this.p_identifier = to!string(symbol);
        this.p_code = Code.symbol;
    }
}


class StringToken : Token {
    this(IStream stream) {
        super(stream);
        this.lex();
    }

private:
    void lex() {
        do {
            stream.read();

            if (stream.lastChar != '\"')
                p_string ~= stream.lastChar;
        } while (stream.lastChar != '\"' && !stream.eof);

        if (stream.eof) {
            throw new LexerError(stream.line, stream.pos, "unexpected end of file");
        } else {
            stream.read();
        }

        p_code = Code.string;
        p_utfstring = to!dstring(p_string);
        p_identifier = '"' ~ p_string ~ '"';
    }
}


// Identifier: [a-zA-Z_][a-zA-Z0-9_]*
class IdToken : Token {
    this(IStream stream) {
        super(stream);
        p_code = Code.id;
        lex();
    }

private:
    bool isIdChar() {
        return isAlphaNum(stream.lastChar) || stream.lastChar == '_';
    }

    void lex() {
        while (isIdChar()) {
            p_identifier ~= stream.lastChar;
            stream.read();
        }

        // import std.stdio;
        // writeln("Identifier: ", p_identifier);

        switch (p_identifier) {
            case "module":
                p_code = Code.module_;
                return;

            case "struct":
                p_code = Code.struct_;
                return;

            case "class":
                p_code = Code.class_;
                return;

            // case "enum":
            //     p_code = Code.enum_;
            //     return;

            // case "true":
            //     p_code = Code.boolean;
            //     p_boolean = true;
            //     return;

            // case "false":
            //     p_code = Code.boolean;
            //     p_boolean = false;
            //     return;

            default:
                p_code = Code.id;
        }
    }
}


class MacroToken : Token {
    this(IStream stream) {
        super(stream);
        p_code = Code.id;
        stream.read();
        lex();
    }

private:
    bool isIdChar() {
        return isAlphaNum(stream.lastChar) || stream.lastChar == '_';
    }

    void lex() {
        while (isIdChar()) {
            p_identifier ~= stream.lastChar;
            stream.read();
        }

        import std.stdio;
        writeln("Macro: ", p_identifier);

        switch (p_identifier) {
            case "foreachTypes":
                p_code = Code.macroForeachTypes;
                return;

            case "importType":
                p_code = Code.macroImportType;
                return;

            case "type":
                p_code = Code.macroType;
                return;

            default:
                p_code = Code.id;
                p_identifier = "#" ~ p_identifier;
        }
    }
}
