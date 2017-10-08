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

        import dapt.token : Token;

        if (hasUDA!(Token, Tag)) {
            funcBuilder.addStatement("$L;", "import dapt.token : Token");
            funcBuilder.addStatement("$L().greet(\"$L\");", "Token", "Hello world!");
        }
    
    }

    {

        import dapt.token : SymbolToken;

        if (hasUDA!(SymbolToken, Tag)) {
            funcBuilder.addStatement("$L;", "import dapt.token : SymbolToken");
            funcBuilder.addStatement("$L().greet(\"$L\");", "SymbolToken", "Hello world!");
        }
    
    }

    {

        import dapt.token : StringToken;

        if (hasUDA!(StringToken, Tag)) {
            funcBuilder.addStatement("$L;", "import dapt.token : StringToken");
            funcBuilder.addStatement("$L().greet(\"$L\");", "StringToken", "Hello world!");
        }
    
    }

    {

        import dapt.token : IdToken;

        if (hasUDA!(IdToken, Tag)) {
            funcBuilder.addStatement("$L;", "import dapt.token : IdToken");
            funcBuilder.addStatement("$L().greet(\"$L\");", "IdToken", "Hello world!");
        }
    
    }

    {

        import dapt.token : MacroToken;

        if (hasUDA!(MacroToken, Tag)) {
            funcBuilder.addStatement("$L;", "import dapt.token : MacroToken");
            funcBuilder.addStatement("$L().greet(\"$L\");", "MacroToken", "Hello world!");
        }
    
    }


    processor.add(funcBuilder.build());
}