/**
The data structure for documents. @nonabstract
*/
class Text {
  /**
    @internal
    */
  constructor() {}
  /**
    Get the line description around the given position.
    */
  lineAt(pos) {
    if (pos < 0 || pos > this.length)
      throw new RangeError(
        `Invalid position ${pos} in document of length ${this.length}`
      );
    return this.lineInner(pos, false, 1, 0);
  }
  /**
    Get the description for the given (1-based) line number.
    */
  line(n) {
    if (n < 1 || n > this.lines)
      throw new RangeError(
        `Invalid line number ${n} in ${this.lines}-line document`
      );
    return this.lineInner(n, true, 1, 0);
  }
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
    Retrieve the text between the given points.
    */
  slice(from, to = this.length) {
    let parts = [];
    this.decompose(from, to, parts, 0);
    return TextNode.from(parts, to - from);
  }

  /**
    @internal
    */
  toString() {
    return this.sliceString(0);
  }
  /**
    Convert the document to an array of lines (which can be
    deserialized again via [`Text.of`](https://codemirror.net/6/docs/ref/#state.Text^of)).
    */
  toJSON() {
    let lines = [];
    this.flatten(lines);
    return lines;
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

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Leaves store an array of line strings. There are always line breaks
// between these strings. Leaves are limited in size and have to be
// contained in TextNode instances for bigger documents.
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
  replace(from, to, text) {
    if (!(text instanceof TextLeaf)) return super.replace(from, to, text);
    let lines = appendText(
      this.text,
      appendText(text.text, sliceText(this.text, 0, from)),
      to
    );
    let newLen = this.length + text.length - (to - from);
    if (lines.length <= 32 /* Tree.Branch */)
      return new TextLeaf(lines, newLen);
    return TextNode.from(TextLeaf.split(lines, []), newLen);
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
  flatten(target) {
    for (let line of this.text) target.push(line);
  }
  scanIdentical() {
    return 0;
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
  lineInner(target, isLine, line, offset) {
    for (let i = 0; ; i++) {
      let child = this.children[i],
        end = offset + child.length,
        endLine = line + child.lines - 1;
      if ((isLine ? endLine : end) >= target)
        return child.lineInner(target, isLine, line, offset);
      offset = end + 1;
      line = endLine + 1;
    }
  }
  decompose(from, to, target, open) {
    for (let i = 0, pos = 0; pos <= to && i < this.children.length; i++) {
      let child = this.children[i],
        end = pos + child.length;
      if (from <= end && to >= pos) {
        let childOpen =
          open &
          ((pos <= from ? 1 /* Open.From */ : 0) |
            (end >= to ? 2 /* Open.To */ : 0));
        if (pos >= from && end <= to && !childOpen) target.push(child);
        else child.decompose(from - pos, to - pos, target, childOpen);
      }
      pos = end + 1;
    }
  }
  replace(from, to, text) {
    if (text.lines < this.lines)
      for (let i = 0, pos = 0; i < this.children.length; i++) {
        let child = this.children[i],
          end = pos + child.length;
        // Fast path: if the change only affects one child and the
        // child's size remains in the acceptable range, only update
        // that child
        if (from >= pos && to <= end) {
          let updated = child.replace(from - pos, to - pos, text);
          let totalLines = this.lines - child.lines + updated.lines;
          if (
            updated.lines < totalLines >> (5 /* Tree.BranchShift */ - 1) &&
            updated.lines > totalLines >> (5 /* Tree.BranchShift */ + 1)
          ) {
            let copy = this.children.slice();
            copy[i] = updated;
            return new TextNode(copy, this.length - (to - from) + text.length);
          }
          return super.replace(pos, end, updated);
        }
        pos = end + 1;
      }
    return super.replace(from, to, text);
  }
  sliceString(from, to = this.length, lineSep = "\n") {
    let result = "";
    for (let i = 0, pos = 0; i < this.children.length && pos <= to; i++) {
      let child = this.children[i],
        end = pos + child.length;
      if (pos > from && i) result += lineSep;
      if (from < end && to > pos)
        result += child.sliceString(from - pos, to - pos, lineSep);
      pos = end + 1;
    }
    return result;
  }
  flatten(target) {
    for (let child of this.children) child.flatten(target);
  }
  scanIdentical(other, dir) {
    if (!(other instanceof TextNode)) return 0;
    let length = 0;
    let [iA, iB, eA, eB] =
      dir > 0
        ? [0, 0, this.children.length, other.children.length]
        : [this.children.length - 1, other.children.length - 1, -1, -1];
    for (; ; iA += dir, iB += dir) {
      if (iA == eA || iB == eB) return length;
      let chA = this.children[iA],
        chB = other.children[iB];
      if (chA != chB) return length + chA.scanIdentical(chB, dir);
      length += chA.length + 1;
    }
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

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
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

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

const DefaultSplit = /\r\n?|\n/;
/**
  Distinguishes different ways in which positions can be mapped.
  */
var MapMode = /*@__PURE__*/ (function (MapMode) {
  /**
      Map a position to a valid new position, even when its context
      was deleted.
      */
  MapMode[(MapMode["Simple"] = 0)] = "Simple";
  /**
      Return null if deletion happens across the position.
      */
  MapMode[(MapMode["TrackDel"] = 1)] = "TrackDel";
  /**
      Return null if the character _before_ the position is deleted.
      */
  MapMode[(MapMode["TrackBefore"] = 2)] = "TrackBefore";
  /**
      Return null if the character _after_ the position is deleted.
      */
  MapMode[(MapMode["TrackAfter"] = 3)] = "TrackAfter";
  return MapMode;
})(MapMode || (MapMode = {}));
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
    Iterate over the unchanged parts left by these changes. `posA`
    provides the position of the range in the old document, `posB`
    the new position in the changed document.
    */
  iterGaps(f) {
    for (let i = 0, posA = 0, posB = 0; i < this.sections.length; ) {
      let len = this.sections[i++],
        ins = this.sections[i++];
      if (ins < 0) {
        f(posA, posB, len);
        posB += len;
      } else {
        posB += ins;
      }
      posA += len;
    }
  }
  /**
    Iterate over the ranges changed by these changes. (See
    [`ChangeSet.iterChanges`](https://codemirror.net/6/docs/ref/#state.ChangeSet.iterChanges) for a
    variant that also provides you with the inserted text.)
    `fromA`/`toA` provides the extent of the change in the starting
    document, `fromB`/`toB` the extent of the replacement in the
    changed document.
    
    When `individual` is true, adjacent changes (which are kept
    separate for [position mapping](https://codemirror.net/6/docs/ref/#state.ChangeDesc.mapPos)) are
    reported separately.
    */
  iterChangedRanges(f, individual = false) {
    iterChanges(this, f, individual);
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

  mapPos(pos, assoc = -1, mode = MapMode.Simple) {
    let posA = 0,
      posB = 0;
    for (let i = 0; i < this.sections.length; ) {
      let len = this.sections[i++],
        ins = this.sections[i++],
        endA = posA + len;
      if (ins < 0) {
        if (endA > pos) return posB + (pos - posA);
        posB += len;
      } else {
        if (
          mode != MapMode.Simple &&
          endA >= pos &&
          ((mode == MapMode.TrackDel && posA < pos && endA > pos) ||
            (mode == MapMode.TrackBefore && posA < pos) ||
            (mode == MapMode.TrackAfter && endA > pos))
        )
          return null;
        if (endA > pos || (endA == pos && assoc < 0 && !len))
          return pos == posA || assoc < 0 ? posB : posB + ins;
        posB += ins;
      }
      posA = endA;
    }
    if (pos > posA)
      throw new RangeError(
        `Position ${pos} is out of range for changeset of length ${posA}`
      );
    return posB;
  }
  /**
    Check whether these changes touch a given range. When one of the
    changes entirely covers the range, the string `"cover"` is
    returned.
    */
  touchesRange(from, to = from) {
    for (let i = 0, pos = 0; i < this.sections.length && pos <= to; ) {
      let len = this.sections[i++],
        ins = this.sections[i++],
        end = pos + len;
      if (ins >= 0 && pos <= to && end >= from)
        return pos < from && end > to ? "cover" : true;
      pos = end;
    }
    return false;
  }
  /**
    @internal
    */
  toString() {
    let result = "";
    for (let i = 0; i < this.sections.length; ) {
      let len = this.sections[i++],
        ins = this.sections[i++];
      result += (result ? " " : "") + len + (ins >= 0 ? ":" + ins : "");
    }
    return result;
  }
  /**
    Serialize this change desc to a JSON-representable value.
    */
  toJSON() {
    return this.sections;
  }
  /**
    Create a change desc from its JSON representation (as produced
    by [`toJSON`](https://codemirror.net/6/docs/ref/#state.ChangeDesc.toJSON).
    */
  static fromJSON(json) {
    if (
      !Array.isArray(json) ||
      json.length % 2 ||
      json.some((a) => typeof a != "number")
    )
      throw new RangeError("Invalid JSON representation of ChangeDesc");
    return new ChangeDesc(json);
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
    Apply the changes to a document, returning the modified
    document.
    */
  apply(doc) {
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
    Given the document as it existed _before_ the changes, return a
    change set that represents the inverse of this set, which could
    be used to go from the document created by the changes back to
    the document as it existed before the changes.
    */
  invert(doc) {
    let sections = this.sections.slice(),
      inserted = [];
    for (let i = 0, pos = 0; i < sections.length; i += 2) {
      let len = sections[i],
        ins = sections[i + 1];
      if (ins >= 0) {
        sections[i] = ins;
        sections[i + 1] = len;
        let index = i >> 1;
        while (inserted.length < index) inserted.push(Text.empty);
        inserted.push(len ? doc.slice(pos, pos + len) : Text.empty);
      }
      pos += len;
    }
    return new ChangeSet(sections, inserted);
  }

  /**
    Iterate over the changed ranges in the document, calling `f` for
    each, with the range in the original document (`fromA`-`toA`)
    and the range that replaces it in the new document
    (`fromB`-`toB`).
    
    When `individual` is true, adjacent changes are reported
    separately.
    */
  iterChanges(f, individual = false) {
    iterChanges(this, f, individual);
  }
  /**
    Get a [change description](https://codemirror.net/6/docs/ref/#state.ChangeDesc) for this change
    set.
    */
  get desc() {
    return ChangeDesc.create(this.sections);
  }

  /**
    Serialize this change set to a JSON-representable value.
    */
  toJSON() {
    let parts = [];
    for (let i = 0; i < this.sections.length; i += 2) {
      let len = this.sections[i],
        ins = this.sections[i + 1];
      if (ins < 0) parts.push(len);
      else if (ins == 0) parts.push([len]);
      else parts.push([len].concat(this.inserted[i >> 1].toJSON()));
    }
    return parts;
  }
  /**
    Create a change set for the given changes, for a document of the
    given length, using `lineSep` as line separator.
    */
  static of(changes, length, lineSep) {
    let sections = [],
      inserted = [],
      pos = 0;
    let total = null;
    function flush(force = false) {
      if (!force && !sections.length) return;
      if (pos < length) addSection(sections, length - pos, -1);
      let set = new ChangeSet(sections, inserted);
      total = total ? total.compose(set.map(total)) : set;
      sections = [];
      inserted = [];
      pos = 0;
    }
    function process(spec) {
      if (Array.isArray(spec)) {
        for (let sub of spec) process(sub);
      } else if (spec instanceof ChangeSet) {
        if (spec.length != length)
          throw new RangeError(
            `Mismatched change set length (got ${spec.length}, expected ${length})`
          );
        flush();
        total = total ? total.compose(spec.map(total)) : spec;
      } else {
        let { from, to = from, insert } = spec;
        if (from > to || from < 0 || to > length)
          throw new RangeError(
            `Invalid change range ${from} to ${to} (in doc of length ${length})`
          );
        let insText = !insert
          ? Text.empty
          : typeof insert == "string"
          ? Text.of(insert.split(lineSep || DefaultSplit))
          : insert;
        let insLen = insText.length;
        if (from == to && insLen == 0) return;
        if (from < pos) flush();
        if (from > pos) addSection(sections, from - pos, -1);
        addSection(sections, to - from, insLen);
        addInsert(inserted, sections, insText);
        pos = to;
      }
    }
    process(changes);
    flush(!total);
    return total;
  }
  /**
    Create an empty changeset of the given length.
    */
  static empty(length) {
    return new ChangeSet(length ? [length, -1] : [], []);
  }
  /**
    Create a changeset from its JSON representation (as produced by
    [`toJSON`](https://codemirror.net/6/docs/ref/#state.ChangeSet.toJSON).
    */
  static fromJSON(json) {
    if (!Array.isArray(json))
      throw new RangeError("Invalid JSON representation of ChangeSet");
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
        throw new RangeError("Invalid JSON representation of ChangeSet");
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
  /**
    @internal
    */
  static createSet(sections, inserted) {
    return new ChangeSet(sections, inserted);
  }
}

////// functions

function addSection(sections, len, ins, forceJoin = false) {
  if (len == 0 && ins <= 0) return;
  let last = sections.length - 2;
  if (last >= 0 && ins <= 0 && ins == sections[last + 1]) sections[last] += len;
  else if (len == 0 && sections[last] == 0) sections[last + 1] += ins;
  else if (forceJoin) {
    sections[last] += len;
    sections[last + 1] += ins;
  } else sections.push(len, ins);
}
function addInsert(values, sections, value) {
  if (value.length == 0) return;
  let index = (sections.length - 2) >> 1;
  if (index < values.length) {
    values[values.length - 1] = values[values.length - 1].append(value);
  } else {
    while (values.length < index) values.push(Text.empty);
    values.push(value);
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

//////////////////////////////////////////////////////////////////////////////////
// START

// @standalone

// The updates received so far (updates.length gives the current
// version)
var updates = [];
// The current document
var doc = Text.of([""]);

//!authorityMessage
var pending = [];
// eslint-disable-next-line no-restricted-globals
self.onmessage = function (event) {
  function resp(value) {
    event.ports[0].postMessage(JSON.stringify(value));
  }
  var data = JSON.parse(event.data);

  console.log(data);

  if (data.type == "pullUpdates") {
    console.log("beforepull1", updates.slice(data.version));
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

const iterChanges2 = (desc, f, individual) => {
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
        text = EMPTY_TEXT;
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

Text.empty = /*@__PURE__*/ new TextLeaf([""], 0);
const EMPTY_TEXT = { text: [""], length: 0 };
