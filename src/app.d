import std.stdio;
import std.getopt;

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

void main(string[] args) {
    string file;

    try {
        auto helpInformation = getopt(
            args,
            std.getopt.config.required,
            "file|f", "Hello world", &file
        );

        if (helpInformation.helpWanted) {
            const description =
                "DUPT - Dlang UDA processor\n" ~
                "Usage: dupt -f <file> [<args>]\n" ~
                "Options:";

            getoptFormatter(
                stdout.lockingTextWriter(),
                description,
                helpInformation.options
            );
        }
    } catch (GetOptException e) {
        writeln("Error: ", e.msg);
        writeln("type --help for more information");
    }
}
