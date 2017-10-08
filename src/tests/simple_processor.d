module tests.simple_processor;

import tests.simple_uda;
import std.traits;

import dapt.type;
import dapt.func;
import dapt.processor;
import dapt.emitter;

void process(Processor processor) {
    auto funcBuilder = new Function.Builder()
        .setName("test")
        .setReturnType(Type.createPrimitiveType("void"));

    
    {

        import tests.simple : A;

        if (hasUDA!(A, Tag)) {
            funcBuilder.addStatement("$L;", "import tests.simple : A");
            funcBuilder.addStatement("$L().greet();", "A");
        }
    
    }

    {

        import tests.simple : B;

        if (hasUDA!(B, Tag)) {
            funcBuilder.addStatement("$L;", "import tests.simple : B");
            funcBuilder.addStatement("$L().greet();", "B");
        }
    
    }

    {

        import tests.simple : C;

        if (hasUDA!(C, Tag)) {
            funcBuilder.addStatement("$L;", "import tests.simple : C");
            funcBuilder.addStatement("$L().greet();", "C");
        }
    
    }


    processor.add(funcBuilder.build());
}