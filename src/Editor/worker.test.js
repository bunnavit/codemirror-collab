import { describe, expect, test } from "@jest/globals";
import { TextLeaf, Text, appendText, textLength, sliceText } from "./worker";

describe("test describe", () => {
  test("testlol", () => {
    expect(3).toBe(3);
  });
});

describe("Text", () => {
  test("noLine", () => {
    const noLine = () => {
      const doc = Text.of([]);
    };
    expect(noLine).toThrow(RangeError);
  });
  test("emptyText", () => {
    const doc = Text.of([""]);
    expect(doc.text.length).toBe(1);
    expect(doc.length).toBe(0);
  });
});

describe("TextLeaf", () => {
  test("emptyText", () => {
    const emptyText = new TextLeaf([""], 0);
    expect(emptyText.text.length).toBe(1);
    expect(emptyText.length).toBe(0);
  });

  test("Text.of creates TextLeaf", () => {
    const doc = Text.of(["some text"]);
    expect(doc.text.length).toBe(1);
    expect(doc.length).toBe(9);
  });

  test("sliceString", () => {
    var textLeaf = new TextLeaf(["first", "second", "third"], 18);
    var text = textLeaf.sliceString(6);
    expect(text).toBe("second\nthird");
    text = textLeaf.sliceString(6, 12, "\n");
    expect(text).toBe("second");
  });
});

describe("Utilities", () => {
  test("appendText", () => {
    var text = ["first", "second", "third"];
    var target = ["target1", "target2"];
    appendText(text, target, 0, 1e9);
    expect(target).toEqual(["target1", "target2first", "second", "third"]);
  });
  test("textLength", () => {
    var text = ["first", "second", "third"];
    var length = textLength(text);
    expect(length).toEqual(18);
  });
  test("sliceText", () => {
    var text = ["first", "second", "third"];
    var slicedText = sliceText(text, 0, 1e9);
    expect(slicedText).toEqual(text);
  });
});
