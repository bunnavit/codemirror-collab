type TextNode = sig<TextNode>;
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
    method <int> getLines <> {
        return this->getLines();
    }

    method <list<BaseText>> getChildren <> {
        return this->getChildren();
    }

    // text node methods
    method <> flatten <list<BaseText> a> {
        this->flatten(a);
    }

    // text leaf methods
    method <> flatten <Text a> {
        this->flatten(a);
    }

    method <Text> getText <> {
        return this->getText();
    }

    method <bool> isLeaf <> {
        return this->isLeaf();
    }

}

//////////////// TEXT LEAF //////////////////////

class TextLeaf: BaseText {

    var text: Text;

    ctor <Text a, int b> text(a) {
        this->length = b;
    }

    ctor <Text a> text(a) {
        this->length = textLength(a);
    }
    
    method <list<BaseText>> getChildren <> {
        return <list<BaseText>>();
    }

    method <int> getLines <> {
        return |text|;
    }

    method <Text> getText <> {
        return text;
    }

    method <bool> isLeaf <> {
        return true;
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

    method <> flatten <Text target> {
        for var line in text do {
            target ~> line;
        }
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

///////////////// TEXT NODE //////////////////////

class TextNode: BaseText {
    var children: list<BaseText>;
    var lines: int;
    ctor <list<BaseText> a, int b> children(a){
        this->length = b;
        lines = 0;
        for var child in children do {
            lines += child->getLines();
        }
    }
    method <int> getLines <> {
        return lines;
    }
    method <list<BaseText>> getChildren <> {
        return children;
    }
    method <bool> isLeaf <> {
        return false;
    }
}

// create textNode from textNodes/textLeafs
function <TextNode> nodeFromChildren <list<BaseText> children, int length> {
    var lines = 0;
    for var child in children do {
        lines += child->getLines();
    }
    // create single textLeaf if lines < 32
    if(lines < 32){
        var flat: Text;
        for var child in children do {
            child->flatten(flat);
        }
        return TextLeaf(flat, length);
    }

    var chunk = @max(32, lines ~> 5);
    var maxChunk = chunk <~ 1;
    var minChunk = chunk ~> 1;
    var chunked: list<BaseText>;
    var currentLines = 0;
    var currentLen = -1;
    var currentChunk: list<BaseText>;

    function <> add <BaseText child> {
        var last: BaseText;
        // not finished
        if(child->getLines() > maxChunk && !child->isLeaf()){
            for var textNode in child->getChildren() do {
                add(textNode);
            }
        } else if (
            child->getLines() > minChunk &&
            (currentLines > minChunk || !currentLines)
        ){
            flush();
            chunked ~> child;
        } else if (
            child->isLeaf() &&
            currentLines &&
            (@tail currentChunk)->isLeaf() &&
            child->getLines() + last->getLines() <= 32
        ){  
            last = @tail currentChunk;
            currentLines += child->getLines();
            currentLen += child->length + 1;
            var text: Text = cloneText(last->getText()) ~> cloneText(child->getText());
            var len = last->length + 1 + child->length;
            @tail currentChunk = TextLeaf(text, len);
        } else {
            last = @tail currentChunk;
            if (currentLines + child->getLines() > chunk){
                flush();
            }
            currentLines += child->getLines();
            currentLen += child->length + 1;
            currentChunk ~> child;
        }
    }
    function <> flush <> {
        if(currentLines == 0) return;
        var toChunk: BaseText;
        if(|currentChunk| == 1){
            toChunk = currentChunk[0];
        } else {
            toChunk = nodeFromChildren(currentChunk, currentLen);
        }
        chunked ~> toChunk;
        currentLen = -1;
        currentLines = 0;
        currentChunk = <list<BaseText>>();
    }
    for var child in children do {
        add(child);
    }
    flush();
    if(|chunked| == 1) return chunked[0];
    return TextNode(chunked, length);
}

// TODO: create nodeFromChildren without length here

////////////////// UTILITIES /////////////////

function <TextLeaf> emptyText <> {
    return TextLeaf([""], 0);
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
    textNodeTest();
    sigTest();

    return 0;
}

/////////////// TESTING ////////////////////

function <> testing <> {
    
}

// prob have to fix this
function <> sigTest <> {
    var textLeaf1 = TextLeaf(["one", "two"], 7);

    assert(textLeaf1->isLeaf() == true);

    var isBaseText = <bool>(<BaseText>(textLeaf1));
    var isTextNode = <bool>(<TextNode>(textLeaf1));
    var isTextLeaf = <bool>(<TextLeaf>(textLeaf1));

    // wrong
    assert(isBaseText == true);
    assert(isTextNode == true);
    assert(isTextLeaf == true);

    var textLeaf2 = TextLeaf(["three", "four"], 10);
    var children: list<BaseText> = [textLeaf1, textLeaf2];
    var textNode: TextNode = TextNode(children, 17);

    assert(textNode->isLeaf() == false);

    isBaseText = <bool>(<BaseText>(textNode));
    isTextNode = <bool>(<TextNode>(textNode));
    isTextLeaf = <bool>(<TextLeaf>(textNode));

    // correct
    assert(isBaseText == true);
    assert(isTextNode == true);
    assert(isTextLeaf == false);

    isBaseText = <bool>(<BaseText>(textLeaf1));
    isTextNode = <bool>(<TextNode>(textLeaf1));
    isTextLeaf = <bool>(<TextLeaf>(textLeaf1));

    // wrong
    assert(isBaseText == true);
    assert(isTextNode == true);
    assert(isTextLeaf == true);
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

function <> textNodeTest <> {
    function <> ctorTest <> {
        var textLeaf1 = TextLeaf(["one", "two"], 7);
        var textLeaf2 = TextLeaf(["three", "four"], 10);
        var children: list<BaseText> = [textLeaf1, textLeaf2];
        var textNode: TextNode = TextNode(children, 17);
        assert(textNode->length == 17);
        assert(textNode->getLines() == 4); 
    }
    function <> leafFromChildrenTest <> {
        var textLeaf1 = TextLeaf(["one", "two"], 7);
        var textLeaf2 = TextLeaf(["three", "four"], 10);
        var children: list<BaseText> = [textLeaf1, textLeaf2];
        var textLeaf: BaseText = nodeFromChildren(children, 17);
        assert (textLeaf->getLines() == 4);
        assert (|textLeaf->getChildren()| == 0);
        var text = textLeaf->getText();
        var expected = ["one", "two", "three", "four"];
        assertListEq(text, expected);
    }
    ctorTest();
    leafFromChildrenTest();
}

function <> assertListEq <list<string> a, list<string> b> {
    assert (|a| == |b|);
    var bIter = @fwd b;
    for (var aIter = @fwd a; aIter; aIter ++){
        assert(@elt aIter == @elt bIter);
        bIter++;
    }
}

