module dapt.stream;

import std.stdio;
import std.file;
import core.stdc.stdio;

class EndOfStreamException : Exception {
    this() {
        super("end of strem");
    }
}

interface IStream {
    char read();

    @property char lastChar();
    @property int line();
    @property int pos();
    @property bool eof();
}

class StringStream : IStream {
    this(in string input) {
        this.input = input;
    }

    char read() {
        p_lastChar = input[index++];

        if (eof)
            throw new EndOfStreamException();

        return p_lastChar;
    }

    @property int line() { return 1; }
    @property int pos() { return cast(int) index; }
    @property bool eof() { return index >= input.length; }
    @property char lastChar() { return p_lastChar; }

private:
    string input;
    size_t index = 0;
    char p_lastChar;
}

class FileStream : IStream {
    this(in string fileName) {
        assert(fileName.isFile);
        this.file = File(fileName);
    }

    ~this() {
        file.close();
    }

    char read() {
        auto buf = file.rawRead(new char[1]);
        ++p_pos;

        if (file.eof) {
            p_lastChar = char.init;
            throw new EndOfStreamException();
        } else {
            p_lastChar = buf[0];
        }

        return p_lastChar;
    }

    @property int line() { return p_line; }
    @property int pos() { return p_pos; }
    @property bool eof() { return file.eof; }
    @property char lastChar() { return p_lastChar; }

private:
    File file;

    int  p_line, p_pos;
    char p_lastChar;
}

class CTFileStream : IStream {
    this(in string content) {
        this.content = content;
    }

    static CTFileStream createFromFile(string fileName)() {
        auto stream = new CTFileStream(import(fileName));
    }

    char read() {
        p_lastChar = content[index++];

        if (eof)
            throw new EndOfStreamException();

        return p_lastChar;
    }

    @property int line() const { return 1; }
    @property int pos() const { return cast(int) index; }
    @property bool eof() const { return index >= content.length; }
    @property char lastChar() const { return p_lastChar; }

private:
    const string content;
    size_t index = 0;
    char p_lastChar;
}
