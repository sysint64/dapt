import std.stdio;
import std.getopt;
import std.file;
import std.path;
import std.container.array;

import core.sys.posix.stdlib : exit;

import dapt.processor;
import dapt.type;
import dapt.func;
import dapt.emitter;


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
    exit(-1);
}

void showError(in Exception e) {
    showError(e.msg);
}

File generatedFilesTxt;

void generateProcessorsEntry(Processor processor, in string sourcePath,
    ref Array!ProcessorInfo processorsInfo)
{
    auto block = new BlockEmittable();
    block.add(new StringEmittable("module processors.entry;\n\n"));
    block.add(new StringEmittable("import dapt.processor;\n\n"));

    auto funcBuilder = new Function.Builder()
        .setName("daptProcess")
        .setReturnType(Type.createPrimitiveType("void"))
        .openScope("version (daptProcessingVersion)");

    foreach (ProcessorInfo info; processorsInfo) {
        funcBuilder
            .openScope()
            .addStatement("import $L : process;", info.moduleName)
            .addStatement("auto processor = new Processor();")
            .addStatement("processor.projectPath = \"$L\";", processor.projectPath)
            .addStatement("processor.process(&process);")
            .addStatement("processor.generateGeneratedFilesTxt($L);", false)
            .closeScope();
    }

    funcBuilder.closeScope();
    block.add(funcBuilder.build());

    const entryPath = buildPath(sourcePath, "processors", "entry.d");
    auto outFile = File(entryPath, "w");
    outFile.write(block.emit());
    outFile.close();

    generatedFilesTxt.writeln(entryPath);
    outFile.close();
}

void main(string[] args) {
    try {
        string source;
        string processors;
        string projectRootDirectory = "";

        auto helpInformation = getopt(
            args,
            std.getopt.config.required,
            "source|s", "Source directory with files", &source,
            std.getopt.config.required,
            "processors|p", "Source directory with processors", &processors,
            "project_root|r", "Project root rirectory", &projectRootDirectory
        );

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

            if (projectRootDirectory != "") {
                processor.projectPath = projectRootDirectory;
            }

            const generatedFilesPath = buildPath(processor.projectPath, "dapt_generated_files.txt");
            generatedFilesTxt = File(generatedFilesPath, "w");

            foreach (string name; dirEntries(source, SpanMode.depth)) {
                if (extension(name) == ".d") {
                    processor.addFileToProcessing(name);
                }
            }

            processor.collectTypes();
            Array!ProcessorInfo processorsInfo;

            foreach (string name; dirEntries(source, SpanMode.depth)) {
                if (extension(name) == ".gen") {
                    auto info = processor.generateProcessor(name);
                    processorsInfo.insert(info);
                    generatedFilesTxt.writeln(info.fileName);
                }
            }

            generateProcessorsEntry(processor, source, processorsInfo);
        }
    } catch (GetOptException e) {
        showError(e);
    } finally {
        if (generatedFilesTxt.isOpen)
            generatedFilesTxt.close();
    }
}
