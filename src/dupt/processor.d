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
}
