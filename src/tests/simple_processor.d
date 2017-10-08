module tests.simple_processor;

import tests.simple_uda;
import dapt.traits;
import dapt.type;
import dapt.func;
import dapt.processor;

void process(Processor processor) {
    auto types = getAnnotatedTypes!Tag();

    auto funcBuilder = new Function.Builder()
        .setName("test")
        .setReturnType(Type.createPrimitiveType("void"));

    foreach (Type type; types) {
        funcBuilder.addStatement("$E().greet();", type);
    }

    processor.add(funcBuilder.build());
}
