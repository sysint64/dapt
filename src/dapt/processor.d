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

class Processor {
    void clear() {
        emittables.clear();
    }

    void addFileToProcess(in string fileName) {
        filesToProcessing.insert(fileName);
    }

    void add(IEmittable emittable) {
        emittables.insert(emittable);
    }

    void addFileToProcessing(in string fileName) {
        filesToProcessing.insert(fileName);
    }

    void process(in string outputFileName, void function(Processor processor) processorHandler) {
        const binDirectory = dirName(thisExePath());
        const fullPath = buildPath(binDirectory, "src", outputFileName);
        auto outputFile = File(fullPath, "w");

        foreach (string fileName; filesToProcessing) {
            parse(fileName);
        }

        processorHandler(this);
        outputFile.write(emit());
        outputFile.close();
    }

    void collectTypes() {
        foreach (string fileName; filesToProcessing) {
            parse(fileName);
        }
    }

    void generateProcessor(in string fileName) {
        const binDirectory = dirName(thisExePath());
        const fullPath = buildPath(binDirectory, "src", fileName);
        const outPath = buildPath(binDirectory, "src", fileName[0..$-4]);

        auto outputFile = File(outPath, "w");

        FileStream stream = new FileStream(fullPath);
        auto lexer = new Lexer(stream);
        auto parser = new Parser(lexer, types);

        outputFile.write(parser.macroTransform());
        outputFile.close();
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
        const binDirectory = dirName(thisExePath());
        const fullPath = buildPath(binDirectory, "src", fileName);

        FileStream stream = new FileStream(fullPath);
        auto lexer = new Lexer(stream);
        auto parser = new Parser(lexer);

        parser.collectTypes();
        p_types ~= parser.types;
    }
}


unittest {
    import tests.simple_processor;
    auto processor = new Processor();
    processor.addFileToProcessing("tests/simple.d");

    processor.add(new StringEmittable("module tests.simple_generated;\n\n"));
    processor.collectTypes();
    processor.generateProcessor("tests/simple_processor.d.gen");
    processor.process("tests/simple_generated.d.test", &process);
}
