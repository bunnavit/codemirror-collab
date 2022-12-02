type TextNode = vector<TextNode>;
type Text  = list<string>;
type TextLeaf = sig<TextLeaf>;


class Text {
    ctor <> {
        
    }
}

class TextLeaf: Text {

    var text: Text;
    var length: int;

    ctor <Text a, int b> {
        text = a;
        length = b;
    }

    method <int> getLength <> {
        return length;
    }

    method <list<string>> getText <> {
        return text;
    }

}

// splits single textLeaf into multiple textLeafs
function <list<TextLeaf>> split <Text text> {
    var target: list<TextLeaf>;
    var part: Text;
    var len = -1;
    for var line in text do {
        part ~> line;
        len = len + |line| + 1;
        if(|part| == 32){
            target ~> TextLeaf(part, len);
            part = <Text>();
            len = -1;
        }
    }
    if(len > -1){
        target ~> TextLeaf(part, len);
    }
    return target;
}

// testing func
function <> testing <> {
    var target: <list<sig<TextLeaf>>>;
    for (var i = 0; i < 3; i++) {
        var leaf = TextLeaf(["test"], i);
        target ~> leaf;
    }
    for var leaf in target do {
        $stdout <:: leaf->getLength() <:: '\n';
    }
}


function <int> main <> {
    var textLeaf = TextLeaf(["text", "text2", "text3"], 1);
    var text = textLeaf->getText();
    var splitText = split(text);
    testing();
    return 0;
}

