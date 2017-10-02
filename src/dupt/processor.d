module dupt.processor;

import dupt.emitter;
import std.container.array;

class Processor {
    Array!IEmittable emittables;

    void add(IEmittable emittable) {
        emittables.insert(emittable);
    }

    void process() {
    }

    string emit() {
        string result;

        foreach (emittable; emittables) {
            result ~= emittable.emit();
        }

        return result;
    }
}
