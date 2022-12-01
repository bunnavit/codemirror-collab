import { describe, expect, test } from "@jest/globals";
import { TextLeaf, Text } from "./worker";

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
});
