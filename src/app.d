import std.stdio;
import std.getopt;
import core.sys.posix.stdlib : exit;

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
    writeln("See 'dupt --help'.");
    exit(-1);
}

void showError(in Exception e) {
    showError(e.msg);
}

void main(string[] args) {
    try {
        string[] files;
        string[] processors;

        auto helpInformation = getopt(
            args,
            std.getopt.config.required,
            "file|f", "Files to prcess", &files,
            std.getopt.config.required,
            "processors|p", "Processors", &processors
        );

        writeln(files);
        writeln(processors);

        if (helpInformation.helpWanted) {
            const description =
                "DUPT - Dlang UDA processor\n" ~
                "Usage: dupt [--version] [--help] -f <file> [<args>]\n" ~
                "Options:";

            getoptFormatter(
                stdout.lockingTextWriter(),
                description,
                helpInformation.options
            );
        }
    } catch (GetOptException e) {
        showError(e);
    }
}
