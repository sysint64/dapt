module dupt.stream;

import std.stdio;
import std.file;
import core.stdc.stdio;

interface IStream {
    char read();

    @property char lastChar();
    @property int line();
    @property int pos();
    @property bool eof();
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

        if (file.eof) p_lastChar = char.init;
        else p_lastChar = buf[0];

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
