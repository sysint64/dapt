module dapt.processor;

import std.container.array;
import std.path;
import std.file : thisExePath;
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

class Processor {
    string projectPath;

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

    void openFile(in string fileName) {
        const fullPath = buildPath(projectPath, "src", fileName);
        generatedFile = File(fullPath, "w");
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

        // writeln(parser.macroTransform());
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

private:
    Array!IEmittable emittables;
    Array!string filesToProcessing;
    Array!Type p_types;

    void parse(in string fileName) {
        const fullPath = buildPath(projectPath, "src", fileName);
        writeln(fullPath, " --------------------------------------");

        FileStream stream = new FileStream(fullPath);
        auto lexer = new Lexer(stream);
        auto parser = new Parser(lexer);

        parser.collectTypes();
        p_types ~= parser.types;
        writeln("end");
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
