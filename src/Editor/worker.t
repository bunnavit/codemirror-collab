type Text  = list<string>;
type BaseText = sig<BaseText>;
type TextLeaf = sig<TextLeaf>;
type TextNode = sig<TextNode>;

class BaseText {
    method length: int;
    ctor <> {}
    method <int> getLines <> {
        return this->getLines();
    }

    method <list<BaseText>> getChildren <> {
        return this->getChildren();
    }

    method <Text> getText <> {
        return this->getText();
    }

    method <bool> isLeaf <> {
        return this->isLeaf();
    }

    method <> decompose <int from, int until, list<BaseText> target, int open> {
        this->decompose(from, until, target, open);
    }

    method <string> sliceString <int from> {
        return this->sliceString(from);
    }

    method <string> sliceString <int from, int until, string lineSep> {
        return this->sliceString(from, until, lineSep);
    }

    method <> flatten <Text target> {
        this->flatten(target);
    }

    // Replace a range of the text with the given content
    method <> replace <> {
        //TODO
    }

    // Append another document to this one
    method <> append <> {
        // TODO
    }

    // Convert the document to an array of lines 
    // which can be deserialized again via makeDoc
    method <Text> toJSON <> {
        var lines: Text;
        this->flatten(lines);
        return lines;
    }
}

// Create document with array of lines
function <BaseText> makeDoc <Text text> {
    if(|text| == 0){
        $stderr <:: "A document must have at least one line" <:: '\n';
    }
    if(|text| == 1 && !text[0]) return emptyText();
    if(|text| <= 32) return TextLeaf(text);
    return nodeFromChildren(leafsFromText(text));
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
    method <> decompose <int from, int until, list<BaseText> target, int open>{
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
        for (var iter = @fwd text; pos <= until && iter; iter++){
            var line = @elt iter;
            var end = pos + |line|;
            if (pos > from && line != @head text) result = result + lineSep;
            if (from < end && until > pos){
                result = result + $substring(line, @max(0, from - pos), until - pos);
            }
            pos = end + 1;
        }
        return result;
    }

    method <> flatten <Text target> {
        for var line in text do {
            target ~> line;
        }
    }
}

// convert text into multiple textLeafs
function <list<TextLeaf>> leafsFromText <Text text> {
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

    method <> decompose <int from, int until, list<BaseText> target, int open>{
        var pos = 0;
        for (var iter = @fwd children; pos <= until && iter; iter++){
            var child = @elt iter;
            var end = pos + child->length;
            if (from <= end && until >= pos) {
                // 1 => open from, 2 => open to
                var childOpen = open & ((pos <= from ? 1 : 0) | (end >= until ? 2 : 0));
                if (pos >= from && end <= until && !childOpen){
                    target ~> child;
                } else {
                    child->decompose(from - pos, until - pos, target, childOpen);
                }
            }
            pos = end + 1;
        }
    }

    method <string> sliceString <int from, int until, string lineSep> {
        var result = "";
        var pos = 0;
        for (var iter = @fwd children; iter && pos <= until; iter++) {
            var child = @elt iter;
            var end = pos + child->length;
            if(pos > from && child != @head children){
                result = result + lineSep;
            }
            if(from < end && until > pos){
                result = result + child->sliceString(from - pos, until - pos, lineSep);
            }
            pos = end + 1;
        }
        return result;
    }

    method <string> sliceString <int from> {
        var until = this->length;
        var lineSep = "\n";
        return sliceString(from, until, lineSep);
    }

    method <> flatten <Text target> {
        for var child in children do {
            child->flatten(target);
        }
    }
}

// create textNode from textNodes/textLeafs
function <BaseText> nodeFromChildren <list<BaseText> children, int length> {
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

        if(|currentChunk|){
            last = @tail currentChunk;
        }

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
            currentLines += child->getLines();
            currentLen += child->length + 1;
            var text: Text = cloneText(last->getText()) ~> cloneText(child->getText());
            var len = last->length + 1 + child->length;
            @tail currentChunk = TextLeaf(text, len);
        } else {
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

function <BaseText> nodeFromChildren <list<BaseText> children> {
    var length = -1;
    for var child in children do {
        length += child->length + 1;
    }
    return nodeFromChildren(children, length);
}

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

    // generateInput(10000);

    return 0;
}

/////////////// TESTING ////////////////////

function <> testing <> {
    utilTest();
    baseTextTest();
    textLeafTest();
    textNodeTest();
    sigTest();
}

function <> sigTest <> {
    var textLeaf1 = TextLeaf(["one", "two"], 7);

    assert(textLeaf1->isLeaf() == true);

    var isBaseText = <bool>(<BaseText>(textLeaf1));
    var isTextNode = <bool>(<TextNode>(textLeaf1));
    var isTextLeaf = <bool>(<TextLeaf>(textLeaf1));

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

    function <> generateTextTest <> {
        var leafs = generateTextLeafs(34);
        assert(|leafs| == 2);
        assert(leafs[0]->length == 214);
        assert(leafs[1]->length == 13);
        var secondText = leafs[1]->getText();
        var expected = ["text33", "text34"];
        assertListEq(secondText, expected);
    }

    appendTextTest();
    textLengthTest();
    sliceTextTest();
    generateTextTest();
}

function <> baseTextTest <> {
    function <> makeDocTest <> {
        var text = [""];
        var doc = makeDoc(text);
        assert(doc->isLeaf());
        assertListEq(doc->getText(), text);

        text = generateText(3);
        doc = makeDoc(text);
        assert(doc->isLeaf());
        assert(|doc->getChildren()| == 0);
        assert(doc->getLines() == 3);
        assert(doc->length == 17);
        assertListEq(doc->getText(), text); 

        text = generateText(34);
        doc = makeDoc(text);
        assert(!doc->isLeaf());
        assert(|doc->getChildren()| == 2);
        assert(doc->getLines() == 34);
        assert(doc->length == 228);
        var leaf2 = doc->getChildren()[1];
        assert(leaf2->isLeaf());
        var expectedText = ["text33", "text34"];
        assertListEq(leaf2->getText(), expectedText);

        text = generateText(100_000);
        doc = makeDoc(text);
        assert(!doc->isLeaf());
        assert(|doc->getChildren()| == 33);
        assert(doc->getLines() == 100_000);
        assert(doc->length == 988894);

        var firstChild = doc->getChildren()[0];
        assert(!firstChild->isLeaf());
        assert(|firstChild->getChildren()| == 33);
        assert(firstChild->getLines() == 3104);
        assert(firstChild->length == 26828);

        var childOfChild = firstChild->getChildren()[0];
        assert(!childOfChild->isLeaf());
        assert(|childOfChild->getChildren()| == 3);
        assert(childOfChild->getLines() == 96);
        assert(childOfChild->length == 662);

        var firstLeaf = childOfChild->getChildren()[0];
        assert(firstLeaf->isLeaf());
        assert(firstLeaf->getLines() == 32);
        assert(firstLeaf->length == 214);
        assertListEq(firstLeaf->getText(), generateText(32));
    }
    makeDocTest();
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
    function <> nodeFromChildrenTest <> {
        var children = generateTextLeafs(34);

        var textNodes: list<BaseText>;
        textNodes ~> nodeFromChildren(children);
        textNodes ~> nodeFromChildren(children, 228);

        for var textNode in textNodes do {
            assert(textNode->isLeaf() == false);
            assert(textNode->length == 228);
            assert(textNode->getLines() == 34);

            var nodeChildren = textNode->getChildren();

            var textLeaf1 = nodeChildren[0];
            assert(textLeaf1->isLeaf());
            assert(textLeaf1->length == 214);
            assert(|textLeaf1->getText()| == 32);
            assert(textLeaf1->getLines() == 32);
            assert(|textLeaf1->getChildren()| == 0);

            var textLeaf2 = nodeChildren[1];
            assert(textLeaf2->length == 13);
            assert(textLeaf2->getLines() == 2);
            var text = textLeaf2->getText();
            var expected = ["text33", "text34"];
            assertListEq(text, expected);
        }
    }
    function <> decomposeTest <> {
        var children = generateTextLeafs(34);
        var textNode = nodeFromChildren(children);
        var target = <list<BaseText>>([emptyText()]);
        assert(|target| == 1);
        textNode->decompose(0, 228, target, 3);
        assert(|target| == 2);

        var textLeaf1 = target[0];
        assert(textLeaf1->isLeaf());
        assert(textLeaf1->length == 214);
        assert(|textLeaf1->getText()| == 32);
        assert(textLeaf1->getLines() == 32);
        assert(|textLeaf1->getChildren()| == 0);

        var textLeaf2 = target[1];
        assert(textLeaf2->length == 13);
        assert(textLeaf2->getLines() == 2);
        var text = textLeaf2->getText();
        var expected = ["text33", "text34"];
        assertListEq(text, expected);
    }
    function <> sliceStringTest <> {
        var children = generateTextLeafs(34);
        var textNode = nodeFromChildren(children);
        var text = textNode->sliceString(0, 228, "\n");
        var text2 = textNode->sliceString(0);
        var expected = "";
        for (var i = 1; i <= 34; i++){
            expected = expected + "text" + <string>(i) + "\n";
        }
        assert (expected == text + "\n");
        assert (expected == text2 + "\n");
    }
    ctorTest();
    leafFromChildrenTest();
    nodeFromChildrenTest();
    decomposeTest();
    sliceStringTest();
}

///////////////////// TEST UTILS ///////////////////

function <> assertListEq <list<string> a, list<string> b> {
    assert (|a| == |b|);
    var bIter = @fwd b;
    for (var aIter = @fwd a; aIter; aIter ++){
        assert(@elt aIter == @elt bIter);
        bIter++;
    }
}

function <Text> generateText <int count> {
    var text: Text;
    for (var i = 1; i <= count; i++){
        text ~> ("text" + <string>(i));
    }
    return text;
}

function <list<TextLeaf>> generateTextLeafs <int count> {
    var leafList: list<TextLeaf>;
    var text: Text;
    for (var i = 1; i <= count; i++){
        text ~> ("text" + <string>(i));
        if(i%32 == 0){
            leafList ~> TextLeaf(text);
            text = <Text>();
        }
    }
    if(|text| > 0){
        leafList ~> TextLeaf(text);
    }
    return leafList;
}

function <> generateInput <int count> {
    var s : stream["input.txt", @utf8, @out];
    if(s){
        for(var i = 1; i <= count; i++){
            s <:: "text" + <string>(i) <:: '\n';
        }
    }
}

