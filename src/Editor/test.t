entry <int> main <> // main
{
   var $W0 : wire<string, string, string, int, string>[32];
   var $W1 : wire<string, list<string>, string, string, int, list<string, list<string, int, list<string, int, string>>>>[32];
   var $W2 : wire<string, string>[32];
   var $W3 : wire<string>[32];
   var $W4 : wire<list<string>>[1];
   var $W5 : wire<string, list<string>, string>[32];
   var $W6 : wire<string>[32];
   var $W7 : wire<list<string>>[32];
   var $W8 : wire<string>[32];
   var $W9 : wire<bool>[32];
   var $W10 : wire<string>[32];
   var $W11 : wire<string, string, string, int, list<string, list<string, int, list<string, int, string>>>>[32];
   var $W12 : wire<string>[32];
   var $W13 : wire<string>[32];
   var $W14 : wire<string>[32];
   var $W15 : wire<int>[32];
   var $W16 : wire<list<string, list<string, int, list<string, int, string>>>>[32];
   var $W17 : wire<string>;
   var $W18 : wire<string>[32];
   var $W19 : wire<string>[32];
   var $W20 : wire<string>[32];
   var $W21 : wire<string>[32];
   var $W22 : wire<int>[1];
   var $W23 : wire<list<string, list<string, int, list<string, int, string>>>>[32];
   var $W24 : wire<string, list<string, int, list<string, int, string>>>[32];
   var $W25 : wire<string>[32];
   var $W26 : wire<list<string, int, list<string, int, string>>>[32];
   var $W27 : wire<string>[1];
   // echo [20]
   node $echoifnot_s_1_1(trigger in $W3, trigger out $W18);
   // GetDocId$FOT3XT5sssdsYtYs [27]
   node GetDocId(trigger in $W0, trigger out $W9, trigger out $W10);
   // echoif [19]
   node $echoif_t_s_1_1(trigger in $W9, trigger in $W10, trigger out $W3);
   // once [11]
   (out $W4) <:: <shared list<string>>(share ["text1", "text2", "text3"]);
   // MakeCreateRequest$FOT3XLsXsYT3sLss [25]
   node MakeCreateRequest(trigger in $W4, trigger in $W19, trigger out $W5);
   // detuple [26]
   node $detuple_T3sLss_111(trigger in $W5, trigger out $W6, trigger out $W7, trigger out $W8);
   // echo [32]
   node $echoifnot_s_1_1(trigger in $W17, trigger out $W19);
   // tuple [15]
   node $tuple_T6sLsssdLT2sLT3sdLT3sds_111000(trigger in $W6, trigger in $W7, trigger in $W8, @unused trigger in <string>, @unused trigger in <int>, @unused trigger in <shared list<string, list<string, int, list<string, int, string>>>>, trigger out $W1);
   // val [7]
   (out $W17) <:: <string>(// connectionID
"bob");
   // Doc$FOT3XT6sLsssdLT2sLT3sdLT3sdsYT5sssdsYT2ss [14]
   node Doc(trigger in $W1, trigger out $W0, trigger out $W2);
   // LogResp$FOXT5sssds [23]
   node LogResp(trigger in $W0);
   // echo [31]
   node $echoifnot_s_1_1(trigger in $W17, trigger out $W20);
   // LogB$FOXT2ss [21]
   node LogB(trigger in $W2);
   // tuple [18]
   node $tuple_T6sLsssdLT2sLT3sdLT3sds_101111(trigger in $W12, @unused trigger in <shared list<string>>, trigger in $W13, trigger in $W14, trigger in $W15, trigger in $W16, trigger out $W1);
   // detuple [28]
   node $detuple_T5sssdLT2sLT3sdLT3sds_11111(trigger in $W11, trigger out $W12, trigger out $W13, trigger out $W14, trigger out $W15, trigger out $W16);
   // MakePushRequest$FOT5XsXsXdXLT2sLT3sdLT3sdsYT5sssdLT2sLT3sdLT3sds [24]
   node MakePushRequest(trigger in $W20, trigger in $W21, trigger in $W22, trigger in $W23, trigger out $W11);
   // echo [30]
   node $echoifnot_s_1_1(trigger in $W18, trigger out $W21);
   // once [33]
   (out $W22) <:: <int>(// version
0);
   // echo [37]
   node $echoifnot_s_1_1(trigger in $W17, trigger out $W25);
   // pack [42]
   node $pack_T2sLT3sdLT3sds_11(trigger in $W25, trigger in $W26, trigger out $W24);
   // makelist [36]
   node $makelist_T2sLT3sdLT3sds_1(trigger in $W24, trigger out $W23);
   // MakeChanges$FOT2XsYLT3sdLT3sds [48]
   node MakeChanges(trigger in $W27, trigger out $W26);
   // once [39]
   (out $W27) <:: <string>(// changes
"[17, [0, \"\", \"text4\"]]");
   fork $numcores();
   return 0;
}
node $detuple_T3sLss_111
{
   var input : trigger in<string, list<string>, string>;
   var o0 : trigger out<string>;
   var o1 : trigger out<list<string>>;
   var o2 : trigger out<string>;
   export ctor <trigger in<string, list<string>, string> input, trigger out<string> o0, trigger out<list<string>> o1, trigger out<string> o2> : input(input), o0(o0), o1(o1), o2(o2) {}
   fire {
      var (x0, x1, x2) = <:: input;
      o0 <:: x0;
      o1 <:: x1;
      o2 <:: x2;
      return 1;
   }
}
node $detuple_T5sssdLT2sLT3sdLT3sds_11111
{
   var input : trigger in<string, string, string, int, list<string, list<string, int, list<string, int, string>>>>;
   var o0 : trigger out<string>;
   var o1 : trigger out<string>;
   var o2 : trigger out<string>;
   var o3 : trigger out<int>;
   var o4 : trigger out<list<string, list<string, int, list<string, int, string>>>>;
   export ctor <trigger in<string, string, string, int, list<string, list<string, int, list<string, int, string>>>> input, trigger out<string> o0, trigger out<string> o1, trigger out<string> o2, trigger out<int> o3, trigger out<list<string, list<string, int, list<string, int, string>>>> o4> : input(input), o0(o0), o1(o1), o2(o2), o3(o3), o4(o4) {}
   fire {
      var (x0, x1, x2, x3, x4) = <:: input;
      o0 <:: x0;
      o1 <:: x1;
      o2 <:: x2;
      o3 <:: x3;
      o4 <:: x4;
      return 1;
   }
}
node $echoif_t_s_1_1
{
   var gate : trigger in<bool>;
   var i0 : trigger in<string>;
   var o0 : trigger out<string>;
    export ctor <trigger in<bool> gate, trigger in<string> i0, trigger out<string> o0> : gate(gate), i0(i0), o0(o0) {}
    fire
    {
       if (<:: gate)
       {
          o0 <:: <:: i0;
       }
       else
       {
          <:: i0;
       }
       return 1;
    }
}
node $echoifnot_s_1_1
{
   var i0 : trigger in<string>;
   var o0 : trigger out<string>;
    export ctor <trigger in<string> i0, trigger out<string> o0> : i0(i0), o0(o0) {}
    fire
    {
       o0 <:: <:: i0;
       return 1;
    }
 }
 node $makelist_T2sLT3sdLT3sds_1
{
   var i0 : trigger in<string, list<string, int, list<string, int, string>>>;
   var output : trigger out<list<string, list<string, int, list<string, int, string>>>>;
   export ctor <trigger in<string, list<string, int, list<string, int, string>>> i0, trigger out<list<string, list<string, int, list<string, int, string>>>> output> : i0(i0), output(output) {}
   fire {
      var l : list<shared <string, list<string, int, list<string, int, string>>>>;
      l ~>  <:: i0;
      output <:: share l;
      return 1;
   }
}
node $pack_T2sLT3sdLT3sds_11
{
   var i0 : trigger in<string>;
   var i1 : trigger in<list<string, int, list<string, int, string>>>;
   var output : trigger out<string, list<string, int, list<string, int, string>>>;
   export ctor <trigger in<string> i0, trigger in<list<string, int, list<string, int, string>>> i1, trigger out<string, list<string, int, list<string, int, string>>> output> : i0(i0), i1(i1), output(output) {}
   fire { output <:: (<:: i0, <:: i1); return 1; }
}
node $tuple_T6sLsssdLT2sLT3sdLT3sds_101111
{
   var i0 : trigger in<string>;
   var i1 : trigger in<list<string>>;
   var i2 : trigger in<string>;
   var i3 : trigger in<string>;
   var i4 : trigger in<int>;
   var i5 : trigger in<list<string, list<string, int, list<string, int, string>>>>;
   var output : trigger out<string, list<string>, string, string, int, list<string, list<string, int, list<string, int, string>>>>;
   export ctor <trigger in<string> i0, trigger in<list<string>> i1, trigger in<string> i2, trigger in<string> i3, trigger in<int> i4, trigger in<list<string, list<string, int, list<string, int, string>>>> i5, trigger out<string, list<string>, string, string, int, list<string, list<string, int, list<string, int, string>>>> output> : i0(i0), i1(i1), i2(i2), i3(i3), i4(i4), i5(i5), output(output) {}
   fire { output <:: (<:: i0, <shared list<string>>(), <:: i2, <:: i3, <:: i4, <:: i5); return 1; }
}
node $tuple_T6sLsssdLT2sLT3sdLT3sds_111000
{
   var i0 : trigger in<string>;
   var i1 : trigger in<list<string>>;
   var i2 : trigger in<string>;
   var i3 : trigger in<string>;
   var i4 : trigger in<int>;
   var i5 : trigger in<list<string, list<string, int, list<string, int, string>>>>;
   var output : trigger out<string, list<string>, string, string, int, list<string, list<string, int, list<string, int, string>>>>;
   export ctor <trigger in<string> i0, trigger in<list<string>> i1, trigger in<string> i2, trigger in<string> i3, trigger in<int> i4, trigger in<list<string, list<string, int, list<string, int, string>>>> i5, trigger out<string, list<string>, string, string, int, list<string, list<string, int, list<string, int, string>>>> output> : i0(i0), i1(i1), i2(i2), i3(i3), i4(i4), i5(i5), output(output) {}
   fire { output <:: (<:: i0, <:: i1, <:: i2, <string>(), <int>(), <shared list<string, list<string, int, list<string, int, string>>>>()); return 1; }
}
type Text  = list<string>;
type BaseText = sig<BaseText>;
type TextLeaf = sig<TextLeaf>;
type TextNode = sig<TextNode>;
type ChangeSet = sig<ChangeSet>;

type ChangeSetJSONReturn = 
<
    ChangeSet value,
    string error
>;

type MakeDocReturn =
<
    BaseText value,
    string error
>;

type Updates = list<Update>;
type Update = 
<
    string connectionID,
    Changes changes
>;

type Changes = list<Change>;
type Change = 
<
    string $type,
    int i, 
    list<string $type, int i, string s> l
>;

type DocUpdate = 
<
    string connectionID,
    ChangeSet changes
>;

class BaseText {
    method length: int;
    ctor <> {}
    method <int> getLines <>{}
    method <list<BaseText>> getChildren <>{}
    method <Text> getText <>{}
    method <bool> isLeaf <>{}
    method <> decompose <int from, int until, list<BaseText> target, int open>{}
    method <string> sliceString <int from>{}
    method <string> sliceString <int from, int until, string lineSep>{}
    method <> flatten <Text target>{}

    // Replace a range of the text with the given content
    method <BaseText> replace <int from, int until, BaseText text> {
        var parts: list<BaseText>;
        var i = 0;
        // open to
        this->decompose(0, from, parts, 2);
        if(text->length){
            // open from, open to
            text->decompose(0, text->length, parts, 1 | 2);
        }
        // open from
        this->decompose(until, this->length, parts, 1);
        // test
        return nodeFromChildren(parts, this->length - (until - from) + text->length);
    }

    // Append another document to this one
    method <BaseText> append <BaseText other> {
        return replace(this->length, this->length, other);
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
function <MakeDocReturn> makeDoc <Text text> {
    var error: string;
    var doc: BaseText;
    var makeDocReturn: MakeDocReturn;
    makeDocReturn = {
        doc,
        error
    };
    if(|text| == 0){
        makeDocReturn.error = "A document must have at least one line";
    } else if(|text| == 1 && !text[0]) {
        makeDocReturn.value = emptyText();
    } else if(|text| <= 32){
        makeDocReturn.value = TextLeaf(text);
    } else {
        makeDocReturn.value = nodeFromChildren(leafsFromText(text));
    }
    return makeDocReturn;
}

//////////////// TEXT LEAF //////////////////////


// Leaves store an array of line strings. There are always line breaks
// between these strings. Leaves are limited in size and have to be
// contained in TextNode instances for bigger documents.
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

    // open: 1 => open from, 2 => open to
    method <> decompose <int from, int until, list<BaseText> target, int open>{
        var newText: TextLeaf;
        if(from <= 0 && until >= this->length){
            newText = this;
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

// Nodes provide the tree structure of the `Text` type. They store a
// number of other nodes or leaves, taking care to balance themselves
// on changes. There are implied line breaks _between_ the children of
// a node (but not before the first or after the last child).
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

////////////////// CHANGE SET ////////////////

class ChangeSet {
    method sections: vector<int>;
    method inserted: vector<BaseText>; 
    ctor <list<int> s, list<BaseText> l> sections(<vector<int>>(|s|)), inserted(<vector<BaseText>>(|l|)) {
        var iSections = @fwd s;
        var iInserted = @fwd l;
        for (var i = 0; i < |s|; i++){
            sections[i] = @elt iSections;
            iSections++;
        }
        for (var i = 0; i < |l|; i++){
            inserted[i] = @elt iInserted;
            iInserted++;
        }
    }

    // The length of the document before the change
    method <int> getLength <> {
        var result = 0;
        for (var iter = @fwd sections; iter; iter++){
            result += @elt iter;
            iter++;
        }
        return result;
    }

    // Apply the changes to a document, returning the modified document
    method <BaseText> apply <BaseText doc> {
        if(doc->length != getLength()){
            $stderr <:: "Applying change set to a document with the wrong length" <:: '\n';
        }
        var posA = 0;
        var posB = 0;
        for (var i = 0; i < |sections|;){
            var len = sections[i];
            i++;
            var ins = sections[i];
            i++;
            if(ins < 0){
                posA += len;
                posB += len;
            } else {
                var endA = posA;
                var endB = posB;
                var text = emptyText();
                for (;;) {
                    endA += len;
                    endB += ins;
                    if(ins && inserted){
                        text = text->append(inserted[(i-2) ~> 1]);
                    }
                    if(i == |sections| || sections[i + 1] < 0) break;
                    len = sections[i];
                    i++;
                    ins = sections[i];
                    i++;
                }
                doc = doc->replace(posB, posB + (endA - posA), text);

                posA = endA;
                posB = endB;
            }
        }
        return doc;
    }
}

function <ChangeSetJSONReturn> changeSetFromJSON <Changes json> {
    var sections: list<int>;
    var inserted: list<BaseText>;
    var i = 0;
    var error: string;
    var changeSet: ChangeSet;
    var changeSetJSONReturn: ChangeSetJSONReturn;

    if(!|json|){
        error = "There are no changes";
    }
 
    START: for(var iter = @fwd json; iter; iter++){
        var part = @elt iter;
        var changes = part.l;
        // untouched
        if(part.$type == "i"){
            sections ~> part.i ~> -1;
        // deletion
        } else if (part.$type == "l" && |changes| == 1 && changes[0].i){
            sections ~> changes[0].i ~> 0;
        // inserts/replace
        } else if(part.$type == "l") {
            while (|inserted| < i) inserted ~> emptyText();
            var text: Text;
            var skipHead = true;
            for(var iter = @fwd changes; iter; iter++){
                var str = @elt iter;
                if(skipHead){
                    skipHead = false;
                    continue;
                }
                if(!(str.s || str.s == "")){
                    error = "Invalid changes form";
                    break START;
                }
                text ~> str.s;
            }
            // ERR?: different
            inserted ~> makeDoc(text).value;
            if(!(changes[0].i || changes[0].i == 0)){
                error = "Invalid changes form";
                break START;
            }
            sections ~> changes[0].i ~> (@tail inserted)->length;
        } else {
            error = "Invalid changes form";
            break START;
        }
        i++;
    }
    if(error) {
        changeSet = ChangeSet(<list<int>>(), <list<BaseText>>());
    } else {
        changeSet = ChangeSet(sections, inserted);
    };
    changeSetJSONReturn = {
        changeSet,
        error
    };
    return changeSetJSONReturn;
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

function <Text> cloneSharedText <shared Text text> {
    var newText: Text;
    for var line in text do {
        newText ~> line;
    }
    return newText;
}

function <Updates> cloneSharedUpdates <shared Updates updates> {
    var newUpdates: Updates;
    for var update in updates do {
        var newUpdate: Update = {
            "connectionID": update.connectionID,
            "changes": cloneSharedChanges(update.changes)
        };
        newUpdates ~> newUpdate;
    }
    return newUpdates;
}

function <Changes> cloneSharedChanges <shared Changes changes> {
    var newChanges: Changes;
    for var change in changes do {
        var newChange: Change = {
            "i": change.i,
            "l": cloneSharedSubChanges(change.l)
        };
        newChanges ~> newChange;
    }
    return newChanges;
}

function <list<string $type, int i, string s>> cloneSharedSubChanges <shared list<string $type, int i, string s> l> {
    var newSubChanges: list<string $type, int i, string s>;
    for var subChange in l do {
        newSubChanges ~> subChange;
    }
    return newSubChanges;
}

/////////////// NODE /////////////////////

type Request = 
<
    string reqType,
    shared Text doc,
    string connectionID,
    string docID,
    int version,
    shared Updates updates
>;

type Response =
<
    string connectionID,
    string docID,
    string reqType,
    int statusCode,
    string message
>;

type Broadcast = 
<
    string docID,
    string message
>;

node Doc
{
  var s : trigger in<Request>;
  var broadcastT: trigger out<Broadcast>;
  var broadcast: Broadcast;
  var resT: trigger out<Response>;
  var res: Response;
  var req : Request;
  var docMap: map <string> to <BaseText>;
  var connectionMap: map <string> to <set<string>>;
  var updatesMap: map <string> to <list<DocUpdate>>;
  #meta menu "Collab"
  export ctor <trigger in<Request> subject, trigger out<Response> response, trigger out<Broadcast> broadcast> : s(subject), resT(response), broadcastT(broadcast) {}
  fire { 
    broadcast = {};
    res = {};
    req = <Request>(<::s);
    $stdout <:j: req <:: '\n'; 
    $stdout <:j: req.reqType == "push" && (req.version || req.version == 0) && req.docID && req.updates <:: '\n';
    res.connectionID = req.connectionID;
    res.docID = req.docID;
    res.reqType = req.reqType;
    // TODO: This is deep cloning (should optimize)
    var clonedText = cloneSharedText(req.doc);
    // creation
    if(req.reqType == "create" && req.doc && req.connectionID){
        var doc = makeDoc(clonedText);
        if(doc.error){
            res.statusCode = 400;
            res.message = doc.error;
        } else {
            var docId = $uuid_unparse($uuid());
            docMap[docId] = doc.value;
            updatesMap[docId] = <list<DocUpdate>>();
            connectionMap[docId] = {req.connectionID};
            res.statusCode = 200;
            res.message = docId;
        }
    } else if (req.reqType == "push" && (req.version || req.version == 0) && req.docID && req.updates){
        var doc = docMap(req.docID) \\ {};
        if(!doc){
            res.statusCode = 400;
            res.message = "No document found";
        } else if(req.version != |updatesMap(req.docID)|){
            res.statusCode = 409;
            res.message = "Incorrect document version";
        } else {
            res.statusCode = 200;
            res.message = "Changes pushed";
            var errorIndex = 0;
            // TODO: This is deep cloning (should optimize)
            var updates = cloneSharedUpdates(req.updates);
            var reqUpdates = cloneSharedUpdates(req.updates);
            START: for var update in reqUpdates do {
                var changeSetReturn = changeSetFromJSON(update.changes);
                var changeSet = changeSetReturn.value;
                var error = changeSetReturn.error;
                // TODO: This should probably revert any changes if there are any errors
                // Should not apply changes
                if(error){
                    res.statusCode = 400;
                    res.message = error;
                    updates = {};
                    var i = 0;
                    for (var uIter = @fwd reqUpdates; i < errorIndex; uIter++){
                        updates ~> @elt uIter;
                        i++;
                    }
                    break START;
                }
                var docUpdate: DocUpdate = {"changes": changeSet, "connectionID": update.connectionID};
                // TODO: revisit this (prob not the best way to do this)
                res.connectionID = update.connectionID;
                updatesMap(req.docID) ~> docUpdate;
                changeSet->apply(doc);
                errorIndex++;
            }
            if(|updates|) {
                broadcast = {
                    "docID": req.docID, 
                    "message": <string>(<stream[@utf8]>() <:j: updates)
                };
            }
        }
    } else if (req.reqType == "subscribe" && req.connectionID && req.docID) {
        var connectionSet = connectionMap(req.docID) \\ {};
        if(!connectionSet){
            res.statusCode = 400;
            res.message = "No document found";
        } else {
            connectionSet += req.connectionID;
            res.statusCode = 200;
            res.message = "Subscribed to " + req.docID;
        }
    } else {
        res.statusCode = 400;
        res.message = "Invalid message format";
    }
    if(!res.connectionID) res.connectionID = "unknown";
    if(!res.docID) res.docID = "unknown";
    if(!res.reqType) res.reqType = "unknown";
    resT <:: res;
    broadcastT <:: broadcast;
    return 1; 
    }
}

node LogResp {
    var s: trigger in<Response>;
    #meta menu "Collab"
    export ctor <trigger in<Response> subject> : s(subject){}
    fire {
        $stderr <:: "logResp: " <:K: (<::s) <:: '\n';
        return 1;
    }
}

node LogB {
    var b: trigger in<Broadcast>;
    #meta menu "Collab"
    export ctor <trigger in<Broadcast> broadcast>: b(broadcast){}
    fire {
        $stderr <:: "logB: " <:K: (<::b) <:: '\n';
        return 1;
    }
}

//////////////// TESTING NODE /////////////

type CreateRequest = 
<
    string reqType,
    shared Text doc,
    string connectionID
>;

node MakeCreateRequest {
    var t: trigger in <shared Text>;
    var cid: trigger in <string>;
    var o: trigger out <CreateRequest>;
    #meta menu "Collab"
    export ctor <
        trigger in<shared Text> text,
        trigger in<string> connectionID, 
        trigger out<CreateRequest> req 
        > : t(text), cid(connectionID), o(req) {} 
    fire {
        var text = <shared Text>(<::t);
        var connectionID = <string>(<::cid);
        var req: CreateRequest = {
            "reqType": "create",
            "connectionID": connectionID,
            "doc": text
        };
        o <:: req;
        return 1;
    }
}

node GetDocId {
    var i: trigger in <Response>;
    var b: trigger out <bool>;
    var o: trigger out <string>;
    var resp: Response;
    #meta menu "Collab"
    export ctor <trigger in<Response> input, trigger out<bool> isDoc, trigger out<string> output> : i(input), b(isDoc), o(output){}
    fire {
        resp = <Response>(<::i);
        var message = resp.message;
        o <:: resp.message;
        if($uuid_parse(message)){
            b <:: true;
        } else {
            b <:: false;
        }
        return 1;
    }
}

type PushRequest = 
<
    string reqType,
    string connectionID,
    string docID,
    int version,
    shared Updates updates
>;

node MakePushRequest {
    var cid: trigger in <string>;
    var did: trigger in <string>;
    var v: trigger in <int>;
    var u: trigger in <shared Updates>;
    var o: trigger out <PushRequest>;
    #meta menu "Collab"
    export ctor <
        trigger in<string> connectionID,
        trigger in<string> docID,
        trigger in<int> version,
        trigger in <shared Updates> updates,
        trigger out<PushRequest> output
    > : cid(connectionID), did(docID), v(version), u(updates), o(output) {}
    fire {
        var connectionID = <string>(<::cid);
        var docID = <string>(<::did);
        var version = <int>(<::v);
        var updates = <shared Updates>(<::u);
        var message: PushRequest = {
            "reqType": "push",
            "connectionID": connectionID,
            "docID": docID,
            "version": version,
            "updates": updates
        };
        o <:: message;
        return 1;
    }
}

node MakeChanges {
    var i: trigger in <string>;
    var o: trigger out <shared Changes>;
    #meta menu "Collab"
    export ctor <
        trigger in<string> input,
        trigger out<shared Changes> output
    >: i(input), o(output) {}
    fire {
        var changes = <shared Changes> <:j: <stream>(<::i);
        o <:: changes;
        return 1;
    }
}

node SubscribeNode {
    var d: trigger in <string>;
    var c: trigger in <string>;
    var m: trigger out<string>;
    #meta menu "Collab"
    export ctor <
        trigger in<string> docID,
        trigger in<string> connectionID,
        trigger out<string> message
    > : d(docID), c(connectionID), m(message) {}
    fire {
        var docID = <string>(<::d);
        var connectionID = <string>(<::c);
        var message = 
            "{reqType: \"subscribe\", docID: \"" + 
            docID + 
            "\", connectionID: \"" + 
            connectionID + "\"}";
        m <:: message;
        return 1;
    }
}