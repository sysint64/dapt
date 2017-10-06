module dupt.ast;

import std.container.array;

class ASTNode {
}

class ModuleASTNode : ASTNode {
    const string name;
    private Array!ASTNode nodes;

    this(in string name) {
        this.name = name;
        this.nodes = nodes;
    }

    void insertNode(ASTNode node) {
        nodes.insert(node);
    }
}
