import std.stdio;
import std.getopt;
import std.file;
import std.path;

import core.sys.posix.stdlib : exit;

import dapt.processor;
import dapt.type;

enum VERSION = "0.1 Alpha";

void getoptFormatter(Output)(Output output, string text, Option[] opt) {
    import std.algorithm.comparison : min, max;
    import std.format : formattedWrite;

    output.formattedWrite("%s\n", text);

    size_t ls, ll;
    bool hasRequired = false;

    foreach (it; opt) {
        ls = max(ls, it.optShort.length);
        ll = max(ll, it.optLong.length);

        hasRequired = hasRequired || it.required;
    }

    string re = " Required: ";

    foreach (it; opt) {
        output.formattedWrite(
            "  %*s %*s%*s%s\n", ls, it.optShort, ll, it.optLong,
            hasRequired ? re.length : 1, it.required ? re : " ", it.help
        );
    }
}

void showError(in string message) {
    writeln("Error: ", message);
    writeln("See 'dapt --help'.");
    exit(int(-1));
}

void showError(in Exception e) {
    showError(e.msg);
}

void main(string[] args) {
    try {
        string source;
        string processors;

        auto helpInformation = getopt(
            args,
            std.getopt.config.required,
            "source|s", "Source directory with files", &source,
            std.getopt.config.required,
            "processors|p", "Source directory with processors", &processors
        );

        writeln(source);
        writeln(processors);

        if (helpInformation.helpWanted) {
            const description =
                "DAPT - Dlang attribute processor\n" ~
                "Usage: dapt [--version] [--help] -f <file> [<args>]\n" ~
                "Options:";

            getoptFormatter(
                stdout.lockingTextWriter(),
                description,
                helpInformation.options
            );
        } else {
            auto processor = new Processor();

            foreach (string name; dirEntries(source, SpanMode.depth)) {
                if (extension(name) == ".d") {
                    writeln(name);
                    processor.addFileToProcessing(name);
                }
            }

            processor.collectTypes();

            foreach (Type type; processor.types) {
                writeln("{");
                writeln("  ", type.generateImport());
                writeln("  ", "emit ", type.emit());
                writeln("}");
            }
        }
    } catch (GetOptException e) {
        showError(e);
    }
}
