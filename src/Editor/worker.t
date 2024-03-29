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

type ChangeSetApplyReturn =
<
    BaseText value,
    string error
>;

type MakeDocReturn =
<
    BaseText value,
    string error
>;

export type Updates = list<Update>;
export type Update = 
<
    string connectionID,
    Changes changes
>;

export type Changes = list<Change>;
export type Change = 
<
    string $type,
    int i, 
    list<string $type, int i, string s> l
>;

export type DocUpdate = 
<
    string connectionID,
    ChangeSet changes
>;

class BaseText {
    method length: int;
    ctor <> {}
    method <int> getLines <>;
    method <list<BaseText>> getChildren <>;
    method <Text> getText <>;
    method <bool> isLeaf <>;
    method <> decompose <int from, int until, list<BaseText> target, int open>;
    method <string> sliceString <int from>;
    method <string> sliceString <int from, int until, string lineSep>;
    method <> flatten <Text target>;

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

    method <string> toString <> {
        return this->sliceString(0);
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
    method <ChangeSetApplyReturn> apply <BaseText doc> {
        if(doc->length != getLength()){
            return {doc, "Applying change set to a document with the wrong length"};
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
        return {doc , ""};
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
    var cloneStr = <string>(<stream[@utf8]>() <:j: updates);
    var newUpdates = <Updates> <:j: <stream>(cloneStr);
    return newUpdates;
}

function <set<string>> cloneStringSet <set<string> strSet> {
    var newSet: <set<string>>;
    for var str in strSet do {
        newSet += str;
    }
    return newSet;
}

/////////////// NODE /////////////////////

export type Request = 
<
    string reqType,
    shared Text doc,
    string connectionID,
    string docID,
    int version,
    shared Updates updates
>;

export type Response =
<
    string connectionID,
    string docID,
    string reqType,
    int statusCode,
    string message,
    string doc,
    int version
>;

export type Broadcast = 
<
    string docID,
    string updates,
    shared set<string> connectionSet
>;

export type CreateRequest = 
<
    string reqType,
    shared Text doc,
    string connectionID
>;

export type SubscribeRequest = 
<
    string reqType,
    string connectionID,
    string docID
>;

export type PushRequest = 
<
    string reqType,
    string connectionID,
    string docID,
    int version,
    shared Updates updates
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
    res.connectionID = req.connectionID;
    res.docID = req.docID;
    res.reqType = req.reqType;

    var connectionSet = connectionMap(req.docID) \\ {};
    var updates = updatesMap(req.docID) \\ {};
    var doc = docMap(req.docID) \\ {};
    
    // creation
    if(req.reqType == "create" && req.doc && req.connectionID){
        // TODO: This is deep cloning (should optimize)
        var clonedText = cloneSharedText(req.doc);
        var newDoc = makeDoc(clonedText);
        if(newDoc.error){
            res.statusCode = 400;
            res.message = newDoc.error;
        } else {
            var docID = $uuid_unparse($uuid());
            docMap[docID] = newDoc.value;
            updatesMap[docID] = <list<DocUpdate>>();
            connectionMap[docID] = {req.connectionID};
            res.statusCode = 200;
            res.docID = docID;
            res.message = "Created document";
        }
    } else if (
            req.reqType == "push" && 
            req.version >= 0 && 
            req.docID && req.updates &&
            req.connectionID
        ){
        if(!doc){
            res.statusCode = 400;
            res.message = "No document found";
        } else if(req.version != |updates|){
            res.statusCode = 409;
            res.message = "Incorrect document version";
        } else {
            res.statusCode = 200;
            res.message = "Changes pushed";
            var errorIndex = 0;
            // TODO: This is deep cloning (should optimize)
            var newUpdates = cloneSharedUpdates(req.updates);
            var reqUpdates = cloneSharedUpdates(req.updates);
            START: for var update in reqUpdates do {
                var changeSetReturn = changeSetFromJSON(update.changes);
                var changeSet = changeSetReturn.value;
                var error = changeSetReturn.error;
                var applyError = (changeSet->apply(doc)).error;
                // TODO: This should probably revert any changes if there are any errors
                // Should not apply changes
                if(error || applyError){
                    res.statusCode = 400;
                    res.message = error;
                    newUpdates = {};
                    var i = 0;
                    for (var uIter = @fwd reqUpdates; i < errorIndex; uIter++){
                        newUpdates ~> @elt uIter;
                        i++;
                    }
                    break START;
                }
                var docUpdate: DocUpdate = {"changes": changeSet, "connectionID": update.connectionID};
                updates ~> docUpdate;
                errorIndex++;
            }
            if(|newUpdates|) {
                broadcast = {
                    "docID": req.docID, 
                    "updates": <string>(<stream[@utf8]>() <:j: newUpdates),
                    "connectionSet": share cloneStringSet(connectionSet)
                };
            }
        }
    } else if (req.reqType == "subscribe" && req.connectionID && req.docID) {
        if(!connectionSet || !(|updates| >= 0) || !doc){
            res.statusCode = 400;
            res.message = "No document found";
        } else {
            connectionSet += req.connectionID;
            res.statusCode = 200;
            res.message = "Subscribed to " + req.docID;
            res.doc = doc->toString();
            res.version = |updates|;
        }
    } else if (req.reqType == "disconnect" && req.connectionID && req.docID){
        if(!connectionSet){
            res.statusCode = 400;
            res.message = "No document found";
        } else {
            connectionSet -= req.connectionID;
            res.statusCode = 200;
            res.message = "Disconnected from " + req.docID;
        }
    } else {
        res.statusCode = 400;
        res.message = "Invalid message format";
    }
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

node StringToDocRequest {
    var i: trigger in<string>;
    var o: trigger out<Request>;
    #meta menu "Collab"
    export ctor <
        trigger in<string> input,
        trigger out<Request> req
    >: i(input), o(req) {}
    fire {
        o <:: <Request> <:j: <stream>(<::i);
        return 1;
    }
}

node DocResponseToString {
    var i: trigger in<Response>;
    var o: trigger out<string>;
    #meta menu "Collab"
    export ctor <
        trigger in<Response> input,
        trigger out<string> output
    >: i(input), o(output) {}
    fire {
        o <:: <string>(<stream[@utf8]>() <:j: (<::i));
        return 1;
    }
}

node DocBroadcastToString {
    var i: trigger in<Broadcast>;
    var o: trigger out<string>;
    #meta menu "Collab"
    export ctor <
        trigger in<Broadcast> input,
        trigger out<string> output
    >: i(input), o(output) {}
    fire {
        o <:: <string>(<stream[@utf8]>() <:j: (<::i));
        return 1;
    }
}


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
        o <:: resp.docID;
        if($uuid_parse(resp.docID) && resp.reqType == "create"){
            b <:: true;
        } else {
            b <:: false;
        }
        return 1;
    }
}

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

node echoif
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


//////////////// MAIN //////////////////////

entry <int> main <> {
    testing();

    // generateInput(10000);
    
    // node testing
    var $Response: wire<Response>[32];
    var $Broadcast: wire<Broadcast>[32];
    var $DocInput: wire<string>[3];
    var $DocID: wire<string>[3];
    var $CheckDocID: wire<string>;
    var $IsDoc: wire<bool>[3];
    var $ConnectionID: wire<string>;

    // constant stream
    (out $ConnectionID) <:: <string>("bob");
    
    // create test
    (out $DocInput) <:: "{\"reqType\": \"create\", \"doc\" : [\"text1\", \"text2\", \"text3\"],\"connectionID\": \"bob\"}";

    // invalid test
    (out $DocInput) <:: "{test: \"test\"}";
    
    // node Doc(trigger in $DocInput, trigger out $Response, trigger out $Broadcast);
    // node GetDocId(trigger in $Response, trigger out $CheckDocID, trigger out $IsDoc);

    // node echoif(trigger in $IsDoc, trigger in $CheckDocID, trigger out $DocID);
    // node PushNode(trigger in $DocID, trigger out $DocInput);

    // node SubscribeNode(trigger in $DocID, trigger in $ConnectionID, trigger out $DocInput);

    // node LogResp(trigger in $Response);
    node LogB(trigger in $Broadcast);

    fork $numcores();
    return 0;
}



/////////////// TESTING ////////////////////

function <> testing <> {
    sigTest();
    utilTest();
    baseTextTest();
    textLeafTest();
    textNodeTest();
    changeSetTest();
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
    function <> makeDocError <> {
        var text = <Text>();
        assert(makeDoc(text).error);
        assert(makeDoc(text).value == <BaseText>());
    }
    function <> makeDocTest <> {
        var text = [""];
        var doc = makeDoc(text).value;
        assert(doc->isLeaf());
        assertListEq(doc->getText(), text);

        text = generateText(3);
        doc = makeDoc(text).value;
        assert(doc->isLeaf());
        assert(|doc->getChildren()| == 0);
        assert(doc->getLines() == 3);
        assert(doc->length == 17);
        assertListEq(doc->getText(), text); 

        text = generateText(34);
        doc = makeDoc(text).value;
        assert(!doc->isLeaf());
        assert(|doc->getChildren()| == 2);
        assert(doc->getLines() == 34);
        assert(doc->length == 228);
        var leaf2 = doc->getChildren()[1];
        assert(leaf2->isLeaf());
        var expectedText = ["text33", "text34"];
        assertListEq(leaf2->getText(), expectedText);

        text = generateText(100_000);
        doc = makeDoc(text).value;
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
    makeDocError();
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

function <> changeSetTest <> {
    function <> changeSetFromJSONError <> {
        var test = "[]";
        var changes = <Changes> <:j: <stream>(test);
        var error = changeSetFromJSON(changes).error;
        assert(error);

        var test2 = "[\"test\",2,3,4]";
        changes = <Changes> <:j: <stream>(test2);
        error = changeSetFromJSON(changes).error;
        assert(error);
    }
    // delete 23 characters from start of document
    function <> changeSetFromJSONTestDelete <> {
        var test = "[[23], 208]";
        var changes = <Changes> <:j: <stream>(test);
        var changeSet = changeSetFromJSON(changes).value;
        var expectedSections = [ 23, 0, 208, -1];
        assertListEq(expectedSections, vecToList(changeSet->sections));
        assert(|changeSet->inserted| == 0);
    }
    // insert multiple lines at start of document
    function <> changeSetFromJSONTestInsert1 <> {
        var test = "[[0, \"text1\", \"text2\", \"text3\", \"text4\"], 228]";
        var changes = <Changes> <:j: <stream>(test);
        var changeSet = changeSetFromJSON(changes).value;
        var expectedSections = [0, 23, 228, -1];
        assertListEq(expectedSections, vecToList(changeSet->sections));
        var inserted = changeSet->inserted;
        assert(|inserted| == 1);
        var leaf: TextLeaf = inserted[0];
        assert(leaf->length == 23);
        assert(leaf->getLines() == 4);
        assertListEq(leaf->getText(), generateText(4));
    }
    // insert multiple lines at the end of document
    function <> changeSetFromJSONTestInsert2 <> {
        var test = "[228, [0, \"\", \"text1\", \"text2\", \"text3\", \"text4\"]]";
        var changes = <Changes> <:j: <stream>(test);
        var changeSet = changeSetFromJSON(changes).value;
        var expectedSections = [228, -1, 0, 24];
        assertListEq(expectedSections, vecToList(changeSet->sections));
        var inserted = changeSet->inserted;
        assert(|inserted| == 2);
        var emptyLeaf: TextLeaf = inserted[0];
        assertListEq(emptyLeaf->getText(), [""]);
        var leaf: TextLeaf = inserted[1];
        assertListEq(leaf->getText(), [""] ~> generateText(4));
    }   
    // insert "a" in three places at the same time
    function <> changeSetFromJSONTestInsert3 <> {
        var test = "[74, [0, \"a\"], 28, [0, \"a\"], 28, [0, \"a\"], 98]";
        var changes = <Changes> <:j: <stream>(test);
        var changeSet = changeSetFromJSON(changes).value;
        var expectedSections = [74, -1, 0, 1, 28, -1, 0, 1, 28, -1, 0, 1, 98, -1];
        assertListEq(expectedSections, vecToList(changeSet->sections));
        assert(|changeSet->inserted| == 6);
        var i = 0;
        for var leaf in changeSet->inserted do {
            if(i%2 == 0){
                assert(leaf->length == 0);
                assert(leaf->getText()[0] == "");
            } else {
                assert(leaf->length == 1);
                assert(leaf->getText()[0] == "a");
            }
            i++;
        }
    }
    // replace section with chunk of text
    function <> changeSetFromJSONTestReplace <> {
        // TODO should make a func that generates text input
    }
    // delete 26 lines at the start of document
    function <> changeSetTestApply1 <> {
        var doc = makeDoc(generateText(40)).value;
        var test = "[[26], 244]";
        var changes = <Changes> <:j: <stream>(test);
        var changeSet = changeSetFromJSON(changes).value;
        doc = (changeSet->apply(doc)).value;
        var children = doc->getChildren();
        assert(|children| == 2);
        var expectedText1 = generateText(32);
        for (var i = 0; i < 5; i++) @pop expectedText1;
        expectedText1 = ["xt5"] ~> expectedText1;
        assertListEq(expectedText1, children[0]->getText());
    }
    // delete lines and convert from node to leaf when small enough
    function <> changeSetTestApply2 <> {
        var doc = makeDoc(generateText(34)).value;
        assert(!doc->isLeaf());
        var test = "[[26], 202]";
        var changes = <Changes> <:j: <stream>(test);
        var changeSet = changeSetFromJSON(changes).value;
        doc = (changeSet->apply(doc)).value;
        assert(doc->isLeaf());
        var expectedText = generateText(34);
        for (var i = 0; i < 5; i++) @pop expectedText;
        expectedText = ["xt5"] ~> expectedText;
        assertListEq(expectedText, doc->getText());
    }
    // insert and apply multiple lines at the end of doc
    function <> changeSetTestApply3 <> {
        var doc = makeDoc(generateText(34)).value;
        var test = "[228, [0, \"\", \"text1\", \"text2\", \"text3\", \"text4\"]]";
        var changes = <Changes> <:j: <stream>(test);
        var changeSet = changeSetFromJSON(changes).value;
        doc = (changeSet->apply(doc)).value;
        assert(|doc->getChildren()| == 2);
        assertListEq(doc->getChildren()[0]->getText(), generateText(32));
        assertListEq(doc->getChildren()[1]->getText(), ["text33", "text34"] ~> generateText(4));
    }
    // replacement of text
    function <> changeSetTestApply4 <> {
        var doc = makeDoc(generateText(34)).value;
        var test = "[89, [34, \"text20\", \"text21\", \"text22\", \"text23\"], 105]";
        var changes = <Changes> <:j: <stream>(test);
        var changeSet = changeSetFromJSON(changes).value;
        doc = (changeSet->apply(doc)).value;
        assert(|doc->getChildren()| == 2);
        var leaf1 = doc->getChildren()[0];
        var expectedText = generateText(14) ~> generateText(20, 23) ~> generateText(20, 32);
        assertListEq(leaf1->getText(), expectedText);
        var leaf2 = doc->getChildren()[1];
        assertListEq(leaf2->getText(), generateText(33, 34));
    }
    changeSetFromJSONError();
    changeSetFromJSONTestDelete();
    changeSetFromJSONTestInsert1();
    changeSetFromJSONTestInsert2();
    changeSetFromJSONTestInsert3();
    changeSetFromJSONTestReplace();
    changeSetTestApply1();
    changeSetTestApply2();
    changeSetTestApply3();
    changeSetTestApply4();
}

///////////////////// TEST UTILS ///////////////////

function <list<string>> vecToList <vector<string> a> {
    var l: list<string>;
    for var x in a do {
        l ~> x;
    }
    return l;
}

function <list<int>> vecToList <vector<int> a> {
    var l: list<int>;
    for var x in a do {
        l ~> x;
    }
    return l;
}

function <> assertListEq <list<string> a, list<string> b> {
    assert (|a| == |b|);
    var bIter = @fwd b;
    for (var aIter = @fwd a; aIter; aIter ++){
        assert(@elt aIter == @elt bIter);
        bIter++;
    }
}

function <> assertListEq <list<int> a, list<int> b> {
    assert (|a| == |b|);
    var bIter = @fwd b;
    for (var aIter = @fwd a; aIter; aIter ++){
        assert(@elt aIter == @elt bIter);
        bIter++;
    }
}

function <Text> generateText <int count> {
    return generateText(1, count);
}

function <Text> generateText <int from, int until> {
    var text: Text;
    for (var i = from; i <= until; i++){
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

