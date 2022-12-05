type TextNode = vector<TextNode>;
type Text  = list<string>;
type TextLeaf = sig<TextLeaf>;
type BaseText = sig<BaseText>;

class BaseText {
    ctor <> {}
    method <> decompose <int from, int until, list<TextLeaf> target, int open> {
        $stderr <:: "should not fire" <:: '\n';
    }
    method <> testDecompose <> {
        this->decompose(2, 3, [emptyText()], 1);
    }
}


class TextLeaf: BaseText {

    var text: Text;
    var length: int;

    ctor <Text a, int b> text(a), length(b) {}

    ctor <Text a> text(a) {
        length = textLength(a);
    }

    method <int> getLength <> {
        return length;
    }
    
    method <> getChildren <> {}

    method <Text> getText <> {
        return text;
    }

    // open: 1 => open from, 2 => open to
    method <> decompose <int from, int until, list<TextLeaf> target, int open>{
        var newText: TextLeaf;
        if(from <= 0 && until >= length){
            newText = TextLeaf(text, length);
        } else {
            newText = TextLeaf(
                sliceText(text, from, until),
                @min(until, length) - @max(0, from)
            );
        }
        // open from
        if(open & 1){
            var prev: TextLeaf = @poptail target;
            var joined: Text = appendText(
                newText->getText(), sliceText(prev->getText()), 0, newText->getLength()
            );
            if(|joined| <= 32){
                target ~> TextLeaf(joined, prev->getLength() + newText->getLength());
            } else {
                var mid: int = |joined| ~> 1;
                target ~> TextLeaf(sliceText(joined, 0, mid));
                target ~> TextLeaf(sliceText(joined, mid, |joined|));
            }
        } else {
            target ~> newText;
        }

    }

    method <string> sliceString <int from> {
        var until = length;
        var lineSep = "\n";
        return sliceString(from, until, lineSep);
    }

    method <string> sliceString <int from, int until, string lineSep> {
        var result = "";
        var pos = 0;
        var i = 0;
        for (var iter = @fwd text; pos <= until && i < length; iter++){
            var line = @elt iter;
            var end = pos + |line|;
            if (pos > from && i) result = result + lineSep;
            if (from < end && until > pos){
                result = result + $substring(line, @max(0, from - pos), until - pos);
            }
            pos = end + 1;
            i++;
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



////////////////// UTILITIES /////////////////

function <TextLeaf> emptyText <> {
    return TextLeaf([""], 0);
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

function <int> textLength <Text text> {
    var length = -1;
    for var line in text do {
        length += |line| + 1;
    }
    return length;
}

function <Text> appendText <Text text, Text target, int from, int until>{
    var i = 0;
    var pos = 0;
    var first = true;
    for (var iter = @fwd text; i < |text| && pos <= until; iter++){
        var line = @elt iter;
        var end = pos + |line|;
        if(end >= from){
            if(end > until) {
                line = $substring(line, 0, until - pos);
            }
            if(pos < from){
                line = $substring(line, from - pos, |line|);
            }
            if(first){
                @tail target = @tail target + line;
                first = false;
            } else {
                target ~> line;
            }
        }
        pos = end + 1;
        i++;
    }
    return target;
}

function <Text> sliceText <Text text> {
    return sliceText(text, 0, |text|);
}

function <Text> sliceText <Text text, int from, int until> {
    return appendText(text, [""], from, until);
}

// testing func
function <> testing <> {

    var inputText: Text = ["first", "second", "third"];

    // TextLeaf sliceString test
    var textLeaf = TextLeaf(inputText, 18);
    var text = textLeaf->sliceString(6);
    assert (text == "second\nthird");
    text = textLeaf->sliceString(6, 12, "\n");
    assert (text == "second");

    // appendText
    var target: Text = ["one", "two"];
    appendText(inputText, target, 0, 1_000_000);
    var expected: Text = ["one", "twofirst", "second", "third"];
    var targetIter = @fwd target;
    for (var eIter = @fwd expected; eIter; eIter++){
        assert (@elt eIter == @elt targetIter);
        targetIter++;
    }

    // textLength
    var length = textLength(inputText);
    assert (length == 18);

    // sliceText
    var outputText = sliceText(inputText, 0, 1_000_000);
    var iIter = @fwd inputText;
    for (var oIter = @fwd outputText; oIter; oIter++){
        assert(@elt oIter == @elt iIter);
        iIter++;
    }

}

function <> testing2 <> {
    var l: list<string>;
    l ~> "hello" ~> "world";
    $stdout <:j: l <:: '\n';
}


function <int> main <> {
    testing();
    testing2();

    return 0;
}

