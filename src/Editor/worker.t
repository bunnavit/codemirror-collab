type TextNode = vector<TextNode>;
type Text  = list<string>;
type TextLeaf = sig<TextLeaf>;
type BaseText = sig<BaseText>;


class BaseText {
    ctor <> {
        
    }
}

class TextLeaf: BaseText {

    var text: Text;
    var length: int;

    ctor <Text a, int b> {
        text = a;
        length = b;
    }

    method <int> getLength <> {
        return length;
    }
    
    method <> getChildren <> {}

    method <list<string>> getText <> {
        return text;
    }

    method <string> sliceString <int from> {
        var until = length;
        var lineSep = "\n";
        var result = "";
        var pos = 0;
        for (var i = 0; pos <= until && i < length; i++){
            var line = text[i];
            var end = pos + |line|;
            if (pos > from && i) result = result + lineSep;
            if (from < end && until > pos){
                result = result + $substring(line, @max(0, from - pos), until - pos);
            }
            pos = end + 1;
        }
        return result;
    }
    method <string> sliceString <int from, int until, string lineSep> {
        var result = "";
        var pos = 0;
        for (var i = 0; pos <= until && i < length; i++){
            var line = text[i];
            var end = pos + |line|;
            if (pos > from && i) result = result + lineSep;
            if (from < end && until > pos){
                result = result + $substring(line, @max(0, from - pos), until - pos);
            }
            pos = end + 1;
        }
        return result;
    }

    method <Text> flatten <Text target> {
        for var line in text do {
            target ~> line;
        }
        return target;
    }

}

// splits single textLeaf into multiple textLeafs
function <list<BaseText>> split <Text text> {
    var target: list<BaseText>;
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

