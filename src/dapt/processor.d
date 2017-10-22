module dapt.processor;

import std.container.array;
import std.path;
import std.file;
import std.stdio;

import dapt.emitter;
import dapt.stream;
import dapt.lexer;
import dapt.parser;
import dapt.type;

struct ProcessorInfo {
    string moduleName;
    string fileName;
}

enum FileOpenMode {write, append};

class Processor {
    string projectPath;

    private Array!string p_generatedFiles;
    @property Array!string generatedFiles() { return p_generatedFiles; }

    this() {
        projectPath = dirName(thisExePath());
    }

    void clear() {
        emittables.clear();
    }

    void addFileToProcess(in string fileName) {
        filesToProcessing.insert(fileName);
    }

    void add(IEmittable emittable) {
        emittables.insert(emittable);
    }

    void addln() {
        emittables.insert(new StringEmittable("\n"));
    }

    void addFileToProcessing(in string fileName) {
        filesToProcessing.insert(fileName);
    }

    private File generatedFile;

    FileOpenMode openFile(in string fileName) {
        const fullPath = buildPath(projectPath, "src", fileName);

        if (exists(fullPath)) {
            generatedFile = File(fullPath, "a");
            return FileOpenMode.append;
        } else {
            p_generatedFiles.insert(fullPath);
            generatedFile = File(fullPath, "w");
            return FileOpenMode.write;
        }
    }

    void closeFile() {
        generatedFile.write(emit());
        generatedFile.close();
        clear();
    }

    void process(void function(Processor processor) processorHandler) {
        processorHandler(this);
    }

    void collectTypes() {
        foreach (string fileName; filesToProcessing) {
            parse(fileName);
        }
    }

    ProcessorInfo generateProcessor(in string fileName) {
        const fullPath = buildPath(projectPath, "src", fileName);
        const outPath = buildPath(projectPath, "src", fileName[0..$-4]);

        auto outputFile = File(outPath, "w");

        FileStream stream = new FileStream(fullPath);
        auto lexer = new Lexer(stream);
        auto parser = new Parser(lexer, types);

        outputFile.write(parser.macroTransform());
        outputFile.close();

        return ProcessorInfo(
            parser.moduleName,
            outPath
        );
    }

    string emit() {
        string result;

        foreach (emittable; emittables) {
            result ~= emittable.emit();
        }

        return result;
    }

    @property Array!Type types() {
        return p_types;
    }

    void generateGeneratedFilesTxt(in bool openToWrite) {
        auto outFile = File(buildPath(projectPath, "generated_files.txt"), openToWrite ? "w" : "a");

        foreach (string generateFilePath; generatedFiles) {
            outFile.writeln(generateFilePath);
        }

        outFile.close();
    }

private:
    Array!IEmittable emittables;
    Array!string filesToProcessing;
    Array!Type p_types;

    void parse(in string fileName) {
        const fullPath = buildPath(projectPath, "src", fileName);

        FileStream stream = new FileStream(fullPath);
        auto lexer = new Lexer(stream);
        auto parser = new Parser(lexer);

        parser.collectTypes();
        p_types ~= parser.types;
    }
}


unittest {
    // import tests.simple_processor;
    // auto processor = new Processor();
    // // processor.addFileToProcessing("tests/simple.d");
    // processor.addFileToProcessing("dapt/token.d");

    // processor.add(new StringEmittable("module tests.simple_generated;\n\n"));
    // processor.collectTypes();
    // processor.generateProcessor("tests/simple_processor.d.gen");
    // processor.process("tests/simple_generated.d.test", &process);
}
