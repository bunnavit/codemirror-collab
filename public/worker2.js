class Text {
  /**
  @internal
  */
  constructor() {}

  /**
  Replace a range of the text with the given content.
  */
  replace(from, to, text) {
    let parts = [];
    this.decompose(0, from, parts, 2 /* Open.To */);
    if (text.length)
      text.decompose(
        0,
        text.length,
        parts,
        1 /* Open.From */ | 2 /* Open.To */
      );
    this.decompose(to, this.length, parts, 1 /* Open.From */);
    return TextNode.from(parts, this.length - (to - from) + text.length);
  }
  /**
  Append another document to this one.
  */
  append(other) {
    return this.replace(this.length, this.length, other);
  }

  /**
  @internal
  */
  toString() {
    return this.sliceString(0);
  }
  /**
    Create a `Text` instance for the given array of lines.
    */
  static of(text) {
    if (text.length == 0)
      throw new RangeError("A document must have at least one line");
    if (text.length == 1 && !text[0]) return Text.empty;
    return text.length <= 32 /* Tree.Branch */
      ? new TextLeaf(text)
      : TextNode.from(TextLeaf.split(text, []));
  }
}

class TextLeaf extends Text {
  constructor(text, length = textLength(text)) {
    super();
    this.text = text;
    this.length = length;
  }
  get lines() {
    return this.text.length;
  }
  get children() {
    return null;
  }
  decompose(from, to, target, open) {
    let text =
      from <= 0 && to >= this.length
        ? this
        : new TextLeaf(
            sliceText(this.text, from, to),
            Math.min(to, this.length) - Math.max(0, from)
          );
    if (open & 1 /* Open.From */) {
      let prev = target.pop();
      let joined = appendText(text.text, prev.text.slice(), 0, text.length);
      if (joined.length <= 32 /* Tree.Branch */) {
        target.push(new TextLeaf(joined, prev.length + text.length));
      } else {
        let mid = joined.length >> 1;
        target.push(
          new TextLeaf(joined.slice(0, mid)),
          new TextLeaf(joined.slice(mid))
        );
      }
    } else {
      target.push(text);
    }
  }
  flatten(target) {
    for (let line of this.text) target.push(line);
  }
  sliceString(from, to = this.length, lineSep = "\n") {
    let result = "";
    for (let pos = 0, i = 0; pos <= to && i < this.text.length; i++) {
      let line = this.text[i],
        end = pos + line.length;
      if (pos > from && i) result += lineSep;
      if (from < end && to > pos)
        result += line.slice(Math.max(0, from - pos), to - pos);
      pos = end + 1;
    }
    return result;
  }
  static split(text, target) {
    let part = [],
      len = -1;
    for (let line of text) {
      part.push(line);
      len += line.length + 1;
      if (part.length == 32 /* Tree.Branch */) {
        target.push(new TextLeaf(part, len));
        part = [];
        len = -1;
      }
    }
    if (len > -1) target.push(new TextLeaf(part, len));
    return target;
  }
}

// Nodes provide the tree structure of the `Text` type. They store a
// number of other nodes or leaves, taking care to balance themselves
// on changes. There are implied line breaks _between_ the children of
// a node (but not before the first or after the last child).
class TextNode extends Text {
  constructor(children, length) {
    super();
    this.children = children;
    this.length = length;
    this.lines = 0;
    for (let child of children) this.lines += child.lines;
  }
  static from(
    children,
    length = children.reduce((l, ch) => l + ch.length + 1, -1)
  ) {
    let lines = 0;
    for (let ch of children) lines += ch.lines;
    if (lines < 32 /* Tree.Branch */) {
      let flat = [];
      for (let ch of children) ch.flatten(flat);
      return new TextLeaf(flat, length);
    }
    let chunk = Math.max(
        32 /* Tree.Branch */,
        lines >> 5 /* Tree.BranchShift */
      ),
      maxChunk = chunk << 1,
      minChunk = chunk >> 1;
    let chunked = [],
      currentLines = 0,
      currentLen = -1,
      currentChunk = [];
    function add(child) {
      let last;
      if (child.lines > maxChunk && child instanceof TextNode) {
        for (let node of child.children) add(node);
      } else if (
        child.lines > minChunk &&
        (currentLines > minChunk || !currentLines)
      ) {
        flush();
        chunked.push(child);
      } else if (
        child instanceof TextLeaf &&
        currentLines &&
        (last = currentChunk[currentChunk.length - 1]) instanceof TextLeaf &&
        child.lines + last.lines <= 32 /* Tree.Branch */
      ) {
        currentLines += child.lines;
        currentLen += child.length + 1;
        currentChunk[currentChunk.length - 1] = new TextLeaf(
          last.text.concat(child.text),
          last.length + 1 + child.length
        );
      } else {
        if (currentLines + child.lines > chunk) flush();
        currentLines += child.lines;
        currentLen += child.length + 1;
        currentChunk.push(child);
      }
    }
    function flush() {
      if (currentLines == 0) return;
      chunked.push(
        currentChunk.length == 1
          ? currentChunk[0]
          : TextNode.from(currentChunk, currentLen)
      );
      currentLen = -1;
      currentLines = currentChunk.length = 0;
    }
    for (let child of children) add(child);
    flush();
    return chunked.length == 1 ? chunked[0] : new TextNode(chunked, length);
  }
}

////////////////////////////////////////////////
// Text functions
Text.empty = /*@__PURE__*/ new TextLeaf([""], 0);
function textLength(text) {
  let length = -1;
  for (let line of text) length += line.length + 1;
  return length;
}
function appendText(text, target, from = 0, to = 1e9) {
  for (let pos = 0, i = 0, first = true; i < text.length && pos <= to; i++) {
    let line = text[i],
      end = pos + line.length;
    if (end >= from) {
      if (end > to) line = line.slice(0, to - pos);
      if (pos < from) line = line.slice(from - pos);
      if (first) {
        target[target.length - 1] += line;
        first = false;
      } else target.push(line);
    }
    pos = end + 1;
  }
  return target;
}
function sliceText(text, from, to) {
  return appendText(text, [""], from, to);
}

/////////////////////////////////////////////////
/**
A change description is a variant of [change set](https://codemirror.net/6/docs/ref/#state.ChangeSet)
that doesn't store the inserted text. As such, it can't be
applied, but is cheaper to store and manipulate.
*/
class ChangeDesc {
  // Sections are encoded as pairs of integers. The first is the
  // length in the current document, and the second is -1 for
  // unaffected sections, and the length of the replacement content
  // otherwise. So an insertion would be (0, n>0), a deletion (n>0,
  // 0), and a replacement two positive numbers.
  /**
    @internal
    */
  constructor(
    /**
    @internal
    */
    sections
  ) {
    this.sections = sections;
  }
  /**
  The length of the document before the change.
  */
  get length() {
    let result = 0;
    for (let i = 0; i < this.sections.length; i += 2)
      result += this.sections[i];
    return result;
  }
  /**
  The length of the document after the change.
  */
  get newLength() {
    let result = 0;
    for (let i = 0; i < this.sections.length; i += 2) {
      let ins = this.sections[i + 1];
      result += ins < 0 ? this.sections[i] : ins;
    }
    return result;
  }
  /**
  False when there are actual changes in this set.
  */
  get empty() {
    return (
      this.sections.length == 0 ||
      (this.sections.length == 2 && this.sections[1] < 0)
    );
  }
  /**
  Get a description of the inverted form of these changes.
  */
  get invertedDesc() {
    let sections = [];
    for (let i = 0; i < this.sections.length; ) {
      let len = this.sections[i++],
        ins = this.sections[i++];
      if (ins < 0) sections.push(len, ins);
      else sections.push(ins, len);
    }
    return new ChangeDesc(sections);
  }
  /**
  @internal
  */
  static create(sections) {
    return new ChangeDesc(sections);
  }
}

/**
A change set represents a group of modifications to a document. It
stores the document length, and can only be applied to documents
with exactly that length.
*/
class ChangeSet extends ChangeDesc {
  constructor(
    sections,
    /**
    @internal
    */
    inserted
  ) {
    super(sections);
    this.inserted = inserted;
  }
  /**
  The length of the document before the change.
  */
  get length() {
    let result = 0;
    for (let i = 0; i < this.sections.length; i += 2)
      result += this.sections[i];
    return result;
  }
  /**
  Get a [change description](https://codemirror.net/6/docs/ref/#state.ChangeDesc) for this change
  set.
  */
  get desc() {
    return ChangeDesc.create(this.sections);
  }
  /**
  Apply the changes to a document, returning the modified
  document.
  */
  apply(doc) {
    console.log("this.length", this.length);
    if (this.length != doc.length)
      throw new RangeError(
        "Applying change set to a document with the wrong length"
      );
    iterChanges(
      this,
      (fromA, toA, fromB, _toB, text) =>
        (doc = doc.replace(fromB, fromB + (toA - fromA), text)),
      false
    );
    return doc;
  }

  /**
  Create a changeset from its JSON representation (as produced by
  [`toJSON`](https://codemirror.net/6/docs/ref/#state.ChangeSet.toJSON).
  */
  static fromJSON(json) {
    if (!Array.isArray(json))
      throw new RangeError("Invalid JSON representation of ChangeSet1");
    let sections = [],
      inserted = [];
    for (let i = 0; i < json.length; i++) {
      let part = json[i];
      if (typeof part == "number") {
        sections.push(part, -1);
      } else if (
        !Array.isArray(part) ||
        typeof part[0] != "number" ||
        part.some((e, i) => i && typeof e != "string")
      ) {
        throw new RangeError("Invalid JSON representation of ChangeSet2");
      } else if (part.length == 1) {
        sections.push(part[0], 0);
      } else {
        while (inserted.length < i) inserted.push(Text.empty);
        inserted[i] = Text.of(part.slice(1));
        sections.push(part[0], inserted[i].length);
      }
    }
    return new ChangeSet(sections, inserted);
  }
}

const iterChanges = (desc, f, individual) => {
  let inserted = desc.inserted;
  for (let posA = 0, posB = 0, i = 0; i < desc.sections.length; ) {
    let len = desc.sections[i++],
      ins = desc.sections[i++];
    if (ins < 0) {
      posA += len;
      posB += len;
    } else {
      let endA = posA,
        endB = posB,
        text = Text.empty;
      for (;;) {
        endA += len;
        endB += ins;
        if (ins && inserted) text = text.append(inserted[(i - 2) >> 1]);
        if (individual || i == desc.sections.length || desc.sections[i + 1] < 0)
          break;
        len = desc.sections[i++];
        ins = desc.sections[i++];
      }
      f(posA, endA, posB, endB, text);
      posA = endA;
      posB = endB;
    }
  }
};

// START

// @standalone

// The updates received so far (updates.length gives the current
// version)
var updates = [];
// The current document
var doc = Text.of(["hello"]);

//!authorityMessage
var pending = [];
// eslint-disable-next-line no-restricted-globals
self.onmessage = function (event) {
  function resp(value) {
    console.log("rsp", updates.slice(value));
    event.ports[0].postMessage(JSON.stringify(value));
  }
  var data = JSON.parse(event.data);

  if (data.type == "pullUpdates") {
    if (data.version < updates.length) resp(updates.slice(data.version));
    else pending.push(resp);
  } else if (data.type == "pushUpdates") {
    if (data.version != updates.length) {
      resp(false);
    } else {
      for (var _i = 0, _a = data.updates; _i < _a.length; _i++) {
        var update = _a[_i];
        // Convert the JSON representation to an actual ChangeSet
        // instance

        var changes = ChangeSet.fromJSON(update.changes);

        updates.push({ changes: changes, clientID: update.clientID });

        doc = changes.apply(doc);
      }
      resp(true);
      // Notify pending requests
      while (pending.length) pending.pop()(data.updates);
    }
  } else if (data.type == "getDocument") {
    resp({ version: updates.length, doc: doc.toString() });
  }
};
