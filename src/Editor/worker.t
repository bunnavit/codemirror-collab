type TextNode = vector<TextNode>;
type Text  = list<string>;
type TextLeaf = sig<TextLeaf>;
type BaseText = sig<BaseText>;

class BaseText {
    method length: int;
    ctor <> {}
    method <> decompose <int from, int until, list<TextLeaf> target, int open> {
        $stderr <:: "should never be invoked" <:: '\n';
    }
    method <> testDecompose <> {
        this->decompose(2, 3, [emptyText()], 1);
    }
}


class TextLeaf: BaseText {

    var text: Text;

    ctor <Text a, int b> text(a) {
        this->length = b;
    }

    ctor <Text a> text(a) {
        this->length = textLength(a);
    }
    
    method <> getChildren <> {}

    method <Text> getText <> {
        return text;
    }

    // open: 1 => open from, others => open to
    method <> decompose <int from, int until, list<TextLeaf> target, int open>{
        var newText: TextLeaf;
        if(from <= 0 && until >= this->length){
            newText = TextLeaf(text, this->length);
        } else {
            newText = TextLeaf(
                sliceText(text, from, until),
                @min(until, this->length) - @max(0, from)
            );
        }
        // open from
        if(open & 1){
            var prev: TextLeaf = @poptail target;
            var joined: Text = appendText(
                newText->getText(), cloneText(prev->getText()), 0, newText->length
            );
            if(|joined| <= 32){
                target ~> TextLeaf(joined, prev->length + newText->length);
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
        var until = this->length;
        var lineSep = "\n";
        return sliceString(from, until, lineSep);
    }

    method <string> sliceString <int from, int until, string lineSep> {
        var result = "";
        var pos = 0;
        var i = 0;
        for (var iter = @fwd text; pos <= until && i < this->length; iter++){
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

function <Text> sliceText <Text text, int from, int until> {
    return appendText(text, [""], from, until);
}

function <Text> cloneText <Text text> {
    var newText: Text;
    for var line in text do {
        newText ~> line;
    }
    return newText;
}

function <int> main <> {
    testing();
    utilTest();
    textLeafTest();

    return 0;
}

/////////////// TESTING ////////////////////

function <> testing <> {

}

function <> utilTest <> {
    function <> appendTextTest <> {
        var text: Text =  ["first", "second", "third"];
        var target: Text = ["target1", "target2"];
        appendText(text, target, 0, 1_000_000);
        var expected: Text = ["target1", "target2first", "second", "third"];
        assertListEq(target, expected);

        text = ["fourth"];
        target = ["first", "second", "third", ""];
        appendText(text, target, 0, 6);
        expected = ["first", "second", "third", "fourth"];
        assertListEq(target, expected);
    }

    function <> textLengthTest <> {
        var text: Text =  ["first", "second", "third"];
        var length = textLength(text);
        assert (length == 18);
    }

    function <> sliceTextTest <> {
        var text: Text =  ["first", "second", "third"];
        var outputText = sliceText(text, 0, 1_000_000);
        assertListEq(text, outputText);
    }
    appendTextTest();
    textLengthTest();
    sliceTextTest();
}

function <> textLeafTest <> {
    function <> sliceString <> {
        var textLeaf = TextLeaf(["first", "second", "third"], 18);
        var text = textLeaf->sliceString(6);
        assert (text == "second\nthird");
        text = textLeaf->sliceString(6, 12, "\n");
        assert (text == "second");
    }

    // delete "third"
    function <> decomposeDeletion <> {
        var textLeaf: TextLeaf = TextLeaf(["first", "second", "third"], 18);
        var target: list<TextLeaf>;
        textLeaf->decompose(0, 13, target, 2);
        assert (|target| == 1);
        assert (target[0]->length == 13);
        var text = target[0]->getText();
        var expected: Text = ["first", "second", ""];
        assertListEq(text, expected);
    }
    // add "fourth"
    function <> decomposeAddition <> {
        var textLeaf: TextLeaf = TextLeaf(["fourth"], 6);
        var target: list<TextLeaf> = [TextLeaf(["first", "second", "third", ""], 19)];
        textLeaf->decompose(0, 6, target, 3);
        assert(|target| == 1);
        assert(target[0]->length == 25);
        var text = target[0]->getText();
        var expected: Text = ["first", "second", "third", "fourth"];
        assertListEq(text, expected);
    }
    sliceString();
    decomposeDeletion();
    decomposeAddition();
}

function <> assertListEq <list<string> a, list<string> b> {
    assert (|a| == |b|);
    var bIter = @fwd b;
    for (var aIter = @fwd a; aIter; aIter ++){
        assert(@elt aIter == @elt bIter);
        bIter++;
    }
}

