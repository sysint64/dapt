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
        if (eof)
            throw new EndOfStreamException();

        p_lastChar = input[index++];
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
    const string fileName;

    this(in string fileName) {
        assert(fileName.isFile);
        this.file = File(fileName);
        this.fileName = fileName;
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
