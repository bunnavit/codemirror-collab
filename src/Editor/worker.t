type TextNode = vector<TextNode>;
type Text  = list<string>;


class Text {
    ctor <> {
        
    }
}

class TextLeaf: Text {

    var text: Text;
    var length: int;

    ctor <Text a> {
        length = 0;
        text = a;
    }

    method <int> getLength <> {
        return length;
    }

    method <list<string>> getText <> {
        return text;
    }

    // static method
    method <list<Text>> split <Text text> {
        var part: Text;
        var len = -1;
        for var line in text do {
            part ~> line;
            len = len + |line| + 1;
            $stdout<:: len <:: '\n';
        }

    }
}

function <int> main <> {
    var textLeaf = TextLeaf(["text", "text2", "text3"]);
    var text = textLeaf->getText();
    var split = textLeaf->split(text);

    return 0;
}