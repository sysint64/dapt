module dupt.processor;

import std.container.array;
import std.path;
import std.file : thisExePath;
import std.stdio;

import dupt.emitter;

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
        clear();
        const binDirectory = dirName(thisExePath());
        const fullPath = buildPath(binDirectory, "src", outputFileName);
        auto outputFile = File(fullPath, "w");
        processorHandler(this);
        outputFile.write(emit());
        outputFile.close();
    }

    string emit() {
        string result;

        foreach (emittable; emittables) {
            result ~= emittable.emit();
        }

        return result;
    }

private:
    Array!IEmittable emittables;
    Array!string filesToProcessing;
}

unittest {
    import tests.simple_processor;
    auto processor = new Processor();
    processor.addFileToProcessing("tests/simple.d");
    processor.process("tests/simple_generated.d.test", &process);
}
