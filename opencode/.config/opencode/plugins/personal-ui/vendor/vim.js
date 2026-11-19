// @bun
// src/tui.tsx
import { createComponent as _$createComponent } from "@opentui/solid";
import { effect as _$effect } from "@opentui/solid";
import { insertNode as _$insertNode } from "@opentui/solid";
import { insert as _$insert } from "@opentui/solid";
import { memo as _$memo } from "@opentui/solid";
import { use as _$use } from "@opentui/solid";
import { setProp as _$setProp } from "@opentui/solid";
import { createElement as _$createElement } from "@opentui/solid";
import { Plugin } from "@opencode/plugin/tui";
import { TextAttributes } from "@opentui/core";
import { createEffect as createEffect2, createRoot, createSignal as createSignal2, onCleanup, onMount } from "solid-js";

// src/prompt-vim.ts
import { AsyncLocalStorage } from "async_hooks";
import { spawnSync } from "child_process";
import { CliRenderEvents, RGBA } from "@opentui/core";

// src/vim/scroll.ts
function vimScroll(event) {
  if (!event.ctrl || event.meta || event.super)
    return;
  const key = event.name ?? "";
  if (key === "e")
    return "line-down";
  if (key === "y")
    return "line-up";
  if (key === "d")
    return "half-down";
  if (key === "u")
    return "half-up";
  if (key === "f")
    return "page-down";
  if (key === "b")
    return "page-up";
  return;
}

// src/vim/jump.ts
function vimJump(event, state) {
  const key = event.name ?? "";
  const hasModifier = !!event.ctrl || !!event.meta || !!event.super;
  if (hasModifier) {
    if (state.pending() === "g")
      state.clearPending();
    return { handled: false };
  }
  if (key === "G" || key === "g" && event.shift) {
    state.clearPending();
    return { action: "bottom", handled: true };
  }
  if (key !== "g") {
    if (state.pending() === "g")
      state.clearPending();
    return { handled: false };
  }
  if (state.pending() === "g") {
    state.clearPending();
    return { action: "top", handled: true };
  }
  const count = typeof state.count === "function" ? state.count() : "";
  state.setPending("g", count + "g");
  return { handled: true };
}

// src/vim/window-navigation.ts
function vimWindowNavigation(event, state) {
  const key = event.name ?? "";
  if (state.pending() === "w") {
    if (key === "k" || key === "w") {
      state.clearPending();
      return { action: "up", handled: true };
    }
    if (key === "j") {
      state.clearPending();
      return { action: "down", handled: true };
    }
    state.clearPending();
    return { handled: false };
  }
  return { handled: false };
}

// src/vim/motions.ts
var bracketPairs = new Map([
  ["(", ")"],
  ["[", "]"],
  ["{", "}"]
]);
var bracketClosers = new Map(Array.from(bracketPairs, ([open, close]) => [close, open]));
function lineStart(text, offset) {
  if (offset <= 0)
    return 0;
  const index = text.lastIndexOf(`
`, offset - 1);
  if (index === -1)
    return 0;
  return index + 1;
}
function lineEnd(text, offset) {
  const index = text.indexOf(`
`, offset);
  if (index === -1)
    return text.length;
  return index;
}
function lineLast(text, offset) {
  const start = lineStart(text, offset);
  const end = lineEnd(text, offset);
  if (end > start)
    return end - 1;
  return start;
}
function prevLineStart(text, offset) {
  const start = lineStart(text, offset);
  if (start === 0)
    return;
  return lineStart(text, start - 1);
}
function nextLineStart(text, offset) {
  const end = lineEnd(text, offset);
  if (end >= text.length)
    return;
  return end + 1;
}
function isBlankLine(text, lineStartOffset) {
  return lineEnd(text, lineStartOffset) === lineStartOffset;
}
function paragraphAdvance(text, lineOffset) {
  const end = lineEnd(text, lineOffset);
  if (end >= text.length - 1)
    return null;
  return end + 1;
}
function paragraphRetreat(text, lineOffset) {
  if (lineOffset <= 0)
    return null;
  return lineStart(text, lineOffset - 1);
}
function nextParagraphTarget(text, cursor) {
  if (text.length === 0)
    return 0;
  let probe = lineStart(text, cursor);
  while (isBlankLine(text, probe)) {
    const next = paragraphAdvance(text, probe);
    if (next === null)
      return probe;
    probe = next;
  }
  while (!isBlankLine(text, probe)) {
    const next = paragraphAdvance(text, probe);
    if (next === null)
      return lineLast(text, text.length - 1);
    probe = next;
  }
  return probe;
}
function previousParagraphTarget(text, cursor) {
  if (text.length === 0 || cursor === 0)
    return 0;
  let probe = lineStart(text, cursor);
  while (isBlankLine(text, probe)) {
    const previous = paragraphRetreat(text, probe);
    if (previous === null)
      return 0;
    probe = previous;
  }
  while (probe > 0) {
    const previous = paragraphRetreat(text, probe);
    if (previous === null)
      return 0;
    if (isBlankLine(text, previous))
      return previous;
    probe = previous;
  }
  return 0;
}
function lineColumn(text, offset) {
  return offset - lineStart(text, offset);
}
function bracketAtOrAfter(text, offset) {
  const end = lineEnd(text, offset);
  for (let pos = offset;pos < end; pos++) {
    if (bracketPairs.has(text[pos]) || bracketClosers.has(text[pos]))
      return pos;
  }
  return null;
}
function matchingForward(text, offset, open, close) {
  let depth = 1;
  for (let pos = offset + 1;pos < text.length; pos++) {
    if (text[pos] === open)
      depth++;
    if (text[pos] === close)
      depth--;
    if (depth === 0)
      return pos;
  }
  return null;
}
function matchingBackward(text, offset, open, close) {
  let depth = 1;
  for (let pos = offset - 1;pos >= 0; pos--) {
    if (text[pos] === close)
      depth++;
    if (text[pos] === open)
      depth--;
    if (depth === 0)
      return pos;
  }
  return null;
}
function matchingBracketTarget(text, offset) {
  if (!text.length)
    return null;
  const source = bracketAtOrAfter(text, Math.max(0, Math.min(offset, text.length - 1)));
  if (source === null)
    return null;
  const char = text[source];
  const close = bracketPairs.get(char);
  if (close)
    return matchingForward(text, source, char, close);
  const open = bracketClosers.get(char);
  if (open)
    return matchingBackward(text, source, open, char);
  return null;
}
function moveUp(text, offset, column = lineColumn(text, offset)) {
  const targetStart = prevLineStart(text, offset);
  if (targetStart === undefined)
    return offset;
  const targetLast = lineLast(text, targetStart);
  const col = column === "end" ? targetLast - targetStart : column;
  return Math.min(targetStart + col, targetLast);
}
function moveDown(text, offset, column = lineColumn(text, offset)) {
  const targetStart = nextLineStart(text, offset);
  if (targetStart === undefined)
    return offset;
  const targetLast = lineLast(text, targetStart);
  const col = column === "end" ? targetLast - targetStart : column;
  return Math.min(targetStart + col, targetLast);
}
function getLineColumn(textarea) {
  return lineColumn(textarea.plainText, textarea.cursorOffset);
}
function moveLeft(textarea) {
  const text = textarea.plainText;
  const start = lineStart(text, textarea.cursorOffset);
  textarea.cursorOffset = Math.max(start, textarea.cursorOffset - 1);
}
function moveLineBeginning(textarea) {
  const text = textarea.plainText;
  textarea.cursorOffset = lineStart(text, textarea.cursorOffset);
}
function moveFirstNonWhitespace(textarea) {
  const text = textarea.plainText;
  textarea.cursorOffset = firstNonWhitespace(text, textarea.cursorOffset);
}
function moveLineEnd(textarea) {
  const text = textarea.plainText;
  textarea.cursorOffset = lineLast(text, textarea.cursorOffset);
}
function clampCursorToLine(textarea) {
  const text = textarea.plainText;
  const last = lineLast(text, textarea.cursorOffset);
  if (textarea.cursorOffset > last)
    textarea.cursorOffset = last;
}
function alignVisualColumn(textarea, column) {
  const view = textarea.editorView;
  if (typeof view?.getVisualCursor !== "function")
    return;
  let cursor = view.getVisualCursor();
  const row = cursor.visualRow;
  const text = textarea.plainText;
  while (cursor.visualCol < column) {
    const next = textarea.cursorOffset + 1;
    if (next > lineLast(text, textarea.cursorOffset))
      break;
    if (typeof view.setCursorByOffset === "function")
      view.setCursorByOffset(next);
    else
      textarea.cursorOffset = next;
    const moved = view.getVisualCursor();
    if (moved.offset === cursor.offset || moved.visualRow !== row) {
      textarea.cursorOffset = cursor.offset;
      break;
    }
    cursor = moved;
  }
}
function moveRight(textarea) {
  const text = textarea.plainText;
  const last = lineLast(text, textarea.cursorOffset);
  textarea.cursorOffset = Math.min(last, textarea.cursorOffset + 1);
}
function moveLineUp(textarea, column) {
  const text = textarea.plainText;
  textarea.cursorOffset = moveUp(text, textarea.cursorOffset, column);
}
function moveLineDown(textarea, column) {
  const text = textarea.plainText;
  textarea.cursorOffset = moveDown(text, textarea.cursorOffset, column);
}
function moveVisualLineUp(textarea) {
  if (typeof textarea.moveCursorUp === "function") {
    textarea.moveCursorUp();
    return;
  }
  moveLineUp(textarea);
}
function moveVisualLineDown(textarea) {
  if (typeof textarea.moveCursorDown === "function") {
    textarea.moveCursorDown();
    return;
  }
  moveLineDown(textarea);
}
function setVisualOffset(textarea, offset) {
  const view = textarea.editorView;
  if (typeof view?.setCursorByOffset === "function")
    view.setCursorByOffset(offset);
  else
    textarea.cursorOffset = offset;
}
function visualRow(textarea) {
  const view = textarea.editorView;
  return typeof view?.getVisualCursor === "function" ? view.getVisualCursor().visualRow : undefined;
}
function visualLineStart(textarea) {
  const row = visualRow(textarea);
  if (row === undefined)
    return lineStart(textarea.plainText, textarea.cursorOffset);
  let offset = textarea.cursorOffset;
  while (offset > lineStart(textarea.plainText, offset)) {
    setVisualOffset(textarea, offset - 1);
    const moved = textarea.cursorOffset;
    if (moved === offset)
      return offset;
    if (visualRow(textarea) !== row) {
      setVisualOffset(textarea, offset);
      return offset;
    }
    offset = moved;
  }
  return offset;
}
function visualLineEnd(textarea) {
  const row = visualRow(textarea);
  if (row === undefined)
    return lineLast(textarea.plainText, textarea.cursorOffset);
  let offset = textarea.cursorOffset;
  while (offset < lineLast(textarea.plainText, offset)) {
    setVisualOffset(textarea, offset + 1);
    const moved = textarea.cursorOffset;
    if (moved === offset)
      return offset;
    if (visualRow(textarea) !== row) {
      setVisualOffset(textarea, offset);
      return offset;
    }
    offset = moved;
  }
  return offset;
}
function moveVisualLineBeginning(textarea) {
  setVisualOffset(textarea, visualLineStart(textarea));
}
function moveVisualFirstNonWhitespace(textarea) {
  const start = visualLineStart(textarea);
  const end = visualLineEnd(textarea);
  for (let offset = start;offset <= end; offset++) {
    const char = textarea.plainText[offset];
    if (char && !/\s/.test(char)) {
      setVisualOffset(textarea, offset);
      return;
    }
  }
  setVisualOffset(textarea, start);
}
function moveVisualLineEnd(textarea) {
  setVisualOffset(textarea, visualLineEnd(textarea));
}
function moveMatchingBracket(textarea) {
  const target = matchingBracketTarget(textarea.plainText, textarea.cursorOffset);
  if (target === null)
    return false;
  textarea.cursorOffset = target;
  return true;
}
function movePreviousParagraph(textarea) {
  textarea.cursorOffset = previousParagraphTarget(textarea.plainText, textarea.cursorOffset);
}
function moveNextParagraph(textarea) {
  textarea.cursorOffset = nextParagraphTarget(textarea.plainText, textarea.cursorOffset);
}
function matchingBracketOperation(textarea) {
  const text = textarea.plainText;
  const cursor = textarea.cursorOffset;
  const target = matchingBracketTarget(text, cursor);
  if (target === null)
    return { span: null, register: null };
  const span = target < cursor ? { start: target, end: cursor + 1 } : { start: cursor, end: target + 1 };
  return { span, register: { text: text.slice(span.start, span.end), linewise: false } };
}
function asLinewise(slice) {
  return slice.endsWith(`
`) ? slice : slice + `
`;
}
function buildOperatorResult(text, span, registerSpan, linewise) {
  if (!span)
    return { span: null, register: null };
  const register = registerSpan ?? span;
  const slice = text.slice(register.start, register.end);
  return { span, register: { text: linewise ? asLinewise(slice) : slice, linewise } };
}
function lineBeginningOperation(textarea) {
  const text = textarea.plainText;
  const end = textarea.cursorOffset;
  const start = lineStart(text, end);
  return buildOperatorResult(text, start < end ? { start, end } : null, null, false);
}
function firstNonWhitespaceOperation(textarea) {
  const text = textarea.plainText;
  const cursor = textarea.cursorOffset;
  const target = firstNonWhitespace(text, cursor);
  if (target === cursor)
    return { span: null, register: null };
  return buildOperatorResult(text, { start: Math.min(target, cursor), end: Math.max(target, cursor) }, null, false);
}
function classifyNextParagraph(text, cursor) {
  const lineStartOffset = lineStart(text, cursor);
  const onBlank = isBlankLine(text, lineStartOffset);
  const target = nextParagraphTarget(text, cursor);
  const targetLineStart = lineStart(text, target);
  return {
    lineStartOffset,
    onBlank,
    lineAligned: onBlank || cursor === lineStartOffset,
    target,
    targetIsBlank: target === targetLineStart && target < text.length && isBlankLine(text, target),
    multiLine: lineStartOffset !== targetLineStart
  };
}
function isLinewiseNext(c, op) {
  if (!c.lineAligned)
    return false;
  return op === "d" ? c.targetIsBlank || c.multiLine : c.targetIsBlank;
}
function nextLinewiseSpan(text, c, op) {
  if (op === "d" && !c.targetIsBlank) {
    const extendBack = text[text.length - 1] !== `
` && c.lineStartOffset > 0;
    return {
      span: { start: extendBack ? c.lineStartOffset - 1 : c.lineStartOffset, end: text.length },
      registerSpan: { start: c.lineStartOffset, end: text.length }
    };
  }
  const end = op === "c" ? c.target - 1 : c.target;
  if (end <= c.lineStartOffset)
    return { span: null, registerSpan: null };
  return { span: { start: c.lineStartOffset, end }, registerSpan: null };
}
function nextCharwiseSpan(text, cursor, c) {
  const end = c.targetIsBlank ? c.target - 1 : c.onBlank ? text.length : c.target + 1;
  if (end <= cursor)
    return null;
  return { start: cursor, end };
}
function nextParagraphOperation(textarea, operation) {
  const text = textarea.plainText;
  const cursor = textarea.cursorOffset;
  if (text.length === 0)
    return { span: null, register: null };
  const c = classifyNextParagraph(text, cursor);
  if (!isLinewiseNext(c, operation))
    return buildOperatorResult(text, nextCharwiseSpan(text, cursor, c), null, false);
  const { span, registerSpan } = nextLinewiseSpan(text, c, operation);
  return buildOperatorResult(text, span, registerSpan, true);
}
function previousParagraphOperation(textarea, operation) {
  const text = textarea.plainText;
  const cursor = textarea.cursorOffset;
  if (text.length === 0 || cursor === 0)
    return { span: null, register: null };
  const lineStartOffset = lineStart(text, cursor);
  const linewise = isBlankLine(text, lineStartOffset) || cursor === lineStartOffset;
  const target = previousParagraphTarget(text, cursor);
  if (target >= cursor)
    return { span: null, register: null };
  if (!linewise || operation !== "c")
    return buildOperatorResult(text, { start: target, end: cursor }, null, linewise);
  const end = text[cursor - 1] === `
` ? cursor - 1 : cursor;
  return buildOperatorResult(text, end > target ? { start: target, end } : null, null, true);
}
function isParagraphSeparator(text, start) {
  return /^[ \t]*$/.test(text.slice(start, lineEnd(text, start)));
}
function paragraphBlockFirstLine(text, cursor) {
  let probe = lineStart(text, cursor);
  while (isParagraphSeparator(text, probe)) {
    const end = lineEnd(text, probe);
    if (end >= text.length)
      return null;
    probe = end + 1;
  }
  while (probe > 0 && !isParagraphSeparator(text, lineStart(text, probe - 1))) {
    probe = lineStart(text, probe - 1);
  }
  return probe;
}
function paragraphBlockLastLine(text, first) {
  let last = first;
  for (;; ) {
    const end = lineEnd(text, last);
    if (end >= text.length)
      return last;
    if (isParagraphSeparator(text, end + 1))
      return last;
    last = end + 1;
  }
}
function paragraphTextObjectRange(text, cursor, around) {
  const cursorLine = lineStart(text, cursor);
  const onBlank = isParagraphSeparator(text, cursorLine);
  const first = onBlank && !around ? cursorLine : paragraphBlockFirstLine(text, cursor);
  if (first === null)
    return null;
  const last = onBlank && !around ? cursorLine : paragraphBlockLastLine(text, first);
  const lastEnd = lineEnd(text, last);
  let end = lastEnd >= text.length ? text.length : lastEnd + 1;
  const includeBlankTail = around !== onBlank;
  if (includeBlankTail) {
    while (end < text.length && isParagraphSeparator(text, end))
      end = Math.min(lineEnd(text, end) + 1, text.length);
  }
  let start = onBlank ? cursorLine : first;
  if (onBlank) {
    while (start > 0) {
      const previous = lineStart(text, start - 1);
      if (!isParagraphSeparator(text, previous))
        break;
      start = previous;
    }
  }
  const trailingBlank = includeBlankTail && end === text.length && text[end - 1] === `
`;
  return { start, end, trailingBlank };
}
function paragraphTextObjectOperation(textarea, around, operation, count = 1) {
  const text = textarea.plainText;
  if (!text.length)
    return { span: !around && operation === "c" && count === 1 ? { start: 0, end: 0 } : null, register: null };
  let range = paragraphTextObjectRange(text, textarea.cursorOffset, around);
  if (!range)
    return { span: null, register: null };
  for (let index = 1;index < count; index++) {
    const terminalEmptyLine = !around && !range.trailingBlank && range.end === text.length && text.endsWith(`
`);
    if (range.end >= text.length && !terminalEmptyLine)
      return { span: null, register: null };
    const next = paragraphTextObjectRange(text, range.end, around);
    if (!next || next.end <= range.end && !terminalEmptyLine)
      return { span: null, register: null };
    range = { ...next, start: range.start };
  }
  const { end, trailingBlank } = range;
  let start = range.start;
  if (around && end === text.length && !isParagraphSeparator(text, lineStart(text, end))) {
    while (start > 0) {
      const previous = lineStart(text, start - 1);
      if (!isParagraphSeparator(text, previous))
        break;
      start = previous;
    }
  }
  const registerSpan = { start, end };
  const deleteStart = operation === "d" && start > 0 && end === text.length && (text[end - 1] !== `
` || trailingBlank) ? start - 1 : start;
  const changeEnd = operation === "c" && text[end - 1] === `
` && !trailingBlank ? end - 1 : end;
  const result = buildOperatorResult(text, { start: deleteStart, end: changeEnd }, registerSpan, true);
  if (trailingBlank && end > start && result.register)
    result.register.text += `
`;
  return result;
}
function bufferTextObjectOperation(textarea) {
  const text = textarea.plainText;
  if (!text.length)
    return { span: null, register: null };
  return { span: { start: 0, end: text.length }, register: { text: text + `
`, linewise: true } };
}
function isWord(char) {
  return /[A-Za-z0-9_]/.test(char);
}
function isBigWord(char) {
  return !/\s/.test(char);
}
function nextWordStart(text, offset, big) {
  let pos = offset;
  if (pos >= text.length)
    return text.length;
  const startClass = wordClass(text[pos], big);
  if (startClass !== "blank") {
    while (pos < text.length && wordClass(text[pos], big) === startClass)
      pos++;
  }
  while (pos < text.length && wordClass(text[pos], big) === "blank")
    pos++;
  return pos;
}
function prevWordStart(text, offset, big) {
  let pos = Math.min(offset, text.length);
  if (pos <= 0)
    return 0;
  pos--;
  while (pos > 0 && wordClass(text[pos], big) === "blank")
    pos--;
  const target = wordClass(text[pos], big);
  while (pos > 0 && wordClass(text[pos - 1], big) === target)
    pos--;
  return pos;
}
function wordClass(char, big) {
  if (!isBigWord(char))
    return "blank";
  if (big || isWord(char))
    return "word";
  return "punct";
}
function wordRunEnd(text, offset, big) {
  const target = wordClass(text[offset], big);
  let pos = offset;
  while (pos + 1 < text.length && wordClass(text[pos + 1], big) === target)
    pos++;
  return pos;
}
function wordEnd(text, offset, big) {
  if (text.length === 0)
    return 0;
  let pos = offset;
  if (pos >= text.length)
    pos = text.length - 1;
  const startClass = wordClass(text[pos], big);
  const atRunEnd = startClass === "blank" || pos + 1 >= text.length || wordClass(text[pos + 1], big) !== startClass;
  if (atRunEnd) {
    pos++;
    while (pos < text.length && wordClass(text[pos], big) === "blank")
      pos++;
    if (pos >= text.length)
      return text.length - 1;
  }
  return wordRunEnd(text, pos, big);
}
function wordTextObjectOperation(textarea, around, big = false) {
  const text = textarea.plainText;
  if (!text.length)
    return { span: null, register: null };
  const blank = wordTextObjectBlankSpan(text, textarea.cursorOffset, big);
  if (blank) {
    if (!around)
      return buildOperatorResult(text, blank, null, false);
    return buildOperatorResult(text, wordTextObjectAroundBlankSpan(text, blank, big), null, false);
  }
  const inner = wordTextObjectInnerSpan(text, textarea.cursorOffset, big);
  if (!inner)
    return { span: null, register: null };
  if (!around)
    return buildOperatorResult(text, inner, null, false);
  let end = inner.end;
  while (end < text.length && text[end] !== `
` && wordClass(text[end], big) === "blank")
    end++;
  if (end > inner.end)
    return buildOperatorResult(text, { start: inner.start, end }, null, false);
  let start = inner.start;
  while (start > 0 && text[start - 1] !== `
` && wordClass(text[start - 1], big) === "blank")
    start--;
  return buildOperatorResult(text, { start, end: inner.end }, null, false);
}
function wordTextObjectInnerSpan(text, cursor, big) {
  const pos = Math.min(cursor, text.length - 1);
  if (text[pos] === `
`)
    return null;
  const target = wordClass(text[pos], big);
  let start = pos;
  while (start > 0 && wordClass(text[start - 1], big) === target)
    start--;
  let end = pos + 1;
  while (end < text.length && wordClass(text[end], big) === target)
    end++;
  return start < end ? { start, end } : null;
}
function wordTextObjectBlankSpan(text, cursor, big) {
  let start = Math.min(cursor, text.length - 1);
  if (wordClass(text[start], big) !== "blank" || text[start] === `
`)
    return null;
  while (start > 0 && text[start - 1] !== `
` && wordClass(text[start - 1], big) === "blank")
    start--;
  let end = start;
  while (end < text.length && text[end] !== `
` && wordClass(text[end], big) === "blank")
    end++;
  return start < end ? { start, end } : null;
}
function wordTextObjectAroundBlankSpan(text, blank, big) {
  const end = blank.end;
  if (end < text.length && text[end] !== `
`) {
    const inner2 = wordTextObjectInnerSpan(text, end, big);
    return inner2 ? { start: blank.start, end: inner2.end } : null;
  }
  if (end >= text.length)
    return null;
  let pos = end + 1;
  while (pos < text.length) {
    if (text[pos - 1] === `
` && text[pos] === `
`)
      return { start: blank.start, end: pos };
    if (wordClass(text[pos], big) !== "blank")
      break;
    pos++;
  }
  if (pos >= text.length)
    return null;
  const inner = wordTextObjectInnerSpan(text, pos, big);
  return inner ? { start: blank.start, end: inner.end } : null;
}
function bracketTextObjectOperation(textarea, around, bracket, operation) {
  const text = textarea.plainText;
  if (!text.length)
    return { span: null, register: null };
  const pair = bracketTextObjectPair(text, textarea.cursorOffset, bracket);
  if (!pair)
    return { span: null, register: null };
  const span = around ? { start: pair.start, end: pair.end + 1 } : bracketTextObjectInnerSpan(text, pair, operation);
  const registerSpan = around ? null : bracketTextObjectInnerSpan(text, pair, "d");
  if (span.start < span.end)
    return buildOperatorResult(text, span, registerSpan, false);
  return { span: { start: span.start, end: span.start }, register: { text: "", linewise: false } };
}
function bracketTextObjectInnerSpan(text, pair, operation) {
  const start = pair.start + 1;
  const end = pair.end;
  if (text[start] === `
` && text[end - 1] === `
`)
    return { start: start + 1, end: operation === "c" ? end - 1 : end };
  return { start, end };
}
function bracketTextObjectPair(text, cursor, bracket) {
  const pair = bracketTextObjectPairChars(bracket);
  if (!pair)
    return null;
  const containing = bracketTextObjectContainingPair(text, cursor, 0, text.length, pair.open, pair.close);
  if (containing)
    return containing;
  const pairStart = bracketTextObjectOpenAfterCursor(text, cursor, text.length, pair.open);
  if (pairStart === null)
    return null;
  const pairEnd = bracketTextObjectClose(text, pairStart, text.length, pair.open, pair.close);
  return pairEnd === null ? null : { start: pairStart, end: pairEnd };
}
function bracketTextObjectPairChars(bracket) {
  if (bracket === "(" || bracket === ")")
    return { open: "(", close: ")" };
  if (bracket === "[" || bracket === "]")
    return { open: "[", close: "]" };
  if (bracket === "{" || bracket === "}")
    return { open: "{", close: "}" };
  if (bracket === "<" || bracket === ">")
    return { open: "<", close: ">" };
  return null;
}
function bracketTextObjectContainingPair(text, cursor, start, end, open, close) {
  const stack = [];
  let result = null;
  for (let index = start;index < end; index++) {
    if (text[index] === open)
      stack.push(index);
    if (text[index] !== close)
      continue;
    const pairStart = stack.pop();
    if (pairStart === undefined || pairStart > cursor || index < cursor)
      continue;
    if (!result || pairStart > result.start)
      result = { start: pairStart, end: index };
  }
  return result;
}
function bracketTextObjectOpenAfterCursor(text, cursor, end, open) {
  const index = text.indexOf(open, cursor);
  return index === -1 || index >= end ? null : index;
}
function bracketTextObjectClose(text, start, end, open, close) {
  let depth = 0;
  for (let index = start;index < end; index++) {
    if (text[index] === open)
      depth++;
    if (text[index] === close) {
      depth--;
      if (depth === 0)
        return index;
    }
  }
  return null;
}
function quoteTextObjectOperation(textarea, around, quote) {
  const text = textarea.plainText;
  if (!text.length)
    return { span: null, register: null };
  const pair = quoteTextObjectPair(text, textarea.cursorOffset, quote);
  if (!pair)
    return { span: null, register: null };
  const span = around ? quoteTextObjectAroundSpan(text, pair) : { start: pair.start + 1, end: pair.end };
  if (span.start < span.end)
    return buildOperatorResult(text, span, null, false);
  return { span: { start: span.start, end: span.start }, register: { text: "", linewise: false } };
}
function quoteTextObjectAroundSpan(text, pair) {
  let end = pair.end + 1;
  while (end < text.length && text[end] !== `
` && isHorizontalWhitespace(text[end]))
    end++;
  if (end > pair.end + 1)
    return { start: pair.start, end };
  let start = pair.start;
  while (start > 0 && text[start - 1] !== `
` && isHorizontalWhitespace(text[start - 1]))
    start--;
  return { start, end: pair.end + 1 };
}
function quoteTextObjectPair(text, cursor, quote) {
  const start = lineStart(text, cursor);
  const end = lineEnd(text, cursor);
  const positions = [];
  for (let position = start;position < end; position++) {
    if (text[position] === quote && !isEscaped(text, position))
      positions.push(position);
  }
  if (positions.length < 2)
    return null;
  const index = positions.findIndex((position) => position >= cursor);
  if (index === -1)
    return null;
  if (positions[index] === cursor) {
    const pairIndex = index % 2 === 0 ? index : index - 1;
    const pairEnd = positions[pairIndex + 1];
    return pairEnd === undefined ? null : { start: positions[pairIndex], end: pairEnd };
  }
  const previous = positions[index - 1];
  if (previous === undefined) {
    const pairEnd = positions[1];
    return pairEnd === undefined ? null : { start: positions[0], end: pairEnd };
  }
  return { start: previous, end: positions[index] };
}
function isHorizontalWhitespace(char) {
  return char === " " || char === "\t";
}
function isEscaped(text, position) {
  let backslashes = 0;
  for (let index = position - 1;index >= 0 && text[index] === "\\"; index--)
    backslashes++;
  return backslashes % 2 === 1;
}
function anyQuoteTextObjectOperation(textarea, around) {
  for (const quote of ['"', "'", "`"]) {
    const result = quoteTextObjectOperation(textarea, around, quote);
    if (result.span)
      return result;
  }
  return { span: null, register: null };
}
function deleteOffsets(textarea, startOffset, endOffset) {
  if (endOffset <= startOffset)
    return;
  const end = Math.min(endOffset, textarea.plainText.length);
  if (end <= startOffset)
    return;
  const start = textarea.editBuffer.offsetToPosition(startOffset);
  const pos = textarea.editBuffer.offsetToPosition(end);
  if (!start || !pos)
    return;
  textarea.deleteRange(start.row, start.col, pos.row, pos.col);
  textarea.cursorOffset = startOffset;
}
function swap(char) {
  const low = char.toLowerCase();
  const up = char.toUpperCase();
  if (char === low && char !== up)
    return up;
  if (char === up && char !== low)
    return low;
  return char;
}
function moveWordNext(textarea) {
  const text = textarea.plainText;
  textarea.cursorOffset = nextWordStart(text, textarea.cursorOffset, false);
}
function moveWordPrev(textarea) {
  const text = textarea.plainText;
  textarea.cursorOffset = prevWordStart(text, textarea.cursorOffset, false);
}
function moveWordEnd(textarea) {
  const text = textarea.plainText;
  textarea.cursorOffset = wordEnd(text, textarea.cursorOffset, false);
}
function moveBigWordNext(textarea) {
  const text = textarea.plainText;
  textarea.cursorOffset = nextWordStart(text, textarea.cursorOffset, true);
}
function moveBigWordPrev(textarea) {
  const text = textarea.plainText;
  textarea.cursorOffset = prevWordStart(text, textarea.cursorOffset, true);
}
function moveBigWordEnd(textarea) {
  const text = textarea.plainText;
  textarea.cursorOffset = wordEnd(text, textarea.cursorOffset, true);
}
function firstNonWhitespace(text, offset) {
  const start = lineStart(text, offset);
  const end = lineEnd(text, offset);
  let pos = start;
  while (pos < end && /\s/.test(text[pos]))
    pos++;
  return pos;
}
function findCharTargetInLine(text, offset, char, forward, skip = 1) {
  if (forward) {
    for (let i = offset + skip;i < text.length; i++) {
      if (text[i] === char)
        return i;
    }
    return null;
  }
  for (let i = offset - skip;i >= 0; i--) {
    if (text[i] === char)
      return i;
  }
  return null;
}
function findCharInLine(text, offset, char, forward, till = false, repeat = false) {
  const target = findCharTargetInLine(text, offset, char, forward, till && repeat ? 2 : 1);
  if (target === null)
    return offset;
  return till ? target + (forward ? -1 : 1) : target;
}
function appendAfterCursor(textarea) {
  const text = textarea.plainText;
  const end = lineEnd(text, textarea.cursorOffset);
  textarea.cursorOffset = Math.min(textarea.cursorOffset + 1, end);
}
function appendLineEnd(textarea) {
  const text = textarea.plainText;
  textarea.cursorOffset = lineEnd(text, textarea.cursorOffset);
}
function insertLineStart(textarea) {
  const text = textarea.plainText;
  textarea.cursorOffset = firstNonWhitespace(text, textarea.cursorOffset);
}
function openLineBelow(textarea) {
  const text = textarea.plainText;
  const end = lineEnd(text, textarea.cursorOffset);
  textarea.cursorOffset = end;
  textarea.insertText(`
`);
}
function openLineAbove(textarea) {
  const text = textarea.plainText;
  const start = lineStart(text, textarea.cursorOffset);
  textarea.cursorOffset = start;
  textarea.insertText(`
`);
  textarea.cursorOffset = start;
}
function deleteUnderCursor(textarea) {
  const text = textarea.plainText;
  const startOffset = textarea.cursorOffset;
  const end = lineEnd(text, startOffset);
  if (startOffset >= end)
    return null;
  const yanked = text[startOffset];
  deleteOffsets(textarea, startOffset, startOffset + 1);
  clampCursorToLine(textarea);
  return { text: yanked, linewise: false };
}
function deleteLine(textarea, anchor) {
  const text = textarea.plainText;
  if (!text.length)
    return null;
  const offset = textarea.cursorOffset;
  const lo = anchor !== undefined ? Math.min(anchor, offset) : offset;
  const hi = anchor !== undefined ? Math.max(anchor, offset) : offset;
  const start = lineStart(text, lo);
  const end = lineEnd(text, hi);
  const yanked = text.slice(start, end);
  if (end < text.length) {
    deleteOffsets(textarea, start, end + 1);
    return { text: yanked, linewise: true };
  }
  if (start > 0) {
    deleteOffsets(textarea, start - 1, end);
    textarea.cursorOffset = lineStart(textarea.plainText, textarea.cursorOffset);
    return { text: yanked, linewise: true };
  }
  deleteOffsets(textarea, start, end);
  return { text: yanked, linewise: true };
}
function deleteLineEnd(textarea) {
  const text = textarea.plainText;
  const start = textarea.cursorOffset;
  const end = lineEnd(text, start);
  if (end <= start)
    return null;
  const yanked = text.slice(start, end);
  deleteOffsets(textarea, start, end);
  textarea.cursorOffset = lineLast(textarea.plainText, start);
  return { text: yanked, linewise: false };
}
function deleteSpan(textarea, span) {
  if (!span || span.end <= span.start)
    return;
  deleteOffsets(textarea, span.start, span.end);
}
function joinLines(textarea) {
  const text = textarea.plainText;
  const end = lineEnd(text, textarea.cursorOffset);
  if (end >= text.length)
    return;
  let next = end + 1;
  while (next < text.length && (text[next] === " " || text[next] === "\t"))
    next++;
  const trailing = end > 0 && /[ \t]/.test(text[end - 1]);
  const paren = next < text.length && text[next] === ")";
  deleteOffsets(textarea, end, next);
  if (!trailing && !paren)
    textarea.insertText(" ");
  textarea.cursorOffset = end;
}
function substituteLine(textarea, anchor) {
  const text = textarea.plainText;
  const offset = textarea.cursorOffset;
  const lo = anchor !== undefined ? Math.min(anchor, offset) : offset;
  const hi = anchor !== undefined ? Math.max(anchor, offset) : offset;
  const start = lineStart(text, lo);
  const end = lineEnd(text, hi);
  if (end <= start)
    return null;
  const yanked = text.slice(start, end);
  deleteOffsets(textarea, start, end);
  return { text: yanked, linewise: true };
}
function substituteLineEnd(textarea) {
  const text = textarea.plainText;
  const start = textarea.cursorOffset;
  const end = lineEnd(text, start);
  if (end <= start)
    return null;
  const yanked = text.slice(start, end);
  deleteOffsets(textarea, start, end);
  return { text: yanked, linewise: false };
}
function replaceUnderCursor(textarea, value) {
  const text = textarea.plainText;
  const offset = textarea.cursorOffset;
  if (offset >= text.length || text[offset] === `
`) {
    textarea.insertText(value);
    return;
  }
  deleteOffsets(textarea, offset, offset + 1);
  textarea.insertText(value);
}
function toggleCase(textarea) {
  const text = textarea.plainText;
  const start = textarea.cursorOffset;
  const end = lineEnd(text, start);
  if (start >= end)
    return;
  const char = text[start];
  const next = swap(char);
  if (next !== char) {
    deleteOffsets(textarea, start, start + 1);
    textarea.insertText(next);
    textarea.cursorOffset = start;
  }
  moveRight(textarea);
}
function pasteAfter(textarea, reg) {
  if (!reg)
    return;
  if (reg.linewise) {
    const text = textarea.plainText;
    const end = lineEnd(text, textarea.cursorOffset);
    const value = reg.text.endsWith(`
`) ? reg.text.slice(0, -1) : reg.text;
    textarea.cursorOffset = end;
    textarea.insertText(`
` + value);
    textarea.cursorOffset = end + 1;
    return;
  }
  textarea.cursorOffset = Math.min(textarea.cursorOffset + 1, textarea.plainText.length);
  textarea.insertText(reg.text);
  textarea.cursorOffset = Math.max(0, textarea.cursorOffset - 1);
}
function pasteBefore(textarea, reg) {
  if (!reg)
    return;
  if (reg.linewise) {
    const text = textarea.plainText;
    const start = lineStart(text, textarea.cursorOffset);
    const value = reg.text.endsWith(`
`) ? reg.text.slice(0, -1) : reg.text;
    textarea.cursorOffset = start;
    textarea.insertText(value + `
`);
    textarea.cursorOffset = start;
    return;
  }
  textarea.insertText(reg.text);
  textarea.cursorOffset = Math.max(0, textarea.cursorOffset - 1);
}
function pasteOverSelection(textarea, reg) {
  if (!reg)
    return null;
  const sel = textarea.editorView.getSelection();
  if (!sel || sel.end <= sel.start)
    return null;
  const start = Math.max(0, Math.min(sel.start, textarea.plainText.length));
  const end = Math.max(start, Math.min(sel.end, textarea.plainText.length));
  const text = textarea.plainText.slice(start, end);
  if (!text)
    return null;
  clearSelection(textarea);
  deleteOffsets(textarea, start, end);
  textarea.insertText(reg.text);
  textarea.cursorOffset = Math.max(0, textarea.cursorOffset - 1);
  return { text, linewise: false };
}
function pasteOverVisualSelection(textarea, reg, linewise = false, anchor) {
  if (!reg || anchor === undefined)
    return null;
  if (!linewise) {
    const sel = selectionRange(textarea, anchor, false);
    if (!sel)
      return null;
    const text2 = textarea.plainText.slice(sel.start, sel.end);
    if (!text2)
      return null;
    clearSelection(textarea);
    deleteOffsets(textarea, sel.start, sel.end);
    textarea.insertText(reg.text);
    textarea.cursorOffset = Math.max(0, textarea.cursorOffset - 1);
    return { text: text2, linewise: false };
  }
  const text = textarea.plainText;
  const selectionStart = lineStart(text, Math.min(anchor, textarea.cursorOffset));
  const selectionEnd = lineEnd(text, Math.max(anchor, textarea.cursorOffset));
  const deleted = text.slice(selectionStart, selectionEnd);
  const prefix = selectionEnd >= text.length && selectionStart > 0 ? `
` : "";
  const suffix = !prefix && selectionEnd < text.length ? `
` : "";
  const start = prefix ? selectionStart - 1 : selectionStart;
  const end = suffix ? selectionEnd + 1 : selectionEnd;
  clearSelection(textarea);
  deleteOffsets(textarea, start, end);
  textarea.cursorOffset = start;
  textarea.insertText(prefix + reg.text + suffix);
  textarea.cursorOffset = start + prefix.length;
  return { text: deleted, linewise: true };
}
function syncSelection(textarea, anchor, linewise = false) {
  const text = textarea.plainText;
  const cursor = textarea.cursorOffset;
  let lo = Math.min(anchor, cursor);
  let hi = Math.max(anchor + 1, cursor + 1);
  if (linewise) {
    lo = lineStart(text, lo);
    hi = lineEnd(text, hi - 1);
    if (hi < text.length)
      hi++;
  }
  const ta = textarea;
  const forward = cursor >= anchor;
  textarea.cursorOffset = forward ? lo : hi;
  ta.updateSelectionForMovement(true, true);
  textarea.cursorOffset = forward ? hi : lo;
  ta.updateSelectionForMovement(true, false);
  textarea.cursorOffset = cursor;
  textarea.editorView.setSelection(lo, hi, textarea.selectionBg, textarea.selectionFg);
}
function toggleVisualEnd(textarea, anchor, linewise = false) {
  const text = textarea.plainText;
  const cursor = textarea.cursorOffset;
  let lo = Math.min(anchor, cursor);
  let hi = Math.max(anchor + 1, cursor + 1);
  if (linewise) {
    lo = lineStart(text, lo);
    hi = lineEnd(text, hi - 1);
    if (hi < text.length)
      hi++;
  }
  textarea.editorView.setSelection(lo, hi, textarea.selectionBg, textarea.selectionFg);
}
function clearSelection(textarea) {
  const ta = textarea;
  ta.updateSelectionForMovement(false, true);
  textarea.editorView.resetSelection();
}
function selectionRange(textarea, anchor, linewise = false) {
  if (anchor === undefined)
    return null;
  let start = Math.min(anchor, textarea.cursorOffset);
  let end = Math.max(anchor + 1, textarea.cursorOffset + 1);
  if (linewise) {
    const text = textarea.plainText;
    start = lineStart(text, start);
    end = lineEnd(text, end - 1);
    if (end < text.length)
      end++;
  }
  return { start, end };
}
function toggleSelectionCase(textarea, linewise = false, anchor) {
  const sel = selectionRange(textarea, anchor, linewise);
  if (!sel)
    return;
  const text = textarea.plainText.slice(sel.start, sel.end);
  const next = text.split("").map(swap).join("");
  if (next !== text) {
    deleteOffsets(textarea, sel.start, sel.end);
    textarea.insertText(next);
  }
  textarea.cursorOffset = sel.start;
}
function replaceSelection(textarea, value, linewise = false, anchor) {
  const sel = selectionRange(textarea, anchor, linewise);
  if (!sel)
    return;
  const next = textarea.plainText.slice(sel.start, sel.end).split("").map((char) => char === `
` ? char : value).join("");
  deleteOffsets(textarea, sel.start, sel.end);
  textarea.insertText(next);
  textarea.cursorOffset = sel.start;
}
function deleteSelection(textarea, linewise = false, anchor) {
  const sel = selectionRange(textarea, anchor, linewise);
  if (!sel)
    return null;
  const text = textarea.plainText;
  const yanked = text.slice(sel.start, sel.end);
  let start = sel.start;
  let end = sel.end;
  if (linewise) {
    const hasTrailingNl = end < text.length && text[end - 1] === `
`;
    const hasLeadingNl = start > 0 && text[start - 1] === `
`;
    if (!hasTrailingNl && end < text.length && text[end] === `
`) {
      end++;
    } else if (!hasTrailingNl && hasLeadingNl) {
      start--;
    }
  }
  deleteOffsets(textarea, start, end);
  const after = textarea.plainText;
  if (linewise) {
    if (start >= after.length && start > 0) {
      textarea.cursorOffset = lineStart(after, after.length - 1);
    } else {
      textarea.cursorOffset = lineStart(after, Math.min(start, Math.max(after.length - 1, 0)));
    }
  } else {
    textarea.cursorOffset = Math.min(start, Math.max(after.length - 1, 0));
  }
  return { text: yanked, linewise };
}
function yankSelection(textarea, linewise = false, anchor) {
  const sel = selectionRange(textarea, anchor, linewise);
  if (!sel)
    return null;
  return { text: textarea.plainText.slice(sel.start, sel.end), linewise };
}

// src/vim/repeat.ts
function createVimRepeat(input) {
  let activeRepeat;
  let mutationDepth = 0;
  function clampOffset(offset, length) {
    return Math.max(0, Math.min(length, offset));
  }
  function changed(before, after) {
    return before.text !== after.text || before.cursor !== after.cursor;
  }
  function sameData(before, after) {
    return input.snapshotDataEqual?.(before.data, after.data) ?? Bun.deepEquals(before.data, after.data);
  }
  function textEdit(origin, before, after) {
    if (before.text === after.text)
      return null;
    let commonStart = 0;
    while (commonStart < before.text.length && commonStart < after.text.length && before.text[commonStart] === after.text[commonStart])
      commonStart++;
    const start = Math.min(commonStart, before.cursor);
    let baseEnd = before.text.length;
    let afterEnd = after.text.length;
    while (baseEnd > start && afterEnd > start && before.text[baseEnd - 1] === after.text[afterEnd - 1]) {
      baseEnd--;
      afterEnd--;
    }
    return {
      startOffset: start - origin.cursor,
      baseEndOffset: baseEnd - origin.cursor,
      insert: after.text.slice(start, afterEnd)
    };
  }
  function patch(base, after) {
    const edit2 = textEdit(base, base, after);
    if (!edit2)
      return {
        startOffset: 0,
        baseEndOffset: 0,
        insert: "",
        cursorOffset: after.cursor - base.cursor
      };
    const deleted = base.text.slice(base.cursor + edit2.startOffset, base.cursor + edit2.baseEndOffset);
    if (deleted && edit2.insert.includes(deleted))
      return null;
    return {
      ...edit2,
      cursorOffset: after.cursor - base.cursor
    };
  }
  function applyTextEdit(base, next) {
    const textarea = input.textarea();
    const start = clampOffset(base.cursor + next.startOffset, textarea.plainText.length);
    const end = Math.max(start, clampOffset(base.cursor + next.baseEndOffset, textarea.plainText.length));
    if (end > start) {
      const startPos = textarea.editBuffer.offsetToPosition(start);
      const endPos = textarea.editBuffer.offsetToPosition(end);
      if (!startPos || !endPos)
        return;
      textarea.deleteRange(startPos.row, startPos.col, endPos.row, endPos.col);
    }
    textarea.cursorOffset = start;
    if (next.insert)
      textarea.insertText(next.insert);
    textarea.cursorOffset = start + next.insert.length;
  }
  function applyPatch(base, next) {
    applyTextEdit(base, next);
    const textarea = input.textarea();
    textarea.cursorOffset = clampOffset(base.cursor + next.cursorOffset, textarea.plainText.length);
  }
  function recorderSnapshot(active) {
    const recorder = active.recorder;
    if (recorder)
      return { text: recorder.textarea.plainText, cursor: recorder.textarea.cursorOffset };
    return input.snapshot();
  }
  function recordTextEdit(active, before) {
    if (activeRepeat !== active || input.state.replaying())
      return;
    const edit2 = textEdit(active.base, before, recorderSnapshot(active));
    if (edit2)
      active.edits.push(edit2);
  }
  function recordMutation(active, run) {
    if (mutationDepth)
      return run();
    const before = recorderSnapshot(active);
    mutationDepth++;
    try {
      return run();
    } finally {
      mutationDepth--;
      recordTextEdit(active, before);
    }
  }
  function startRecording(active) {
    const textarea = input.textarea();
    const recorder = {
      textarea,
      insertText: textarea.insertText,
      deleteRange: textarea.deleteRange,
      setText: textarea.setText
    };
    active.recorder = recorder;
    textarea.insertText = (...args) => {
      return recordMutation(active, () => recorder.insertText.apply(textarea, args));
    };
    textarea.deleteRange = (...args) => {
      return recordMutation(active, () => recorder.deleteRange.apply(textarea, args));
    };
    textarea.setText = (...args) => {
      return recordMutation(active, () => recorder.setText.apply(textarea, args));
    };
  }
  function stopRecording(active) {
    if (active.type !== "patch" || !active.recorder)
      return;
    active.recorder.textarea.insertText = active.recorder.insertText;
    active.recorder.textarea.deleteRange = active.recorder.deleteRange;
    active.recorder.textarea.setText = active.recorder.setText;
    active.recorder = undefined;
  }
  function finishActiveRepeat() {
    const active = activeRepeat;
    activeRepeat = undefined;
    if (active)
      stopRecording(active);
    return active;
  }
  function cancel() {
    finishActiveRepeat();
  }
  input.state.onCancelEdit(cancel);
  function applyTextEdits(base, edits, cursorOffset) {
    edits.forEach((edit2) => applyTextEdit(base, edit2));
    const textarea = input.textarea();
    textarea.cursorOffset = clampOffset(base.cursor + cursorOffset, textarea.plainText.length);
  }
  function withReplay(run) {
    input.state.setReplaying(true);
    try {
      run();
    } finally {
      input.state.setReplaying(false);
    }
  }
  function pushReplay(before, after) {
    if (!sameData(before, after))
      input.state.setRepeat(null);
    if (!changed(before, after))
      return false;
    input.state.push(before, after);
    return true;
  }
  function recordRepeat(run) {
    if (input.state.replaying())
      return;
    input.state.setRepeat({
      run() {
        const before = input.snapshot();
        withReplay(run);
        return pushReplay(before, input.snapshot());
      }
    });
  }
  function edit(run) {
    if (!input.tracked()) {
      run();
      return;
    }
    const before = input.snapshot();
    const repeatable = !input.state.replaying() && !input.state.isVisual();
    const applied = run() === true;
    const after = input.snapshot();
    input.state.push(before, after);
    if (!repeatable)
      return;
    if (!sameData(before, after)) {
      input.state.setRepeat(null);
      return;
    }
    if (applied || changed(before, after))
      recordRepeat(run);
  }
  function begin(run, options) {
    if (!input.tracked()) {
      run?.();
      return;
    }
    cancel();
    const before = input.snapshot();
    const repeatable = !input.state.replaying() && !input.state.isVisual();
    input.state.beginEdit(before);
    if (run?.() === false) {
      input.state.cancelEdit();
      return;
    }
    if (repeatable) {
      const next = {
        before,
        base: input.snapshot(),
        setup: run ?? (() => {})
      };
      activeRepeat = options?.replace ? { ...next, type: "replace", edits: [] } : { ...next, type: "patch", edits: [] };
      if (activeRepeat.type === "patch")
        startRecording(activeRepeat);
    }
  }
  function commit(after) {
    const active = finishActiveRepeat();
    if (!active || input.state.replaying())
      return;
    if (!sameData(active.before, active.base) || !sameData(active.base, after)) {
      input.state.setRepeat(null);
      return;
    }
    const recordCommittedRepeat = (run) => input.state.setRepeat({
      run() {
        const before = input.snapshot();
        let failed = false;
        withReplay(() => {
          if (active.setup() === false) {
            failed = true;
            input.state.setMode("normal");
            return;
          }
          run();
          input.state.setMode("normal");
        });
        const repeated = input.snapshot();
        if (failed)
          return false;
        return pushReplay(before, repeated);
      }
    });
    if (active.type === "replace" && active.edits.length) {
      const replaced = active.edits.some((edit2) => edit2.type === "replace");
      recordCommittedRepeat(() => {
        const start = input.state.replace();
        active.edits.forEach((edit2) => {
          if (edit2.type === "replace")
            replaceUnderCursor(input.textarea(), edit2.text);
          else
            input.textarea().insertText(edit2.text);
        });
        if (replaced && start !== null)
          input.textarea().cursorOffset = Math.max(start, input.textarea().cursorOffset - 1);
      });
      return;
    }
    if (active.type === "replace") {
      input.state.setRepeat(null);
      return;
    }
    if (active.edits.length) {
      const cursorOffset = after.cursor - active.base.cursor;
      recordCommittedRepeat(() => applyTextEdits(input.snapshot(), active.edits, cursorOffset));
      return;
    }
    const next = patch(active.base, after);
    if (!next) {
      input.state.setRepeat(null);
      return;
    }
    if (active.before.text === active.base.text && active.base.text === after.text && !next.insert) {
      input.state.setRepeat(null);
      return;
    }
    recordCommittedRepeat(() => applyPatch(input.snapshot(), next));
  }
  return {
    edit,
    begin,
    commit,
    recordReplaceChar(char) {
      if (activeRepeat?.type === "replace")
        activeRepeat.edits.push({ type: "replace", text: char });
    },
    recordInsertText(text) {
      if (activeRepeat?.type === "replace")
        activeRepeat.edits.push({ type: "insert", text });
    },
    cancel
  };
}

// src/vim/langmap.ts
function applyLangmap(event, key, langmap) {
  if (key.length !== 1)
    return event;
  const mapped = langmap?.[key] ?? (event.shift ? langmap?.[key.toLowerCase()]?.toUpperCase() : undefined);
  if (!mapped || mapped.length !== 1)
    return event;
  return {
    ...event,
    name: mapped,
    sequence: mapped,
    raw: mapped,
    shift: /[A-Z]/.test(mapped),
    preventDefault: () => event.preventDefault()
  };
}

// src/vim/handler.ts
function vimLangmapKeyName(event) {
  return vimEventText(event) ?? normalizedKeyName(event);
}
function vimEventText(event) {
  return event.sequence?.length === 1 ? event.sequence : event.raw?.length === 1 ? event.raw : undefined;
}
function normalizedKeyName(event) {
  if (event.name === "backspace" || event.sequence === "\b" || event.sequence === "\x7F" || event.raw === "\b" || event.raw === "\x7F")
    return "backspace";
  if (event.name === "enter")
    return "return";
  if (event.name === "slash")
    return event.shift ? "?" : "/";
  if (event.name === "colon")
    return ":";
  if (event.name === "at")
    return "@";
  if (event.name === "quote")
    return '"';
  if (event.name === "apostrophe")
    return "'";
  if (event.name === "backtick")
    return "`";
  const text = vimEventText(event);
  if (text && (text === ":" || text === "/" || text === "?" || text === "@" || text === '"' || text === "'" || text === "`" || "()[]{}<>".includes(text)))
    return text;
  if (event.shift) {
    if (event.name === "4")
      return "$";
    if (event.name === "6")
      return "^";
    if (event.name === "9")
      return "(";
    if (event.name === "0")
      return ")";
    if (event.name === "[")
      return "{";
    if (event.name === "]")
      return "}";
    if (event.name === ",")
      return "<";
    if (event.name === ".")
      return ">";
    if (event.name === ";")
      return ":";
  }
  return event.name ?? "";
}
function createVimHandler(input) {
  let wantedColumn;
  let visualWantedColumn;
  let pendingOperatorCount = 1;
  let pendingOperatorFind;
  let pendingOperatorDisplay;
  let pendingTextObject;
  const escapeSeq = input.vimEscapeSequence;
  const escapeFirst = escapeSeq?.[0];
  const escapeSecond = escapeSeq?.[1];
  let escapePending = false;
  let escapeTimer = null;
  function clearEscapePending() {
    escapePending = false;
    if (escapeTimer) {
      clearTimeout(escapeTimer);
      escapeTimer = null;
    }
  }
  function hasModifier(event) {
    return !!event.ctrl || !!event.meta || !!event.super;
  }
  function isPrintable(event) {
    const key = normalizedKeyName(event);
    return key.length === 1 || key === "space";
  }
  function value(event) {
    const key = normalizedKeyName(event);
    if (key === "space")
      return " ";
    if (event.shift && key.length === 1 && /[a-z]/.test(key))
      return key.toUpperCase();
    return key;
  }
  function replaceValue(event, visual = false) {
    if (event.name === "return")
      return visual ? "\r" : `
`;
    if (isPrintable(event))
      return value(event);
    return null;
  }
  function langmapped(event) {
    if (hasModifier(event))
      return event;
    if (["r", "vr", "f", "F", "t", "T"].includes(input.state.pending()))
      return event;
    return applyLangmap(event, vimLangmapKeyName(event), input.langmap?.());
  }
  function isShifted(event, key) {
    return event.name === key.toUpperCase() || event.name === key && !!event.shift;
  }
  function tracked() {
    return input.history?.() ?? true;
  }
  function register() {
    if (input.register)
      return input.register();
    return input.state.register();
  }
  function setRegister(next, notify = false) {
    if (input.setRegister) {
      input.setRegister(next, notify);
      return;
    }
    input.state.setRegister(next);
  }
  function countedRegister(reg, count) {
    if (!reg || count <= 1)
      return reg;
    const separator = reg.linewise && !reg.text.endsWith(`
`) ? `
` : "";
    return {
      ...reg,
      text: Array.from({ length: count }, () => reg.text).join(separator)
    };
  }
  function clearWantedColumn() {
    wantedColumn = undefined;
  }
  function clearVisualWantedColumn() {
    visualWantedColumn = undefined;
  }
  function cancelPending() {
    clearEscapePending();
    pendingOperatorCount = 1;
    pendingOperatorFind = undefined;
    pendingOperatorDisplay = undefined;
    pendingTextObject = undefined;
    clearWantedColumn();
    clearVisualWantedColumn();
    input.state.clearPending();
  }
  function repeatCount(count, run) {
    Array.from({ length: count }).forEach(() => run());
  }
  function takeCount(defaultValue = 1) {
    return input.state.takeCount(defaultValue);
  }
  function takeOperatorCount() {
    const count = takeCount(pendingOperatorCount);
    pendingOperatorCount = 1;
    return count;
  }
  function countedMotion(run) {
    repeatCount(takeCount(), run);
  }
  function isCountDigit(event, key) {
    return !event.shift && !hasModifier(event) && /^[1-9]$/.test(key);
  }
  function isCountInput(event, key) {
    return !input.state.pending() && (isCountDigit(event, key) || key === "0" && input.state.count());
  }
  function isPendingOperatorCountInput(event, key) {
    return pendingOperatorCount === 1 && (input.state.pending() === "c" || input.state.pending() === "d" || input.state.pending() === "y") && (isCountDigit(event, key) || key === "0" && input.state.count());
  }
  function startOperator(event, operation) {
    const display = input.state.count() + operation;
    pendingOperatorCount = takeCount();
    input.state.setPending(operation, display);
    event.preventDefault();
    return true;
  }
  function lineStartForCount(text, offset, count) {
    return Array.from({ length: count - 1 }).reduce((current) => {
      const end = lineEnd(text, current);
      return end >= text.length ? current : end + 1;
    }, offset);
  }
  function moveVertical(direction) {
    const column = wantedColumn ?? getLineColumn(input.textarea());
    if (direction === "up")
      moveLineUp(input.textarea(), column);
    else
      moveLineDown(input.textarea(), column);
    wantedColumn = column;
  }
  function preservesWantedColumn(event, key) {
    if (key === "g" && !event.shift && !hasModifier(event))
      return true;
    if ((key === "j" || key === "k" || key === "down" || key === "up") && !event.shift && !hasModifier(event))
      return true;
    return (key === "v" || isShifted(event, "v")) && !hasModifier(event);
  }
  function preservesVisualWantedColumn(event, key) {
    if (key === "g" && !event.shift && !hasModifier(event))
      return true;
    return input.state.pending() === "g" && (key === "j" || key === "k" || key === "down" || key === "up") && !event.shift && !hasModifier(event);
  }
  function snapshot() {
    if (input.snapshot)
      return input.snapshot();
    return {
      text: input.textarea().plainText,
      cursor: input.textarea().cursorOffset
    };
  }
  function restore(next) {
    clearWantedColumn();
    clearVisualWantedColumn();
    clearSelection(input.textarea());
    input.state.clearPending();
    input.state.setMode("normal");
    input.state.cancelEdit();
    if (input.restore) {
      input.restore(next);
      return;
    }
    input.textarea().setText(next.text);
    input.textarea().cursorOffset = Math.max(0, Math.min(next.cursor, next.text.length));
  }
  const repeat = createVimRepeat({
    state: input.state,
    textarea: input.textarea,
    snapshot,
    snapshotDataEqual: input.snapshotDataEqual,
    tracked
  });
  const edit = repeat.edit;
  const begin = repeat.begin;
  function applyOperatorYank(result) {
    if (result.register)
      setRegister(result.register, true);
    if (result.span && result.span.end > result.span.start)
      input.flash?.(result.span);
    input.state.clearPending();
  }
  function applyOperatorEdit(result, operation) {
    const apply = () => {
      const next = result();
      if (!next.span && !next.register) {
        input.state.clearPending();
        return false;
      }
      if (next.span && next.span.end > next.span.start)
        deleteSpan(input.textarea(), next.span);
      if (next.span && next.span.end === next.span.start)
        input.textarea().cursorOffset = next.span.start;
      if (next.register)
        setRegister(next.register);
      input.state.clearPending();
      if (operation === "c")
        input.state.setMode("insert");
      return true;
    };
    if (operation === "c")
      begin(apply);
    else
      edit(apply);
  }
  function applyOperatorResult(result, operation) {
    const initial = result();
    if (!initial.span && !initial.register) {
      input.state.clearPending();
      return;
    }
    if (operation === "y") {
      applyOperatorYank(initial);
      return;
    }
    applyOperatorEdit(result, operation);
  }
  function paragraphOperator(key, operation) {
    if (key !== "{" && key !== "}")
      return false;
    const count = takeOperatorCount();
    applyOperatorResult(() => key === "}" ? nextParagraphCountOperation(operation, count) : previousParagraphCountOperation(operation, count), operation);
    return true;
  }
  function matchingBracketOperator(key, operation) {
    if (key !== "%")
      return false;
    pendingOperatorCount = 1;
    applyOperatorResult(() => matchingBracketOperation(input.textarea()), operation);
    return true;
  }
  function charwiseOperation(span) {
    if (!span)
      return { span: null, register: null };
    return { span, register: { text: input.textarea().plainText.slice(span.start, span.end), linewise: false } };
  }
  function linewiseOperation(span) {
    if (!span)
      return { span: null, register: null };
    const text = input.textarea().plainText.slice(span.start, span.end);
    return { span, register: { text: text.endsWith(`
`) ? text : text + `
`, linewise: true } };
  }
  function nextParagraphCountOperation(operation, count) {
    if (count === 1)
      return nextParagraphOperation(input.textarea(), operation);
    const textarea = input.textarea();
    const cursor = textarea.cursorOffset;
    repeatCount(count - 1, () => moveNextParagraph(textarea));
    const next = nextParagraphOperation(textarea, operation);
    textarea.cursorOffset = cursor;
    if (!next.span)
      return next;
    return next.register?.linewise ? linewiseOperation({ start: lineStart(textarea.plainText, cursor), end: next.span.end }) : charwiseOperation({ start: cursor, end: next.span.end });
  }
  function previousParagraphCountOperation(operation, count) {
    if (count === 1)
      return previousParagraphOperation(input.textarea(), operation);
    const textarea = input.textarea();
    const cursor = textarea.cursorOffset;
    repeatCount(count - 1, () => movePreviousParagraph(textarea));
    const next = previousParagraphOperation(textarea, operation);
    textarea.cursorOffset = cursor;
    if (!next.span)
      return next;
    if (!next.register?.linewise)
      return charwiseOperation({ start: next.span.start, end: cursor });
    const end = operation === "c" && textarea.plainText[cursor - 1] === `
` ? cursor - 1 : cursor;
    return linewiseOperation(end > next.span.start ? { start: next.span.start, end } : null);
  }
  function nextWordOperation(big, count = 1) {
    const textarea = input.textarea();
    const start = textarea.cursorOffset;
    const end = Array.from({ length: count }).reduce((offset) => nextWordStart(textarea.plainText, offset, big), start);
    return charwiseOperation(end > start ? { start, end } : null);
  }
  function previousWordOperation(count = 1) {
    const textarea = input.textarea();
    const end = textarea.cursorOffset;
    const start = Array.from({ length: count }).reduce((offset) => prevWordStart(textarea.plainText, offset, false), end);
    return charwiseOperation(start < end ? { start, end } : null);
  }
  function wordEndOperation(big, count = 1) {
    const textarea = input.textarea();
    const start = textarea.cursorOffset;
    if (start >= textarea.plainText.length)
      return charwiseOperation(null);
    const end = Array.from({ length: count }).reduce((offset) => wordEnd(textarea.plainText, offset, big) + 1, start);
    return charwiseOperation(end > start ? { start, end } : null);
  }
  function lineSpanCount(count) {
    const textarea = input.textarea();
    const start = lineStart(textarea.plainText, textarea.cursorOffset);
    const target = lineStartForCount(textarea.plainText, textarea.cursorOffset, count);
    return { start, end: lineEnd(textarea.plainText, target) };
  }
  function yankLineCount(count) {
    const span = lineSpanCount(count);
    return { span, register: { text: input.textarea().plainText.slice(span.start, span.end), linewise: true } };
  }
  function deleteLineCount(count) {
    const textarea = input.textarea();
    const start = textarea.cursorOffset;
    repeatCount(count - 1, () => moveLineDown(textarea, 0));
    const anchor = textarea.cursorOffset;
    textarea.cursorOffset = start;
    return deleteLine(textarea, anchor);
  }
  function substituteLineCount(count) {
    const textarea = input.textarea();
    const start = textarea.cursorOffset;
    repeatCount(count - 1, () => moveLineDown(textarea, 0));
    const anchor = textarea.cursorOffset;
    textarea.cursorOffset = start;
    return substituteLine(textarea, anchor);
  }
  function prepareDisplayWantedColumn() {
    const view = input.textarea().editorView;
    visualWantedColumn ??= wantedColumn === "end" ? "end" : view.getVisualCursor?.().visualCol;
    clearWantedColumn();
  }
  function moveDisplayVertical(direction, count, column) {
    repeatCount(count, () => {
      direction === "down" ? moveVisualLineDown(input.textarea()) : moveVisualLineUp(input.textarea());
      clampCursorToLine(input.textarea());
      if (column === "end")
        moveVisualLineEnd(input.textarea());
      else if (column !== undefined)
        alignVisualColumn(input.textarea(), column);
    });
  }
  function moveDisplayHorizontal(key, count) {
    const textarea = input.textarea();
    if (key === "$")
      repeatCount(count - 1, () => moveDisplayVertical("down", 1, undefined));
    if (key === "0")
      moveVisualLineBeginning(textarea);
    else if (key === "^")
      moveVisualFirstNonWhitespace(textarea);
    else
      moveVisualLineEnd(textarea);
  }
  function lineMotionAnchor(direction, count) {
    const textarea = input.textarea();
    const cursor = textarea.cursorOffset;
    const start = lineStart(textarea.plainText, cursor);
    repeatCount(count, () => direction === "down" ? moveLineDown(textarea, 0) : moveLineUp(textarea, 0));
    const anchor = textarea.cursorOffset;
    textarea.cursorOffset = cursor;
    return lineStart(textarea.plainText, anchor) === start ? null : anchor;
  }
  function yankLineMotion(direction, count) {
    const textarea = input.textarea();
    const anchor = lineMotionAnchor(direction, count);
    if (anchor === null)
      return { span: null, register: null };
    const cursorLine = lineStart(textarea.plainText, textarea.cursorOffset);
    const anchorLine = lineStart(textarea.plainText, anchor);
    const span = {
      start: Math.min(cursorLine, anchorLine),
      end: lineEnd(textarea.plainText, Math.max(cursorLine, anchorLine))
    };
    return { span, register: { text: textarea.plainText.slice(span.start, span.end), linewise: true } };
  }
  function clearPendingOperatorDisplay() {
    if (pendingOperatorDisplay)
      pendingOperatorCount = 1;
    pendingOperatorDisplay = undefined;
  }
  function displayLinewiseOperation(span) {
    if (!span)
      return { span: null, register: null };
    const text = input.textarea().plainText.slice(span.start, span.end);
    return { span, register: { text: text.endsWith(`
`) ? text.slice(0, -1) : text, linewise: true } };
  }
  function visualLineHorizontalMotionOperator(key, operation) {
    const count = takeOperatorCount();
    const result = () => {
      const textarea = input.textarea();
      const cursor = textarea.cursorOffset;
      moveDisplayHorizontal(key, key === "$" ? count : 1);
      const target = textarea.cursorOffset;
      textarea.cursorOffset = cursor;
      if (key === "$") {
        const end = textarea.plainText[target] && textarea.plainText[target] !== `
` ? target + 1 : target;
        return charwiseOperation(end > cursor ? { start: cursor, end } : null);
      }
      if (target === cursor)
        return charwiseOperation(null);
      const span = { start: Math.min(cursor, target), end: Math.max(cursor, target) };
      return charwiseOperation(span.end > span.start ? span : null);
    };
    if (operation === "y") {
      const yanked = result();
      applyOperatorYank(yanked);
      if (yanked.span)
        input.textarea().cursorOffset = yanked.span.start;
      return true;
    }
    applyOperatorResult(result, operation);
    return true;
  }
  function visualLineMotionOperator(key, operation) {
    const direction = key === "j" || key === "down" ? "down" : key === "k" || key === "up" ? "up" : undefined;
    if (!direction)
      return false;
    const count = takeOperatorCount();
    const result = () => {
      const textarea = input.textarea();
      const cursor = textarea.cursorOffset;
      const view = textarea.editorView;
      moveDisplayVertical(direction, count, view.getVisualCursor?.().visualCol);
      const target = textarea.cursorOffset;
      textarea.cursorOffset = cursor;
      if (target === cursor)
        return charwiseOperation(null);
      const start = Math.min(cursor, target);
      const end = Math.max(cursor, target);
      const sameColumnAtLineStart = lineStart(textarea.plainText, cursor) === cursor && lineStart(textarea.plainText, target) === target;
      return sameColumnAtLineStart ? displayLinewiseOperation({ start, end }) : charwiseOperation({ start, end });
    };
    if (operation === "y") {
      const yanked = result();
      applyOperatorYank(yanked);
      if (yanked.span)
        input.textarea().cursorOffset = yanked.span.start;
      return true;
    }
    if (operation === "c") {
      const initial = result();
      if (!initial.span && !initial.register) {
        input.state.clearPending();
        return true;
      }
      if (!initial.register?.linewise || !initial.span) {
        applyOperatorEdit(result, operation);
        return true;
      }
      begin(() => {
        const next = result();
        if (!next.span && !next.register) {
          input.state.clearPending();
          return false;
        }
        if (!next.span) {
          if (next.register)
            setRegister(next.register);
          input.state.clearPending();
          input.state.setMode("insert");
          return true;
        }
        const end = input.textarea().plainText[next.span.end - 1] === `
` ? next.span.end - 1 : next.span.end;
        if (end > next.span.start)
          deleteSpan(input.textarea(), { start: next.span.start, end });
        if (next.register)
          setRegister(next.register);
        input.state.clearPending();
        input.state.setMode("insert");
        return true;
      });
      return true;
    }
    applyOperatorResult(result, operation);
    return true;
  }
  function verticalMotionOperator(event, key, operation) {
    const direction = key === "j" || key === "down" ? "down" : key === "k" || key === "up" ? "up" : undefined;
    if (!direction || event.shift || hasModifier(event))
      return false;
    const count = takeOperatorCount();
    if (operation === "y") {
      const result = yankLineMotion(direction, count);
      if (result.register)
        setRegister(result.register, true);
      if (result.span && result.span.end > result.span.start)
        input.flash?.(result.span);
      input.state.clearPending();
      return true;
    }
    if (operation === "d") {
      edit(() => {
        const anchor = lineMotionAnchor(direction, count);
        const reg = anchor === null ? null : deleteLine(input.textarea(), anchor);
        input.state.clearPending();
        if (!reg)
          return false;
        setRegister(reg);
        return true;
      });
      return true;
    }
    begin(() => {
      const anchor = lineMotionAnchor(direction, count);
      const reg = anchor === null ? null : substituteLine(input.textarea(), anchor);
      input.state.clearPending();
      if (!reg)
        return false;
      setRegister(reg);
      input.state.setMode("insert");
      return true;
    });
    return true;
  }
  function changeWordOperation(big, count = 1) {
    const textarea = input.textarea();
    const char = textarea.plainText[textarea.cursorOffset];
    return char && !/\s/.test(char) ? wordEndOperation(big, count) : nextWordOperation(big, count);
  }
  function wordOperator(event, key, operation) {
    if ((key === "w" || isShifted(event, "w")) && !hasModifier(event)) {
      const big = isShifted(event, "w");
      const count = takeOperatorCount();
      applyOperatorResult(() => operation === "c" ? changeWordOperation(big, count) : nextWordOperation(big, count), operation);
      return true;
    }
    if (key === "b" && !event.shift && !hasModifier(event) && operation !== "y") {
      const count = takeOperatorCount();
      applyOperatorResult(() => previousWordOperation(count), operation);
      return true;
    }
    if ((key === "e" || isShifted(event, "e")) && !hasModifier(event)) {
      const count = takeOperatorCount();
      applyOperatorResult(() => wordEndOperation(isShifted(event, "e"), count), operation);
      return true;
    }
    return false;
  }
  function lineEndCountOperation(count) {
    const textarea = input.textarea();
    const start = textarea.cursorOffset;
    const end = lineEnd(textarea.plainText, lineStartForCount(textarea.plainText, start, count));
    return charwiseOperation(end > start ? { start, end } : null);
  }
  function lineBoundaryMotion(event, key, operation) {
    if (key === "$" && !hasModifier(event)) {
      const count = takeOperatorCount();
      applyOperatorResult(() => lineEndCountOperation(count), operation);
      return true;
    }
    if (key === "0" && !event.shift && !hasModifier(event)) {
      pendingOperatorCount = 1;
      applyOperatorResult(() => lineBeginningOperation(input.textarea()), operation);
      return true;
    }
    if (key === "^" && !hasModifier(event)) {
      pendingOperatorCount = 1;
      applyOperatorResult(() => firstNonWhitespaceOperation(input.textarea()), operation);
      return true;
    }
    return false;
  }
  function findCharTargetOffset(char, forward, till, count, repeat2 = false) {
    const textarea = input.textarea();
    const start = textarea.cursorOffset;
    const lineStart2 = textarea.plainText.lastIndexOf(`
`, start - 1) + 1;
    const lineEnd2 = textarea.plainText.indexOf(`
`, start);
    const line = textarea.plainText.slice(lineStart2, lineEnd2 === -1 ? textarea.plainText.length : lineEnd2);
    const target = Array.from({ length: count }).reduce((offset, _, index) => {
      if (offset === null)
        return null;
      return findCharTargetInLine(line, offset, char, forward, till && repeat2 && index === 0 ? 2 : 1);
    }, start - lineStart2);
    return target === null ? null : lineStart2 + target;
  }
  function findCharCount(char, forward, till, count, repeat2 = false) {
    const target = findCharTargetOffset(char, forward, till, count, repeat2);
    if (target !== null)
      input.textarea().cursorOffset = target + (till ? forward ? -1 : 1 : 0);
  }
  function findOperation(char, forward, till, count = 1) {
    const textarea = input.textarea();
    const start = textarea.cursorOffset;
    const offset = findCharTargetOffset(char, forward, till, count);
    if (offset === null)
      return charwiseOperation(null);
    if (forward) {
      const spanEnd = till ? offset : offset + 1;
      return charwiseOperation(spanEnd > start ? { start, end: spanEnd } : null);
    }
    const spanStart = till ? offset + 1 : offset;
    return charwiseOperation(spanStart < start ? { start: spanStart, end: start } : null);
  }
  function startOperatorFind(event, operation, find) {
    pendingOperatorFind = { operation, find };
    input.state.setPending(find, (input.state.pendingDisplay() || operation) + find);
    event.preventDefault();
    return true;
  }
  function operatorFind(event, key, operation) {
    if (key === "f" && !event.shift && !hasModifier(event))
      return startOperatorFind(event, operation, "f");
    if (isShifted(event, "f") && !hasModifier(event))
      return startOperatorFind(event, operation, "F");
    if (key === "t" && !event.shift && !hasModifier(event))
      return startOperatorFind(event, operation, "t");
    if (isShifted(event, "t") && !hasModifier(event))
      return startOperatorFind(event, operation, "T");
    return false;
  }
  function startTextObject(event, operation, scope) {
    const display = (input.state.pendingDisplay() || operation) + (scope === "around" ? "a" : "i");
    const count = takeOperatorCount();
    pendingTextObject = { operation, scope, count };
    input.state.setPending(operation, display);
    event.preventDefault();
    return true;
  }
  function operatorTextObject(event, key, operation) {
    if (key === "i" && !event.shift && !hasModifier(event))
      return startTextObject(event, operation, "inner");
    if (key === "a" && !event.shift && !hasModifier(event))
      return startTextObject(event, operation, "around");
    return false;
  }
  function resolveTextObject(event, key, scope, operation, count) {
    if ((key === "w" || isShifted(event, "w")) && !hasModifier(event)) {
      const big = isShifted(event, "w");
      return () => wordTextObjectOperation(input.textarea(), scope === "around", big);
    }
    if ((key === '"' || key === "'" || key === "`") && !hasModifier(event)) {
      return () => quoteTextObjectOperation(input.textarea(), scope === "around", key);
    }
    if (key === "q" && !event.shift && !hasModifier(event)) {
      return () => anyQuoteTextObjectOperation(input.textarea(), scope === "around");
    }
    if ("()[]{}<>".includes(key) && !hasModifier(event)) {
      return () => bracketTextObjectOperation(input.textarea(), scope === "around", key, operation);
    }
    if (key === "p" && !event.shift && !hasModifier(event)) {
      return () => paragraphTextObjectOperation(input.textarea(), scope === "around", operation, count);
    }
    if (key === "l" && !event.shift && !hasModifier(event)) {
      return () => bufferTextObjectOperation(input.textarea());
    }
  }
  function pendingTextObjectOperator(event, key) {
    if (!pendingTextObject)
      return false;
    if (input.state.pending() !== pendingTextObject.operation) {
      pendingTextObject = undefined;
      return false;
    }
    const textObject = pendingTextObject;
    const operation = resolveTextObject(event, key, textObject.scope, textObject.operation, textObject.count);
    pendingTextObject = undefined;
    if (operation) {
      pendingOperatorCount = 1;
      applyOperatorResult(operation, textObject.operation);
      event.preventDefault();
      return true;
    }
    pendingOperatorCount = 1;
    input.state.clearPending();
    event.preventDefault();
    return true;
  }
  function pendingFindOperator(event) {
    if (!pendingOperatorFind)
      return false;
    if (input.state.pending() !== pendingOperatorFind.find) {
      pendingOperatorFind = undefined;
      pendingOperatorCount = 1;
      return false;
    }
    if (isPrintable(event) && !hasModifier(event)) {
      const forward = pendingOperatorFind.find === "f" || pendingOperatorFind.find === "t";
      const till = pendingOperatorFind.find === "t" || pendingOperatorFind.find === "T";
      const char = value(event);
      const operation = pendingOperatorFind.operation;
      const count = takeOperatorCount();
      pendingOperatorFind = undefined;
      applyOperatorResult(() => findOperation(char, forward, till, count), operation);
      input.state.setLastFind({ char, forward, till });
      event.preventDefault();
      return true;
    }
    pendingOperatorFind = undefined;
    pendingOperatorCount = 1;
    input.state.clearPending();
    event.preventDefault();
    return true;
  }
  function undo() {
    if (!tracked())
      return false;
    const next = input.state.undo(snapshot());
    if (!next)
      return false;
    restore(next);
    return true;
  }
  function redo() {
    if (!tracked())
      return false;
    const next = input.state.redo(snapshot());
    if (!next)
      return false;
    restore(next);
    return true;
  }
  function dispatch(event, key) {
    const hadPending = !!input.state.pending();
    const hadCount = !!input.state.count();
    if (!preservesWantedColumn(event, key))
      clearWantedColumn();
    if (!preservesVisualWantedColumn(event, key))
      clearVisualWantedColumn();
    if (input.state.pending() === "r") {
      if (hasModifier(event)) {
        input.state.clearPending();
        return false;
      }
      const next = replaceValue(event);
      if (next !== null) {
        edit(() => {
          const offset = input.textarea().cursorOffset;
          if (deleteUnderCursor(input.textarea())) {
            input.textarea().cursorOffset = offset;
            input.textarea().insertText(next);
            input.textarea().cursorOffset = next === `
` ? offset + 1 : offset;
            input.state.clearPending();
            return true;
          }
          input.state.clearPending();
        });
        event.preventDefault();
        return true;
      }
      input.state.clearPending();
      event.preventDefault();
      return true;
    }
    if (pendingFindOperator(event))
      return true;
    if (pendingTextObjectOperator(event, key))
      return true;
    if (input.state.pending() === "vr" && input.state.isVisual()) {
      if (hasModifier(event)) {
        input.state.clearPending();
        return false;
      }
      const next = replaceValue(event, true);
      if (next !== null) {
        edit(() => {
          replaceSelection(input.textarea(), next, input.state.isVisualLine(), input.state.anchor() ?? undefined);
          clearSelection(input.textarea());
          input.state.clearPending();
          input.state.setMode("normal");
        });
        event.preventDefault();
        return true;
      }
      input.state.clearPending();
      event.preventDefault();
      return true;
    }
    const find = input.state.pending();
    if (find === "f" || find === "F" || find === "t" || find === "T") {
      if (isPrintable(event) && !hasModifier(event)) {
        const forward = find === "f" || find === "t";
        const till = find === "t" || find === "T";
        const char = value(event);
        findCharCount(char, forward, till, takeCount());
        input.state.setLastFind({ char, forward, till });
        input.state.clearPending();
        event.preventDefault();
        return true;
      }
      input.state.clearPending();
      event.preventDefault();
      return true;
    }
    const scroll = vimScroll(event);
    if (scroll) {
      clearPendingOperatorDisplay();
      input.state.clearPending();
      input.scroll(scroll);
      event.preventDefault();
      return true;
    }
    const pendingForDisplay = input.state.pending();
    if ((pendingForDisplay === "c" || pendingForDisplay === "d" || pendingForDisplay === "y") && key === "g" && !event.shift && !hasModifier(event)) {
      pendingOperatorDisplay = pendingForDisplay;
      input.state.setPending("g", (input.state.pendingDisplay() || pendingForDisplay) + "g");
      event.preventDefault();
      return true;
    }
    if (input.state.pending() === "g" && !hasModifier(event)) {
      const operation = pendingOperatorDisplay;
      if ((key === "j" || key === "k" || key === "down" || key === "up") && !event.shift) {
        pendingOperatorDisplay = undefined;
        if (operation) {
          visualLineMotionOperator(key, operation);
        } else {
          const direction = key === "j" || key === "down" ? "down" : "up";
          const count = takeCount();
          prepareDisplayWantedColumn();
          input.state.clearPending();
          moveDisplayVertical(direction, count, visualWantedColumn);
        }
        event.preventDefault();
        return true;
      }
      if (key === "0" && !event.shift || key === "^" || key === "$") {
        pendingOperatorDisplay = undefined;
        if (operation) {
          visualLineHorizontalMotionOperator(key, operation);
        } else {
          const count = takeCount();
          input.state.clearPending();
          clearWantedColumn();
          moveDisplayHorizontal(key, count);
          if (key === "$")
            visualWantedColumn = "end";
        }
        event.preventDefault();
        return true;
      }
    }
    if (input.state.pending() === "g")
      clearPendingOperatorDisplay();
    const jump = vimJump(event, input.state);
    if (jump.handled) {
      if (jump.action) {
        input.state.clearPending();
        clearWantedColumn();
        clearVisualWantedColumn();
        input.jump(jump.action);
      }
      event.preventDefault();
      return true;
    }
    const navigation = vimWindowNavigation(event, input.state);
    if (navigation.handled) {
      if (navigation.action) {
        input.state.clearPending();
        input.navigate?.(navigation.action);
      }
      event.preventDefault();
      return true;
    }
    if (key === "escape") {
      if (input.state.isVisual()) {
        clearSelection(input.textarea());
        input.state.setMode("normal");
        event.preventDefault();
        return true;
      }
      if (!input.state.pending() && input.state.count()) {
        input.state.clearCount();
        event.preventDefault();
        return true;
      }
      if (!input.state.pending())
        return false;
      input.state.clearPending();
      event.preventDefault();
      return true;
    }
    if (isCountInput(event, key)) {
      input.state.appendCountDigit(key);
      event.preventDefault();
      return true;
    }
    if (key === "." && !event.shift && !hasModifier(event) && !input.state.isVisual() && !input.state.pending()) {
      const repeat2 = input.state.repeat();
      if (repeat2)
        repeat2.run();
      event.preventDefault();
      return true;
    }
    if (key === "u" && !event.shift && !hasModifier(event) && !input.state.isVisual() && !input.state.pending()) {
      undo();
      event.preventDefault();
      return true;
    }
    if (key === "r" && !!event.ctrl && !event.shift && !event.meta && !event.super && !input.state.isVisual() && !input.state.pending()) {
      redo();
      event.preventDefault();
      return true;
    }
    if (input.state.isVisual()) {
      const a = input.state.anchor();
      const lw = input.state.isVisualLine();
      if (key === "~" && !hasModifier(event)) {
        edit(() => {
          toggleSelectionCase(input.textarea(), lw, a ?? undefined);
          clearSelection(input.textarea());
          input.state.setMode("normal");
        });
        event.preventDefault();
        return true;
      }
      if (key === "r" && !event.shift && !hasModifier(event)) {
        input.state.setPending("vr");
        event.preventDefault();
        return true;
      }
      if ((key === "i" || key === "a") && !event.shift && !hasModifier(event)) {
        event.preventDefault();
        return true;
      }
      if (key === "o" && !event.shift && !hasModifier(event)) {
        const cursor = input.textarea().cursorOffset;
        const anchor = input.state.anchor();
        if (anchor !== null) {
          input.textarea().cursorOffset = anchor;
          input.state.setAnchor(cursor);
          toggleVisualEnd(input.textarea(), cursor, input.state.isVisualLine());
        }
        event.preventDefault();
        return true;
      }
      if ((isShifted(event, "i") || isShifted(event, "a") || isShifted(event, "o")) && !hasModifier(event)) {
        event.preventDefault();
        return true;
      }
      if ((key === "d" || key === "x") && !event.shift && !hasModifier(event)) {
        edit(() => {
          const reg = deleteSelection(input.textarea(), lw, a ?? undefined);
          if (reg)
            setRegister(reg);
          clearSelection(input.textarea());
          input.state.setMode("normal");
        });
        event.preventDefault();
        return true;
      }
      if (isShifted(event, "d") && !hasModifier(event)) {
        edit(() => {
          const reg = deleteLine(input.textarea(), a ?? undefined);
          if (reg)
            setRegister(reg);
          clearSelection(input.textarea());
          input.state.setMode("normal");
        });
        event.preventDefault();
        return true;
      }
      if (key === "y" && !event.shift && !hasModifier(event)) {
        const reg = yankSelection(input.textarea(), lw, a ?? undefined);
        if (reg)
          setRegister(reg, true);
        clearSelection(input.textarea());
        input.state.setMode("normal");
        event.preventDefault();
        return true;
      }
      if (key === "c" && !event.shift && !hasModifier(event)) {
        begin(() => {
          const reg = deleteSelection(input.textarea(), lw, a ?? undefined);
          if (reg)
            setRegister(reg);
          clearSelection(input.textarea());
          input.state.setMode("insert");
        });
        event.preventDefault();
        return true;
      }
      if (isShifted(event, "c") && !hasModifier(event)) {
        begin(() => {
          const reg = substituteLine(input.textarea(), a ?? undefined);
          if (reg)
            setRegister(reg);
          clearSelection(input.textarea());
          input.state.setMode("insert");
        });
        event.preventDefault();
        return true;
      }
      if (key === "p" && !event.shift && !hasModifier(event)) {
        edit(() => {
          const deleted = pasteOverVisualSelection(input.textarea(), register(), lw, a ?? undefined);
          if (deleted)
            setRegister(deleted);
          clearSelection(input.textarea());
          input.state.setMode("normal");
        });
        event.preventDefault();
        return true;
      }
      if (key === "v" && !event.shift && !hasModifier(event)) {
        if (lw) {
          input.state.setMode("visual");
          event.preventDefault();
          return true;
        }
        clearSelection(input.textarea());
        input.state.setMode("normal");
        event.preventDefault();
        return true;
      }
      if (isShifted(event, "v") && !hasModifier(event)) {
        if (lw) {
          clearSelection(input.textarea());
          input.state.setMode("normal");
          event.preventDefault();
          return true;
        }
        input.state.setMode("visual-line");
        event.preventDefault();
        return true;
      }
    }
    if (key === ":" && !hasModifier(event) && !hadPending && !hadCount) {
      input.commandPalette?.();
      input.state.clearPending();
      event.preventDefault();
      return true;
    }
    function operatorPending(op, event2, key2) {
      if (hasModifier(event2)) {
        pendingOperatorCount = 1;
        input.state.clearPending();
        return false;
      }
      if (isPendingOperatorCountInput(event2, key2)) {
        const count = input.state.count();
        input.state.appendCountDigit(key2);
        if (input.state.count() !== count)
          input.state.setPending(op, (input.state.pendingDisplay() || op) + key2);
        event2.preventDefault();
        return true;
      }
      if (key2 === op && !event2.shift) {
        doubledOperator(op);
        event2.preventDefault();
        return true;
      }
      if (verticalMotionOperator(event2, key2, op)) {
        event2.preventDefault();
        return true;
      }
      if (wordOperator(event2, key2, op)) {
        event2.preventDefault();
        return true;
      }
      if (lineBoundaryMotion(event2, key2, op)) {
        event2.preventDefault();
        return true;
      }
      if (operatorTextObject(event2, key2, op))
        return true;
      if (paragraphOperator(key2, op)) {
        event2.preventDefault();
        return true;
      }
      if (matchingBracketOperator(key2, op)) {
        event2.preventDefault();
        return true;
      }
      if (operatorFind(event2, key2, op))
        return true;
      pendingOperatorCount = 1;
      pendingTextObject = undefined;
      input.state.clearPending();
      return;
    }
    function doubledOperator(op) {
      if (op === "c") {
        const count = takeOperatorCount();
        begin(() => {
          const reg = substituteLineCount(count);
          if (reg)
            setRegister(reg);
          input.state.clearPending();
          input.state.setMode("insert");
        });
        return;
      }
      if (op === "d") {
        const count = takeOperatorCount();
        edit(() => {
          const reg = deleteLineCount(count);
          if (reg)
            setRegister(reg);
          input.state.clearPending();
        });
        return;
      }
      const result = yankLineCount(takeOperatorCount());
      setRegister(result.register, true);
      if (result.span.end > result.span.start)
        input.flash?.(result.span);
      input.state.clearPending();
    }
    if ((key === "/" || key === "?") && !hasModifier(event) && !hadPending && !hadCount && !input.state.isVisual()) {
      if (input.copySearchStart?.(key === "?" ? "backward" : "forward") !== false) {
        input.state.clearPending();
        event.preventDefault();
        return true;
      }
    }
    const pendingOperator = input.state.pending();
    if (pendingOperator === "c" || pendingOperator === "d" || pendingOperator === "y") {
      const handled = operatorPending(pendingOperator, event, key);
      if (handled !== undefined)
        return handled;
    }
    if (key === "return" && !hasModifier(event)) {
      input.submit();
      input.state.clearPending();
      event.preventDefault();
      return true;
    }
    if ((key === "/" || key === "@") && !hasModifier(event)) {
      const autocomplete = input.autocomplete?.(key);
      if (autocomplete && input.textarea().cursorOffset === 0 && input.textarea().plainText.length === 0) {
        input.state.setMode("insert");
        input.textarea().insertText(autocomplete);
        event.preventDefault();
        return true;
      }
      event.preventDefault();
      return true;
    }
    if (key === "c" && !event.shift && !hasModifier(event))
      return startOperator(event, "c");
    if (key === "d" && !event.shift && !hasModifier(event))
      return startOperator(event, "d");
    if (key === "y" && !event.shift && !hasModifier(event))
      return startOperator(event, "y");
    if (key === "r" && !event.shift && !hasModifier(event)) {
      input.state.setPending("r");
      event.preventDefault();
      return true;
    }
    if (key === "p" && !event.shift && !hasModifier(event)) {
      const reg = countedRegister(register(), takeCount());
      edit(() => {
        const deleted = input.pasteOverSelection?.() !== false ? pasteOverSelection(input.textarea(), reg) : null;
        if (deleted)
          setRegister(deleted);
        else
          pasteAfter(input.textarea(), reg);
      });
      event.preventDefault();
      return true;
    }
    if (isShifted(event, "p") && !hasModifier(event)) {
      const reg = countedRegister(register(), takeCount());
      edit(() => {
        const deleted = input.pasteOverSelection?.() !== false ? pasteOverSelection(input.textarea(), reg) : null;
        if (deleted)
          setRegister(deleted);
        else
          pasteBefore(input.textarea(), reg);
      });
      event.preventDefault();
      return true;
    }
    if ((key === "f" || key === "t") && !event.shift && !hasModifier(event)) {
      input.state.setPending(key, input.state.count() + key);
      event.preventDefault();
      return true;
    }
    if ((isShifted(event, "f") || isShifted(event, "t")) && !hasModifier(event)) {
      const find2 = isShifted(event, "f") ? "F" : "T";
      input.state.setPending(find2, input.state.count() + find2);
      event.preventDefault();
      return true;
    }
    if (key === ";" && !event.shift && !hasModifier(event)) {
      const last = input.state.lastFind();
      if (last)
        findCharCount(last.char, last.forward, last.till, takeCount(), true);
      event.preventDefault();
      return true;
    }
    if (key === "," && !event.shift && !hasModifier(event)) {
      const last = input.state.lastFind();
      if (last)
        findCharCount(last.char, !last.forward, last.till, takeCount(), true);
      event.preventDefault();
      return true;
    }
    if (isShifted(event, "s") && !hasModifier(event)) {
      begin(() => {
        input.state.clearPending();
        const reg = substituteLine(input.textarea());
        if (reg)
          setRegister(reg);
        input.state.setMode("insert");
      });
      event.preventDefault();
      return true;
    }
    if (isShifted(event, "d") && !hasModifier(event)) {
      edit(() => {
        const reg = deleteLineEnd(input.textarea());
        if (reg)
          setRegister(reg);
      });
      event.preventDefault();
      return true;
    }
    if (isShifted(event, "c") && !hasModifier(event)) {
      begin(() => {
        const reg = substituteLineEnd(input.textarea());
        if (reg)
          setRegister(reg);
        input.state.setMode("insert");
      });
      event.preventDefault();
      return true;
    }
    if (isShifted(event, "r") && !hasModifier(event)) {
      begin(() => {
        input.state.setReplace(input.textarea().cursorOffset);
        input.state.setTyped(false);
        input.state.setMode("replace");
      }, { replace: true });
      event.preventDefault();
      return true;
    }
    if (key === "v" && !event.shift && !hasModifier(event)) {
      input.state.setAnchor(input.textarea().cursorOffset);
      input.state.setMode("visual");
      syncSelection(input.textarea(), input.textarea().cursorOffset);
      event.preventDefault();
      return true;
    }
    if (isShifted(event, "v") && !hasModifier(event)) {
      input.state.setAnchor(input.textarea().cursorOffset);
      input.state.setMode("visual-line");
      syncSelection(input.textarea(), input.textarea().cursorOffset, true);
      event.preventDefault();
      return true;
    }
    if (key === "i" && !event.shift && !hasModifier(event)) {
      begin(() => {
        input.state.setMode("insert");
      });
      event.preventDefault();
      return true;
    }
    if (isShifted(event, "i") && !hasModifier(event)) {
      begin(() => {
        insertLineStart(input.textarea());
        input.state.setMode("insert");
      });
      event.preventDefault();
      return true;
    }
    if (key === "a" && !event.shift && !hasModifier(event)) {
      begin(() => {
        appendAfterCursor(input.textarea());
        input.state.setMode("insert");
      });
      event.preventDefault();
      return true;
    }
    if (isShifted(event, "a") && !hasModifier(event)) {
      begin(() => {
        appendLineEnd(input.textarea());
        input.state.setMode("insert");
      });
      event.preventDefault();
      return true;
    }
    if (key === "o" && !event.shift && !hasModifier(event)) {
      begin(() => {
        openLineBelow(input.textarea());
        input.state.setMode("insert");
      });
      event.preventDefault();
      return true;
    }
    if (isShifted(event, "o") && !hasModifier(event)) {
      begin(() => {
        openLineAbove(input.textarea());
        input.state.setMode("insert");
      });
      event.preventDefault();
      return true;
    }
    if (key === "h" && !event.shift && !hasModifier(event)) {
      countedMotion(() => moveLeft(input.textarea()));
      event.preventDefault();
      return true;
    }
    if (key === "l" && !event.shift && !hasModifier(event)) {
      countedMotion(() => moveRight(input.textarea()));
      event.preventDefault();
      return true;
    }
    if (isShifted(event, "j") && !hasModifier(event)) {
      edit(() => {
        input.state.clearPending();
        joinLines(input.textarea());
      });
      event.preventDefault();
      return true;
    }
    if ((key === "j" || key === "down") && !event.shift && !hasModifier(event)) {
      const before = input.textarea().cursorOffset;
      countedMotion(() => moveVertical("down"));
      if (key === "down" && !input.state.isVisual() && input.textarea().cursorOffset === before)
        return false;
      event.preventDefault();
      return true;
    }
    if (isShifted(event, "h") && !hasModifier(event)) {
      input.jump("high");
      event.preventDefault();
      return true;
    }
    if (isShifted(event, "m") && !hasModifier(event)) {
      input.jump("middle");
      event.preventDefault();
      return true;
    }
    if (isShifted(event, "l") && !hasModifier(event)) {
      input.jump("low");
      event.preventDefault();
      return true;
    }
    if ((key === "k" || key === "up") && !event.shift && !hasModifier(event)) {
      const before = input.textarea().cursorOffset;
      countedMotion(() => moveVertical("up"));
      if (key === "up" && !input.state.isVisual() && input.textarea().cursorOffset === before)
        return false;
      event.preventDefault();
      return true;
    }
    if (key === "0" && !event.shift && !hasModifier(event)) {
      moveLineBeginning(input.textarea());
      event.preventDefault();
      return true;
    }
    if ((key === "^" || key === "_") && !hasModifier(event)) {
      moveFirstNonWhitespace(input.textarea());
      event.preventDefault();
      return true;
    }
    if (key === "$" && !hasModifier(event)) {
      repeatCount(takeCount() - 1, () => moveLineDown(input.textarea(), 0));
      moveLineEnd(input.textarea());
      wantedColumn = "end";
      event.preventDefault();
      return true;
    }
    if (key === "%" && !hasModifier(event)) {
      moveMatchingBracket(input.textarea());
      event.preventDefault();
      return true;
    }
    if (key === "{" && !hasModifier(event)) {
      countedMotion(() => movePreviousParagraph(input.textarea()));
      event.preventDefault();
      return true;
    }
    if (key === "}" && !hasModifier(event)) {
      countedMotion(() => moveNextParagraph(input.textarea()));
      event.preventDefault();
      return true;
    }
    if (key === "s" && !event.shift && !hasModifier(event)) {
      begin(() => {
        const cursor = input.textarea().cursorOffset;
        const reg = deleteUnderCursor(input.textarea());
        if (reg) {
          setRegister(reg);
          input.textarea().cursorOffset = cursor;
        }
        input.state.setMode("insert");
      });
      event.preventDefault();
      return true;
    }
    if (key === "x" && !event.shift && !hasModifier(event)) {
      edit(() => {
        const reg = deleteUnderCursor(input.textarea());
        if (reg)
          setRegister(reg);
      });
      event.preventDefault();
      return true;
    }
    if (key === "~" && !hasModifier(event)) {
      const count = takeCount();
      edit(() => {
        for (let index = 0;index < count; index++) {
          const before = input.textarea().cursorOffset;
          toggleCase(input.textarea());
          if (input.textarea().cursorOffset === before)
            break;
        }
      });
      event.preventDefault();
      return true;
    }
    if (key === "w" && !event.shift && !hasModifier(event)) {
      countedMotion(() => moveWordNext(input.textarea()));
      event.preventDefault();
      return true;
    }
    if (key === "b" && !event.shift && !hasModifier(event)) {
      countedMotion(() => moveWordPrev(input.textarea()));
      event.preventDefault();
      return true;
    }
    if (key === "e" && !event.shift && !hasModifier(event)) {
      countedMotion(() => moveWordEnd(input.textarea()));
      event.preventDefault();
      return true;
    }
    if (isShifted(event, "w") && !hasModifier(event)) {
      countedMotion(() => moveBigWordNext(input.textarea()));
      event.preventDefault();
      return true;
    }
    if (isShifted(event, "b") && !hasModifier(event)) {
      countedMotion(() => moveBigWordPrev(input.textarea()));
      event.preventDefault();
      return true;
    }
    if (isShifted(event, "e") && !hasModifier(event)) {
      countedMotion(() => moveBigWordEnd(input.textarea()));
      event.preventDefault();
      return true;
    }
    if (key === "w" && event.ctrl && !event.shift && !event.meta && !event.super) {
      input.state.setPending("w", "^W");
      event.preventDefault();
      return true;
    }
    if (key === "backspace" || key === "delete") {
      event.preventDefault();
      return true;
    }
    if (isPrintable(event) && !hasModifier(event)) {
      event.preventDefault();
      return true;
    }
    return false;
  }
  function copyMotion(offset) {
    input.setCopyCol?.(offset);
  }
  function copy(event, key) {
    if (input.copySearchActive?.()) {
      if (key === "return") {
        input.copySearchSubmit?.();
        event.preventDefault();
        return true;
      }
      if (key === "escape") {
        input.copySearchCancel?.();
        event.preventDefault();
        return true;
      }
      if (key === "backspace" || key === "delete" || key === "h" && event.ctrl && !event.meta && !event.super) {
        input.copySearchBackspace?.();
        event.preventDefault();
        return true;
      }
      if (!hasModifier(event) && isPrintable(event)) {
        input.copySearchAppend?.(value(event));
        event.preventDefault();
        return true;
      }
      event.preventDefault();
      return true;
    }
    if (input.state.pending() === "" && isShifted(event, "y") && !hasModifier(event)) {
      if (input.copyIsVisual?.()) {
        input.copyYank?.();
        input.state.setMode("normal");
        input.copyExit?.();
        event.preventDefault();
        return true;
      }
      input.copyYankLine?.();
      setTimeout(() => {
        input.state.setMode("normal");
        input.copyExit?.();
      }, 70);
      event.preventDefault();
      return true;
    }
    if (key === "y" && !event.shift && !hasModifier(event)) {
      if (input.copyIsVisual?.()) {
        input.copyYank?.();
        input.copyExitPreserveScroll?.();
        input.state.setMode("normal");
        event.preventDefault();
        return true;
      }
      if (input.state.pending() === "y") {
        input.state.clearPending();
        input.copyYankLine?.();
        setTimeout(() => {
          input.copyExitPreserveScroll?.();
          input.state.setMode("normal");
        }, 70);
        event.preventDefault();
        return true;
      }
      input.state.setPending("y");
      event.preventDefault();
      return true;
    }
    const pending = input.state.pending();
    const clearCopyPending = () => {
      if (input.state.pending())
        input.state.clearPending();
    };
    if (pending === "y") {
      input.state.clearPending();
    }
    if (key === "return") {
      if (!event.shift && !input.copyIsVisual?.() && (input.copyToggleCollapsed?.() || input.copyActivate?.())) {
        event.preventDefault();
        return true;
      }
      input.copyCopy?.();
      if (event.shift) {
        input.state.setMode("normal");
        input.copyExit?.();
        event.preventDefault();
        return true;
      }
      input.copyExitPreserveScroll?.();
      input.state.setMode("normal");
      event.preventDefault();
      return true;
    }
    if (key === "v" && event.ctrl && !event.shift && !event.meta && !event.super) {
      clearCopyPending();
      input.copyVisual?.("block");
      event.preventDefault();
      return true;
    }
    if (key === "q") {
      input.state.setMode("normal");
      input.copyExit?.();
      event.preventDefault();
      return true;
    }
    if (pending === "" && key === "i" && !event.shift && !hasModifier(event)) {
      begin();
      input.copyFocusInput?.();
      input.state.setMode("insert");
      event.preventDefault();
      return true;
    }
    if (key === "escape") {
      if (input.copyIsVisual?.()) {
        input.copyExitVisual?.();
        event.preventDefault();
        return true;
      }
      if (input.copySearchHighlighted?.() && input.copySearchClear?.()) {
        event.preventDefault();
        return true;
      }
      input.state.setMode("normal");
      input.copyExit?.();
      event.preventDefault();
      return true;
    }
    if (input.state.pending() === "w") {
      if (key === "j" || key === "w") {
        if (input.copyIsVisual?.()) {
          input.copyExitVisual?.();
          event.preventDefault();
          return true;
        }
        input.state.setSkipExitOnModeChange(true);
        input.state.setExitScrollToBottom(false);
        input.state.setMode("normal");
        input.copyExit?.(false);
        event.preventDefault();
        return true;
      }
      input.state.clearPending();
    }
    if (key === "w" && event.ctrl && !event.shift && !event.meta && !event.super) {
      input.state.setPending("w", "^W");
      event.preventDefault();
      return true;
    }
    const scroll = vimScroll(event);
    if (scroll) {
      clearCopyPending();
      input.scroll(scroll);
      event.preventDefault();
      return true;
    }
    const jump = vimJump(event, input.state);
    if (jump.handled) {
      if (jump.action)
        input.copyJump ? input.copyJump(jump.action) : input.jump(jump.action);
      event.preventDefault();
      return true;
    }
    if (hasModifier(event)) {
      clearCopyPending();
      return false;
    }
    if (pending === "" && key === "/") {
      clearCopyPending();
      input.copySearchStart?.("forward");
      event.preventDefault();
      return true;
    }
    if (pending === "" && key === "?") {
      clearCopyPending();
      input.copySearchStart?.("backward");
      event.preventDefault();
      return true;
    }
    if (pending === "" && key === "n" && !event.shift) {
      clearCopyPending();
      input.copySearchNext?.();
      event.preventDefault();
      return true;
    }
    if (pending === "" && isShifted(event, "n")) {
      clearCopyPending();
      input.copySearchPrevious?.();
      event.preventDefault();
      return true;
    }
    if (isShifted(event, "h")) {
      clearCopyPending();
      input.copyJump?.("high");
      event.preventDefault();
      return true;
    }
    if (isShifted(event, "m")) {
      clearCopyPending();
      input.copyJump?.("middle");
      event.preventDefault();
      return true;
    }
    if (isShifted(event, "l")) {
      clearCopyPending();
      input.copyJump?.("low");
      event.preventDefault();
      return true;
    }
    if (isShifted(event, "v")) {
      clearCopyPending();
      input.copyVisual?.("line");
      event.preventDefault();
      return true;
    }
    if (key === "v" && !event.shift) {
      clearCopyPending();
      input.copyVisual?.("char");
      event.preventDefault();
      return true;
    }
    if (key === "o" && !hasModifier(event) && input.copyIsVisual?.() && !isShifted(event, "o")) {
      input.copyToggleVisualEnd?.();
      event.preventDefault();
      return true;
    }
    if (pending === "f" || pending === "F" || pending === "t" || pending === "T") {
      if (key.length === 1) {
        const forward = pending === "f" || pending === "t";
        const till = pending === "t" || pending === "T";
        const text = input.copyText?.() ?? "";
        const pos2 = input.copyCol?.() ?? 0;
        const col = findCharInLine(text, pos2, key, forward, till);
        input.state.setLastFind({ char: key, forward, till });
        input.state.clearPending();
        copyMotion(col);
        event.preventDefault();
        return true;
      }
      input.state.clearPending();
      event.preventDefault();
      return true;
    }
    if (pending === "z") {
      input.state.clearPending();
      if (key === "z")
        input.copyScroll?.("center");
      else if (key === "t")
        input.copyScroll?.("top");
      else if (key === "b")
        input.copyScroll?.("bottom");
      event.preventDefault();
      return true;
    }
    if (key === "j" || key === "down") {
      input.copy?.("down");
      event.preventDefault();
      return true;
    }
    if (key === "k" || key === "up") {
      input.copy?.("up");
      event.preventDefault();
      return true;
    }
    if (key === "h" || key === "left") {
      input.copy?.("left");
      event.preventDefault();
      return true;
    }
    if (key === "l" || key === "right") {
      input.copy?.("right");
      event.preventDefault();
      return true;
    }
    const pos = input.copyCol?.() ?? 0;
    if (key === "0") {
      copyMotion(0);
      input.setCopyStick?.("start");
      event.preventDefault();
      return true;
    }
    if (key === "^" || key === "_") {
      const text = input.copyText?.() ?? "";
      copyMotion(firstNonWhitespace(text, 0));
      input.setCopyStick?.("first");
      event.preventDefault();
      return true;
    }
    if (key === "$") {
      const text = input.copyText?.() ?? "";
      copyMotion(Math.max(0, text.length - 1));
      input.setCopyStick?.("end");
      event.preventDefault();
      return true;
    }
    if (key === "%") {
      if (pending === "y") {
        input.state.clearPending();
        if (input.copyYankMatchingBracket?.()) {
          setTimeout(() => {
            input.copyExitPreserveScroll?.();
            input.state.setMode("normal");
          }, 70);
        }
        event.preventDefault();
        return true;
      }
      if (!input.copyMatchingBracket?.()) {
        const text = input.copyText?.() ?? "";
        const target = matchingBracketTarget(text, pos);
        if (target !== null)
          copyMotion(target);
      }
      event.preventDefault();
      return true;
    }
    if (key === "z" && !event.shift) {
      input.state.setPending("z");
      event.preventDefault();
      return true;
    }
    if (key === "w" && !event.shift) {
      if (input.copyWordNext?.(false)) {
        event.preventDefault();
        return true;
      }
      const text = input.copyText?.() ?? "";
      const col = nextWordStart(text, pos, false);
      copyMotion(Math.min(col, Math.max(0, text.length - 1)));
      event.preventDefault();
      return true;
    }
    if (key === "b" && !event.shift) {
      if (input.copyWordPrev?.(false)) {
        event.preventDefault();
        return true;
      }
      const text = input.copyText?.() ?? "";
      copyMotion(prevWordStart(text, pos, false));
      event.preventDefault();
      return true;
    }
    if (key === "e" && !event.shift) {
      if (input.copyWordEnd?.(false)) {
        event.preventDefault();
        return true;
      }
      const text = input.copyText?.() ?? "";
      copyMotion(wordEnd(text, pos, false));
      event.preventDefault();
      return true;
    }
    if (isShifted(event, "w")) {
      if (input.copyWordNext?.(true)) {
        event.preventDefault();
        return true;
      }
      const text = input.copyText?.() ?? "";
      const col = nextWordStart(text, pos, true);
      copyMotion(Math.min(col, Math.max(0, text.length - 1)));
      event.preventDefault();
      return true;
    }
    if (isShifted(event, "b")) {
      if (input.copyWordPrev?.(true)) {
        event.preventDefault();
        return true;
      }
      const text = input.copyText?.() ?? "";
      copyMotion(prevWordStart(text, pos, true));
      event.preventDefault();
      return true;
    }
    if (isShifted(event, "e")) {
      if (input.copyWordEnd?.(true)) {
        event.preventDefault();
        return true;
      }
      const text = input.copyText?.() ?? "";
      copyMotion(wordEnd(text, pos, true));
      event.preventDefault();
      return true;
    }
    if (key === "{" && !hasModifier(event)) {
      input.copyPreviousParagraph?.();
      event.preventDefault();
      return true;
    }
    if (key === "}" && !hasModifier(event)) {
      input.copyNextParagraph?.();
      event.preventDefault();
      return true;
    }
    if ((key === "f" || key === "t") && !event.shift) {
      input.state.setPending(key, key);
      event.preventDefault();
      return true;
    }
    if (isShifted(event, "f")) {
      input.state.setPending("F", "F");
      event.preventDefault();
      return true;
    }
    if (isShifted(event, "t")) {
      input.state.setPending("T", "T");
      event.preventDefault();
      return true;
    }
    if (key === ";") {
      const last = input.state.lastFind();
      if (last) {
        const text = input.copyText?.() ?? "";
        copyMotion(findCharInLine(text, pos, last.char, last.forward, last.till, true));
      }
      event.preventDefault();
      return true;
    }
    if (key === ",") {
      const last = input.state.lastFind();
      if (last) {
        const text = input.copyText?.() ?? "";
        copyMotion(findCharInLine(text, pos, last.char, !last.forward, last.till, true));
      }
      event.preventDefault();
      return true;
    }
    if (isPrintable(event)) {
      event.preventDefault();
      return true;
    }
    return false;
  }
  return {
    cancelPending,
    beginInsertEdit: repeat.begin,
    recordInsertText: repeat.recordInsertText,
    handleKey(event) {
      if (!input.enabled())
        return false;
      if (input.state.replaying()) {
        event.preventDefault();
        return true;
      }
      if (input.state.isReplace()) {
        if (event.name === "escape") {
          const start = input.state.replace();
          const typed = input.state.typed();
          input.state.setMode("normal");
          if (typed && start !== null) {
            input.textarea().cursorOffset = Math.max(start, input.textarea().cursorOffset - 1);
          }
          input.state.commitEdit(snapshot());
          repeat.commit(snapshot());
          event.preventDefault();
          return true;
        }
        if (isPrintable(event) && !hasModifier(event)) {
          const next = value(event);
          repeat.recordReplaceChar(next);
          replaceUnderCursor(input.textarea(), next);
          input.state.setTyped(true);
          event.preventDefault();
          return true;
        }
        return false;
      }
      if (input.state.isCopy()) {
        clearEscapePending();
        const mapped2 = input.copySearchActive?.() ? event : langmapped(event);
        return copy(mapped2, normalizedKeyName(mapped2));
      }
      if (input.state.isInsert()) {
        if (event.name === "escape") {
          clearEscapePending();
          input.state.setMode("normal");
          input.state.commitEdit(snapshot());
          moveLeft(input.textarea());
          repeat.commit(snapshot());
          event.preventDefault();
          return true;
        }
        if (escapeSeq) {
          const key2 = normalizedKeyName(event);
          if (escapePending) {
            clearEscapePending();
            if (key2 === escapeSecond && !hasModifier(event)) {
              const pos = input.textarea().cursorOffset;
              if (pos > 0) {
                const start = input.textarea().editBuffer.offsetToPosition(pos - 1);
                const end = input.textarea().editBuffer.offsetToPosition(pos);
                if (start && end) {
                  input.textarea().deleteRange(start.row, start.col, end.row, end.col);
                  input.textarea().cursorOffset = pos - 1;
                }
              }
              input.state.setMode("normal");
              input.state.commitEdit(snapshot());
              moveLeft(input.textarea());
              repeat.commit(snapshot());
              event.preventDefault();
              return true;
            }
            return false;
          }
          if (key2 === escapeFirst && !hasModifier(event)) {
            escapePending = true;
            escapeTimer = setTimeout(clearEscapePending, 300);
            return false;
          }
        }
        clearEscapePending();
        return false;
      }
      clearEscapePending();
      const mapped = langmapped(event);
      const key = normalizedKeyName(mapped);
      const result = dispatch(mapped, key);
      if (result && input.state.count() && !input.state.pending() && !isCountInput(mapped, key))
        input.state.clearCount();
      if (result && input.state.isVisual()) {
        const a = input.state.anchor();
        if (a !== null)
          syncSelection(input.textarea(), a, input.state.isVisualLine());
      }
      return result;
    }
  };
}

// src/vim/indicator.ts
function useVimIndicator(input) {
  return () => {
    if (!input.enabled() || !input.active())
      return;
    const key = input.state.pending();
    if (key)
      return (input.state.pendingDisplay() || key) + "..";
    if (input.state.count())
      return input.state.count();
    if (input.state.isCopy()) {
      const search = input.copySearch?.();
      if (search !== undefined)
        return search;
      if (input.copyVisual?.() === "char")
        return "-- VISUAL --";
      if (input.copyVisual?.() === "line")
        return "-- VISUAL LINE --";
      if (input.copyVisual?.() === "block")
        return "-- VISUAL BLOCK --";
      return "-- COPY --";
    }
    if (input.state.mode() === "insert")
      return "-- INSERT --";
    if (input.state.mode() === "replace")
      return "-- REPLACE --";
    if (input.state.mode() === "visual-line")
      return "-- VISUAL LINE --";
    if (input.state.mode() === "visual")
      return "-- VISUAL --";
  };
}

// src/vim/state.ts
import { createEffect, createMemo, createSignal } from "solid-js";
var VIM_COUNT_MAX = 9999;
var VIM_COUNT_MAX_DIGITS = String(VIM_COUNT_MAX).length;
function createVimState(input) {
  const [mode, setMode] = createSignal(input.initial?.() ?? "insert");
  const [pending, setPendingValue] = createSignal("");
  const [pendingDisplay, setPendingDisplay] = createSignal("");
  const [count, setCountValue] = createSignal("");
  const [lastFind, setLastFind] = createSignal(null);
  const [register, setRegister] = createSignal(null);
  const [anchor, setAnchor] = createSignal(null);
  const [replace, setReplace] = createSignal(null);
  const [typed, setTyped] = createSignal(false);
  const [undos, setUndos] = createSignal([]);
  const [redos, setRedos] = createSignal([]);
  const [edit, setEdit] = createSignal(null);
  const [repeat, setRepeat] = createSignal(null);
  const [replaying, setReplaying] = createSignal(false);
  const [skipExitOnModeChange, setSkipExitOnModeChange] = createSignal(false);
  const [exitScrollToBottom, setExitScrollToBottom] = createSignal(true);
  const cancelEditCallbacks = new Set;
  function setPending(next, display = "") {
    setPendingValue(next);
    setPendingDisplay(display);
  }
  function clearPending() {
    if (pending())
      setPendingValue("");
    if (pendingDisplay())
      setPendingDisplay("");
    clearCount();
  }
  function clearCount() {
    if (count())
      setCountValue("");
  }
  function appendCountDigit(digit) {
    setCountValue((value) => value.length >= VIM_COUNT_MAX_DIGITS ? value : value + digit);
  }
  function takeCount(defaultValue = 1) {
    const value = count() ? Number(count()) : defaultValue;
    clearCount();
    return Math.max(1, Math.min(Number.isSafeInteger(value) ? value : defaultValue, VIM_COUNT_MAX));
  }
  function clearEdit() {
    setEdit(null);
  }
  function cancelOpenEdit() {
    cancelEditCallbacks.forEach((callback) => callback());
    clearEdit();
  }
  function clearHistory() {
    cancelOpenEdit();
    setUndos([]);
    setRedos([]);
    setRepeat(null);
  }
  function changeMode(next) {
    clearPending();
    clearCount();
    if (next !== "visual" && next !== "visual-line")
      setAnchor(null);
    if (next !== "replace") {
      setReplace(null);
      setTyped(false);
    }
    setMode(next);
  }
  function push(before, after) {
    clearEdit();
    if (before.text === after.text && before.cursor === after.cursor)
      return;
    setUndos((list) => [...list, { before, after }]);
    setRedos([]);
  }
  createEffect(() => {
    const enabled = input.enabled();
    if (!enabled) {
      if (mode() !== "insert")
        setMode("insert");
      clearPending();
      cancelOpenEdit();
      return;
    }
  });
  return {
    mode,
    setMode: changeMode,
    pending,
    pendingDisplay,
    setPending,
    clearPending,
    count,
    appendCountDigit,
    clearCount,
    takeCount,
    lastFind,
    setLastFind,
    register,
    setRegister,
    anchor,
    setAnchor,
    replace,
    setReplace,
    typed,
    setTyped,
    beginEdit(snapshot) {
      setEdit(snapshot);
    },
    commitEdit(snapshot) {
      const start = edit();
      clearEdit();
      if (!start)
        return;
      push(start, snapshot);
    },
    cancelEdit() {
      cancelOpenEdit();
    },
    onCancelEdit(callback) {
      cancelEditCallbacks.add(callback);
      return () => cancelEditCallbacks.delete(callback);
    },
    repeat,
    setRepeat(next) {
      setRepeat(next);
    },
    replaying,
    setReplaying,
    push,
    undo(snapshot) {
      const item = undos()[undos().length - 1];
      if (!item)
        return;
      setUndos((list) => list.slice(0, -1));
      setRedos((list) => [...list, snapshot]);
      clearEdit();
      return item.before;
    },
    redo(snapshot) {
      const item = redos()[redos().length - 1];
      if (!item)
        return;
      setRedos((list) => list.slice(0, -1));
      setUndos((list) => [...list, { before: snapshot, after: item }]);
      clearEdit();
      return item;
    },
    resetHistory: clearHistory,
    reset() {
      clearPending();
      clearCount();
      setAnchor(null);
      setReplace(null);
      setTyped(false);
      clearHistory();
      setMode("insert");
    },
    canUndo: createMemo(() => undos().length > 0),
    canRedo: createMemo(() => redos().length > 0),
    isInsert: createMemo(() => mode() === "insert"),
    isReplace: createMemo(() => mode() === "replace"),
    isVisual: createMemo(() => mode() === "visual" || mode() === "visual-line"),
    isVisualLine: createMemo(() => mode() === "visual-line"),
    isCopy: createMemo(() => mode() === "copy"),
    skipExitOnModeChange,
    setSkipExitOnModeChange,
    exitScrollToBottom,
    setExitScrollToBottom
  };
}

// src/prompt-vim.ts
var PROMPT_RENDER_PATCH = Symbol("ocv-plugin.prompt.render.patch");
var COMMAND_PALETTE = "command.palette.show";
var COMMAND_KEY = "ocv-plugin.key";
var YANK_FLASH_MS = 70;
var CLIPBOARD_TIMEOUT_MS = 300;
function isRecord(value) {
  return typeof value === "object" && value !== null;
}
function isTextareaLike(value) {
  if (!isRecord(value))
    return false;
  return typeof value.plainText === "string" && typeof value.cursorOffset === "number" && typeof value.insertText === "function" && typeof value.deleteRange === "function" && typeof value.setText === "function" && typeof value.editBuffer === "object";
}
var shiftedSymbols = {
  "1": "!",
  "2": "@",
  "3": "#",
  "4": "$",
  "5": "%",
  "6": "^",
  "7": "&",
  "8": "*",
  "9": "(",
  "0": ")",
  "-": "_",
  "=": "+",
  "[": "{",
  "]": "}",
  "\\": "|",
  ";": ":",
  "'": '"',
  ",": "<",
  ".": ">",
  "/": "?",
  "`": "~"
};
function vimEvent(event) {
  if (hasModifier(event))
    return event;
  const typed = event.sequence?.length === 1 ? event.sequence : event.raw?.length === 1 ? event.raw : undefined;
  const shifted = event.shift ? shiftedSymbols[event.name] : undefined;
  const text = shifted && typed === event.name ? shifted : typed && typed.charCodeAt(0) > 32 && typed.charCodeAt(0) !== 127 ? typed : shifted;
  if (!text)
    return event;
  return { ...event, name: text, sequence: text, preventDefault: () => event.preventDefault() };
}
function hasModifier(event) {
  return !!event.ctrl || !!event.meta || !!event.super;
}
function selectedForeground(context, bg) {
  if (context.theme.background.base.a > 0)
    return context.theme.background.base;
  return 0.299 * bg.r + 0.587 * bg.g + 0.114 * bg.b > 0.5 ? RGBA.fromInts(0, 0, 0) : RGBA.fromInts(255, 255, 255);
}
function clipboardRead() {
  const command = process.platform === "darwin" ? ["pbpaste"] : process.platform === "win32" ? ["powershell.exe", "-NoProfile", "-Command", "Get-Clipboard -Raw"] : ["sh", "-c", "wl-paste -n 2>/dev/null || xclip -selection clipboard -out 2>/dev/null || xsel --clipboard --output 2>/dev/null"];
  const result = spawnSync(command[0], command.slice(1), {
    encoding: "utf8",
    stdio: ["ignore", "pipe", "ignore"],
    timeout: CLIPBOARD_TIMEOUT_MS,
    windowsHide: true
  });
  if (result.status !== 0 || result.error)
    return;
  return result.stdout;
}
function clipboardWrite(text) {
  const command = process.platform === "darwin" ? ["pbcopy"] : process.platform === "win32" ? ["powershell.exe", "-NoProfile", "-Command", "[Console]::In.ReadToEnd() | Set-Clipboard"] : ["sh", "-c", "wl-copy 2>/dev/null || xclip -selection clipboard -in 2>/dev/null || xsel --clipboard --input 2>/dev/null"];
  const result = spawnSync(command[0], command.slice(1), {
    input: text,
    encoding: "utf8",
    stdio: ["pipe", "ignore", "ignore"],
    timeout: CLIPBOARD_TIMEOUT_MS,
    windowsHide: true
  });
  if (result.error)
    return result.error.code === "ENOENT" ? "missing" : "failed";
  return result.status === 0 ? "ok" : "failed";
}
var normalKeys = [
  "escape",
  "return",
  "space",
  "backspace",
  "delete",
  "left",
  "right",
  "up",
  "down",
  "h",
  "j",
  "k",
  "l",
  "shift+h",
  "shift+m",
  "shift+l",
  "w",
  "b",
  "e",
  "shift+w",
  "shift+b",
  "shift+e",
  "0",
  "1",
  "2",
  "3",
  "4",
  "5",
  "6",
  "7",
  "8",
  "9",
  "shift+4",
  "shift+6",
  "shift+-",
  "$",
  "^",
  "_",
  "g",
  "shift+g",
  "f",
  "shift+f",
  "t",
  "shift+t",
  ";",
  "i",
  "shift+i",
  "a",
  "shift+a",
  "o",
  "shift+o",
  "r",
  "shift+r",
  "x",
  "shift+x",
  "s",
  "shift+s",
  "c",
  "shift+c",
  "d",
  "y",
  "p",
  "shift+p",
  "q",
  "u",
  "ctrl+r",
  ".",
  "v",
  "shift+v",
  "shift+j",
  "z",
  "/",
  "shift+/",
  "shift+;",
  "shift+'",
  "shift+`",
  ":",
  '"',
  "'",
  "`",
  "shift+9",
  "shift+0",
  "(",
  ")",
  "[",
  "]",
  "shift+[",
  "shift+]",
  "shift+.",
  "%",
  "<",
  ">",
  "shift+5",
  "ctrl+e",
  "ctrl+y",
  "ctrl+d",
  "ctrl+u",
  "ctrl+f",
  "ctrl+b",
  "ctrl+w",
  "ctrl+v"
];
var insertPrintableKeys = [
  ..."abcdefghijklmnopqrstuvwxyz".split(""),
  ..."0123456789".split(""),
  "space",
  "-",
  "=",
  "[",
  "]",
  "\\",
  ";",
  "'",
  ".",
  "/",
  "`",
  "shift+a",
  "shift+b",
  "shift+c",
  "shift+d",
  "shift+e",
  "shift+f",
  "shift+g",
  "shift+h",
  "shift+i",
  "shift+j",
  "shift+k",
  "shift+l",
  "shift+m",
  "shift+n",
  "shift+o",
  "shift+p",
  "shift+q",
  "shift+r",
  "shift+s",
  "shift+t",
  "shift+u",
  "shift+v",
  "shift+w",
  "shift+x",
  "shift+y",
  "shift+z",
  "!",
  "@",
  "#",
  "$",
  "%",
  "^",
  "&",
  "*",
  "(",
  ")",
  "_",
  "+",
  "shift+1",
  "shift+2",
  "shift+3",
  "shift+4",
  "shift+5",
  "shift+6",
  "shift+7",
  "shift+8",
  "shift+9",
  "shift+0",
  "shift+-",
  "shift+=",
  "shift+[",
  "shift+]",
  "shift+\\",
  "{",
  "}",
  "|",
  ":",
  '"',
  "<",
  ">",
  "?",
  "shift+.",
  "shift+/",
  "shift+;",
  "shift+'",
  "shift+`",
  "~"
];
function unique(items) {
  return [...new Set(items)];
}
function createPromptVim(context, input) {
  let lastPromptEditor;
  let lastPromptKey;
  let refocusingPrompt = false;
  let onPromptEditorChange = (_previous) => {};
  let onPromptClear = () => {};
  let disposed = false;
  let pasteGeneration = 0;
  const pasteEdits = new AsyncLocalStorage;
  let lastPaste;
  let pasteTail;
  function cancelPasteEdits() {
    pasteGeneration++;
    lastPaste = undefined;
    pasteTail = undefined;
  }
  function currentPromptEditor() {
    if (context.keymap.mode.current() !== "base")
      return;
    const route = context.ui.router.current();
    if (route.type !== "home" && route.type !== "session")
      return;
    const key = route.type === "session" ? `session:${route.sessionID}` : "home";
    let editor = context.renderer.currentFocusedEditor;
    if (!isTextareaLike(editor))
      return;
    if (editor.focused === false)
      return;
    if (!refocusingPrompt && (editor.width <= 0 || editor.height <= 0) && key === lastPromptKey && lastPromptEditor && lastPromptEditor !== editor && !lastPromptEditor.isDestroyed && lastPromptEditor.width > 0 && lastPromptEditor.height > 0) {
      refocusingPrompt = true;
      try {
        lastPromptEditor.focus();
      } finally {
        refocusingPrompt = false;
      }
      return lastPromptEditor;
    }
    if (editor !== lastPromptEditor) {
      const previous = lastPromptEditor;
      lastPromptEditor = editor;
      lastPromptKey = key;
      patchPromptEditor(editor);
      onPromptEditorChange(previous);
    }
    return editor;
  }
  function promptEditor() {
    if (!input.enabled())
      return;
    return currentPromptEditor();
  }
  const patchedEditors = new Set;
  const pasteLayoutTimers = new Set;
  function refreshPasteLayout(editor) {
    if (disposed)
      return;
    const timer = setTimeout(() => {
      pasteLayoutTimers.delete(timer);
      if (editor.isDestroyed)
        return;
      context.renderer.requestRender();
    }, 0);
    pasteLayoutTimers.add(timer);
  }
  function prunePatchedEditors() {
    for (const patched of patchedEditors) {
      if (patched.isDestroyed)
        patchedEditors.delete(patched);
    }
  }
  function restorePromptAppearance(editor, patch) {
    editor.showCursor = patch.originalShowCursor;
    editor.cursorStyle = patch.originalCursorStyle;
    editor.selectionBg = patch.originalSelectionBg;
    editor.selectionFg = patch.originalSelectionFg;
    editor.requestRender();
  }
  function patchPromptEditor(editor) {
    if (editor[PROMPT_RENDER_PATCH])
      return;
    prunePatchedEditors();
    const originalInsertText = editor.insertText;
    let inserting = false;
    const patchedInsertText = (...args) => {
      const paste = pasteEdits.getStore();
      if (!paste)
        lastPaste = undefined;
      if (!paste || inserting || disposed || !input.enabled() || editor.isDestroyed || paste.editor !== editor || paste.generation !== pasteGeneration || editor !== lastPromptEditor || editor !== context.renderer.currentFocusedEditor)
        return originalInsertText.apply(editor, args);
      const pre = { text: editor.plainText, cursor: editor.cursorOffset };
      inserting = true;
      try {
        return originalInsertText.apply(editor, args);
      } finally {
        inserting = false;
        if (paste.generation === pasteGeneration && !disposed) {
          const post = { text: editor.plainText, cursor: editor.cursorOffset };
          if (pre.text !== post.text) {
            if (lastPaste !== paste || pasteTail?.text !== pre.text) {
              state.commitEdit(pasteTail?.text === pre.text ? pasteTail : pre);
              state.push(pre, post);
            }
            lastPaste = paste;
            pasteTail = post;
            if (state.isInsert() || state.isReplace())
              state.beginEdit(post);
          }
        }
      }
    };
    const originalClear = editor.clear;
    const patchedClear = (...args) => {
      originalClear.apply(editor, args);
      onPromptClear();
    };
    const originalPaste = editor.onPaste;
    const patchedPaste = (event) => {
      if (input.enabled() && state.mode() !== "insert" && state.mode() !== "replace") {
        event.preventDefault();
        event.stopPropagation();
        return;
      }
      const result = pasteEdits.run(input.enabled() ? { editor, generation: pasteGeneration } : undefined, () => originalPaste?.call(editor, event));
      if (typeof result?.then === "function") {
        Promise.resolve(result).then(() => refreshPasteLayout(editor), () => refreshPasteLayout(editor));
      } else {
        refreshPasteLayout(editor);
      }
    };
    editor[PROMPT_RENDER_PATCH] = {
      originalInsertText,
      patchedInsertText,
      originalClear,
      patchedClear,
      originalPaste,
      patchedPaste,
      originalShowCursor: editor.showCursor,
      originalCursorStyle: editor.cursorStyle,
      originalSelectionBg: editor.selectionBg,
      originalSelectionFg: editor.selectionFg
    };
    editor.insertText = patchedInsertText;
    editor.clear = patchedClear;
    editor.onPaste = patchedPaste;
    patchedEditors.add(editor);
  }
  function applyCursorStyle() {
    if (!input.enabled()) {
      cancelPasteEdits();
      prunePatchedEditors();
      for (const editor2 of patchedEditors) {
        const patch = editor2[PROMPT_RENDER_PATCH];
        if (patch)
          restorePromptAppearance(editor2, patch);
      }
      return;
    }
    const editor = currentPromptEditor();
    if (!editor)
      return;
    patchPromptEditor(editor);
    const visual = state.isVisual();
    editor.selectionBg = visual ? context.theme.hue.accent[300] : undefined;
    editor.selectionFg = visual ? selectedForeground(context, context.theme.hue.accent[300]) : undefined;
    if (state.isInsert()) {
      editor.showCursor = true;
      editor.cursorStyle = { style: "line", blinking: true };
      return;
    }
    if (state.isReplace()) {
      editor.showCursor = true;
      editor.cursorStyle = { style: "underline", blinking: false };
      return;
    }
    editor.cursorStyle = { style: "block", blinking: false };
    editor.showCursor = true;
    editor.requestRender();
  }
  let styleSync;
  function syncStyle() {
    applyCursorStyle();
    styleSync?.();
  }
  function setStyleSync(fn) {
    styleSync = fn;
  }
  function textarea() {
    const editor = promptEditor();
    if (!editor)
      throw new Error("No focused OpenCode prompt textarea");
    return editor;
  }
  const state = createVimState({
    enabled: input.enabled,
    initial: () => input.initialMode
  });
  let clipboardRegister = null;
  let clipboardText;
  let clipboardUnavailable = false;
  let clipboardFailures = 0;
  const CLIPBOARD_MAX_FAILURES = 3;
  function clipboardFailed(kind) {
    clipboardFailures = kind === "missing" ? CLIPBOARD_MAX_FAILURES : clipboardFailures + 1;
    if (clipboardFailures < CLIPBOARD_MAX_FAILURES || clipboardUnavailable)
      return;
    clipboardUnavailable = true;
    context.ui.toast.show({ variant: "warning", message: "System clipboard unavailable, using the internal Vim register" });
  }
  let flash = 0;
  let flashSpan;
  let flashTimer;
  function register() {
    if (!input.systemClipboardRegister || clipboardUnavailable)
      return state.register();
    const text = clipboardRead();
    if (text === undefined)
      return clipboardRegister ?? state.register();
    if (clipboardRegister && text === clipboardText)
      return clipboardRegister;
    return { text, linewise: false };
  }
  function setRegister(next, notify = false) {
    state.setRegister(next);
    if (!input.systemClipboardRegister || !next || clipboardUnavailable)
      return;
    clipboardRegister = next;
    clipboardText = next.text;
    const copied = clipboardWrite(next.text);
    if (copied !== "ok") {
      clipboardFailed(copied);
      return;
    }
    clipboardFailures = 0;
    if (notify)
      context.ui.toast.show({ message: "Copied to clipboard", variant: "info" });
  }
  function submitPrompt() {
    const editor = textarea();
    patchPromptEditor(editor);
    editor.submit();
  }
  function flashYank(span) {
    const editor = promptEditor();
    if (!editor || span.end <= span.start)
      return;
    flash++;
    flashSpan = span;
    const id = flash;
    const cursor = editor.cursorOffset;
    editor.editorView.setSelection(span.start, span.end, editor.selectionBg, editor.selectionFg);
    editor.cursorOffset = cursor;
    context.renderer.requestRender();
    if (flashTimer)
      clearTimeout(flashTimer);
    flashTimer = setTimeout(() => {
      if (editor.isDestroyed)
        return;
      if (id !== flash)
        return;
      if (state.isVisual()) {
        flashSpan = undefined;
        return;
      }
      const selection = editor.editorView.getSelection();
      if (!selection) {
        flashSpan = undefined;
        return;
      }
      if (selection.start !== span.start || selection.end !== span.end) {
        flashSpan = undefined;
        return;
      }
      flashSpan = undefined;
      editor.clearSelection();
      context.renderer.requestRender();
    }, YANK_FLASH_MS);
  }
  function jumpPromptViewport(action) {
    const editor = textarea();
    const row = action === "high" ? 0 : action === "middle" ? Math.max(0, Math.floor((editor.height - 1) / 2)) : editor.height - 1;
    let prev = -1;
    while (editor.visualCursor.visualRow > row && editor.cursorOffset !== prev) {
      prev = editor.cursorOffset;
      editor.moveCursorUp();
    }
    prev = -1;
    while (editor.visualCursor.visualRow < row && editor.cursorOffset !== prev) {
      prev = editor.cursorOffset;
      editor.moveCursorDown();
    }
  }
  const handler = createVimHandler({
    enabled: () => Boolean(promptEditor()),
    state,
    textarea,
    register,
    setRegister,
    pasteOverSelection() {
      const selection = textarea().editorView.getSelection();
      if (!selection)
        return false;
      return !flashSpan || selection.start !== flashSpan.start || selection.end !== flashSpan.end;
    },
    submit: submitPrompt,
    commandPalette() {
      context.keymap.dispatch(COMMAND_PALETTE);
    },
    flash: flashYank,
    scroll(action) {
      if (action === "line-down")
        context.keymap.dispatch("session.line.down");
      if (action === "line-up")
        context.keymap.dispatch("session.line.up");
      if (action === "half-down")
        context.keymap.dispatch("session.half.page.down");
      if (action === "half-up")
        context.keymap.dispatch("session.half.page.up");
      if (action === "page-down")
        context.keymap.dispatch("session.page.down");
      if (action === "page-up")
        context.keymap.dispatch("session.page.up");
    },
    jump(action) {
      if (action === "high" || action === "middle" || action === "low") {
        jumpPromptViewport(action);
        return;
      }
      const editor = textarea();
      if (editor.plainText.length > 0) {
        if (action === "top")
          editor.gotoBufferHome();
        if (action === "bottom")
          editor.gotoBufferEnd();
        return;
      }
      if (action === "top")
        context.keymap.dispatch("session.first");
      if (action === "bottom")
        context.keymap.dispatch("session.last");
    },
    copySearchStart: () => false,
    autocomplete: (trigger) => trigger,
    langmap: input.langmap,
    vimEscapeSequence: input.vimEscapeSequence
  });
  onPromptEditorChange = (previous) => {
    cancelPasteEdits();
    const mode = state.mode();
    if (previous && (mode === "visual" || mode === "visual-line") && !previous.isDestroyed)
      previous.clearSelection();
    handler.cancelPending();
    state.resetHistory();
    if (mode === "visual" || mode === "visual-line" || mode === "replace")
      state.setMode("normal");
    else if (input.enabled() && mode === "insert")
      handler.beginInsertEdit();
    syncStyle();
  };
  onPromptClear = () => {
    cancelPasteEdits();
    handler.cancelPending();
    state.resetHistory();
    state.setMode(input.insertAfterSubmit ? "insert" : "normal");
    if (input.enabled() && input.insertAfterSubmit)
      handler.beginInsertEdit();
    syncStyle();
  };
  const indicator = useVimIndicator({
    enabled: input.enabled,
    active: () => {
      const route = context.ui.router.current().type;
      return route === "home" || route === "session";
    },
    state
  });
  function runVimKey(event) {
    const editor = promptEditor();
    if (!editor)
      return false;
    lastPaste = undefined;
    const keyEvent = vimEvent(event);
    if (state.isReplace() && keyEvent.name === "escape" && pasteTail?.text === editor.plainText) {
      state.commitEdit(pasteTail);
    }
    if (!state.isInsert() && !state.isReplace())
      pasteTail = undefined;
    if ((state.isInsert() || state.isReplace()) && keyEvent.name === "return" && !hasModifier(keyEvent)) {
      if (input.enterSubmit)
        submitPrompt();
      else {
        if (state.isReplace())
          handler.recordInsertText(`
`);
        textarea().insertText(`
`);
      }
      syncStyle();
      return;
    }
    if ((state.isInsert() || state.isReplace()) && (keyEvent.name === "down" || keyEvent.name === "up") && !hasModifier(keyEvent)) {
      if (!handler.handleKey(keyEvent)) {
        if (keyEvent.name === "down")
          editor.moveCursorDown();
        else
          editor.moveCursorUp();
      }
      syncStyle();
      return;
    }
    const handled = handler.handleKey(keyEvent);
    syncStyle();
    if (!handled)
      return false;
  }
  function onComma(event) {
    if (event.name !== "," || hasModifier(event))
      return;
    if (runVimKey(event) === false)
      return;
    event.preventDefault();
    event.stopPropagation();
  }
  context.renderer.keyInput.prependListener("keypress", onComma);
  const keys = unique([
    ...normalKeys,
    ...insertPrintableKeys,
    ...Object.keys(input.langmap?.() ?? {}).map((key) => key === " " ? "space" : key)
  ]).filter((key) => !key.includes(","));
  const vimCommands = [{
    id: COMMAND_KEY,
    bind: keys.join(","),
    run: (_input, event) => event ? runVimKey(event) : false
  }];
  context.renderer.on(CliRenderEvents.FOCUSED_EDITOR, syncStyle);
  syncStyle();
  function dispose() {
    disposed = true;
    cancelPasteEdits();
    pasteEdits.disable();
    context.renderer.off(CliRenderEvents.FOCUSED_EDITOR, syncStyle);
    context.renderer.keyInput.off("keypress", onComma);
    handler.cancelPending();
    state.cancelEdit();
    for (const timer of pasteLayoutTimers)
      clearTimeout(timer);
    pasteLayoutTimers.clear();
    if (flashTimer) {
      clearTimeout(flashTimer);
      flashTimer = undefined;
    }
    flash++;
    for (const editor of patchedEditors) {
      const patch = editor[PROMPT_RENDER_PATCH];
      if (!patch)
        continue;
      if (editor.insertText === patch.patchedInsertText)
        editor.insertText = patch.originalInsertText;
      if (editor.clear === patch.patchedClear)
        editor.clear = patch.originalClear;
      if (editor.onPaste === patch.patchedPaste)
        editor.onPaste = patch.originalPaste;
      delete editor[PROMPT_RENDER_PATCH];
      if (!editor.isDestroyed) {
        if (flashSpan) {
          const selection = editor.editorView.getSelection();
          if (selection?.start === flashSpan.start && selection.end === flashSpan.end)
            editor.clearSelection();
        }
        restorePromptAppearance(editor, patch);
      }
    }
    patchedEditors.clear();
    flashSpan = undefined;
    context.renderer.requestRender();
  }
  return {
    dispose,
    cancelPending: handler.cancelPending,
    applyCursorStyle: syncStyle,
    setStyleSync,
    active: () => Boolean(promptEditor()),
    indicator,
    pending: state.pending,
    isVisual: state.isVisual,
    isVisualLine: state.isVisualLine,
    mode: state.mode,
    setMode: state.setMode,
    vimCommands
  };
}

// src/tui.tsx
var PLUGIN_ID = "ocv-plugin";
var COMMAND_TOGGLE = "ocv-plugin.toggle";
var COMMAND_QUIT = "ocv-plugin.quit";
var COMMAND_EXIT = "app.exit";
var KV_ENABLED = "ocv-plugin.enabled.v2";
function isRecord2(value) {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
function nonEmptyString(value) {
  return typeof value === "string" && value.trim() ? value : undefined;
}
function readInitialMode(value) {
  return value === "normal" || value === "insert" ? value : undefined;
}
var COMMAND_ALIASES = {
  app_exit: "app.exit",
  app_debug: "app.debug",
  app_console: "app.console",
  app_heap_snapshot: "app.heap_snapshot",
  app_toggle_animations: "app.toggle.animations",
  app_toggle_file_context: "app.toggle.file_context",
  app_toggle_diffwrap: "app.toggle.diffwrap",
  app_toggle_paste_summary: "app.toggle.paste_summary",
  app_toggle_session_directory_filter: "app.toggle.session_directory_filter",
  command_list: "command.palette.show",
  help_show: "help.show",
  docs_open: "docs.open",
  diff_open: "diff.open",
  diff_close: "diff.close",
  diff_toggle: "diff.toggle",
  diff_expand: "diff.expand",
  diff_expand_all: "diff.expand_all",
  diff_collapse: "diff.collapse",
  diff_switch_focus: "diff.switch_focus",
  diff_next_hunk: "diff.next_hunk",
  diff_previous_hunk: "diff.previous_hunk",
  diff_next_file: "diff.next_file",
  diff_previous_file: "diff.previous_file",
  diff_toggle_file_tree: "diff.toggle_file_tree",
  diff_single_patch: "diff.single_patch",
  diff_switch_source: "diff.switch_source",
  diff_toggle_view: "diff.toggle_view",
  diff_help: "diff.help",
  editor_open: "prompt.editor",
  theme_list: "theme.switch",
  theme_switch_mode: "theme.switch_mode",
  theme_mode_lock: "theme.mode.lock",
  sidebar_toggle: "session.sidebar.toggle",
  scrollbar_toggle: "session.toggle.scrollbar",
  status_view: "opencode.status",
  debug_view: "opencode.debug",
  session_export: "session.export",
  session_copy: "session.copy",
  copy_mode: "session.copy_mode",
  session_move: "session.move",
  session_new: "session.new",
  session_list: "session.list",
  session_timeline: "session.timeline",
  session_fork: "session.fork",
  session_rename: "session.rename",
  session_delete: "session.delete",
  session_share: "session.share",
  session_unshare: "session.unshare",
  session_interrupt: "session.interrupt",
  session_background: "session.background",
  session_compact: "session.compact",
  session_toggle_timestamps: "session.toggle.timestamps",
  session_toggle_generic_tool_output: "session.toggle.generic_tool_output",
  session_queued_prompts: "session.queued_prompts",
  session_child_first: "session.child.first",
  session_child_cycle: "session.child.next",
  session_child_cycle_reverse: "session.child.previous",
  session_parent: "session.parent",
  session_pin_toggle: "session.pin.toggle",
  session_quick_switch_1: "session.quick_switch.1",
  session_quick_switch_2: "session.quick_switch.2",
  session_quick_switch_3: "session.quick_switch.3",
  session_quick_switch_4: "session.quick_switch.4",
  session_quick_switch_5: "session.quick_switch.5",
  session_quick_switch_6: "session.quick_switch.6",
  session_quick_switch_7: "session.quick_switch.7",
  session_quick_switch_8: "session.quick_switch.8",
  session_quick_switch_9: "session.quick_switch.9",
  stash_delete: "stash.delete",
  model_provider_list: "model.dialog.provider",
  model_favorite_toggle: "model.dialog.favorite",
  model_list: "model.list",
  model_cycle_recent: "model.cycle_recent",
  model_cycle_recent_reverse: "model.cycle_recent_reverse",
  model_cycle_favorite: "model.cycle_favorite",
  model_cycle_favorite_reverse: "model.cycle_favorite_reverse",
  mcp_list: "mcp.list",
  provider_connect: "provider.connect",
  console_org_switch: "console.org.switch",
  agent_list: "agent.list",
  agent_cycle: "agent.cycle",
  agent_cycle_reverse: "agent.cycle.reverse",
  variant_cycle: "variant.cycle",
  variant_list: "variant.list",
  messages_page_up: "session.page.up",
  messages_page_down: "session.page.down",
  messages_line_up: "session.line.up",
  messages_line_down: "session.line.down",
  messages_half_page_up: "session.half.page.up",
  messages_half_page_down: "session.half.page.down",
  messages_first: "session.first",
  messages_last: "session.last",
  messages_next: "session.message.next",
  messages_previous: "session.message.previous",
  messages_last_user: "session.messages_last_user",
  messages_copy: "messages.copy",
  messages_undo: "session.undo",
  messages_redo: "session.redo",
  messages_toggle_conceal: "session.toggle.conceal",
  tool_details: "session.toggle.actions",
  display_thinking: "session.toggle.thinking",
  prompt_submit: "prompt.submit",
  prompt_copy_selection: "prompt.copy_selection",
  prompt_editor_context_clear: "prompt.editor_context.clear",
  prompt_skills: "prompt.skills",
  prompt_stash: "prompt.stash",
  prompt_stash_pop: "prompt.stash.pop",
  prompt_stash_list: "prompt.stash.list",
  workspace_set: "workspace.set",
  input_clear: "prompt.clear",
  input_paste: "prompt.paste",
  input_submit: "input.submit",
  input_newline: "input.newline",
  input_move_left: "input.move.left",
  input_move_right: "input.move.right",
  input_move_up: "input.move.up",
  input_move_down: "input.move.down",
  input_select_left: "input.select.left",
  input_select_right: "input.select.right",
  input_select_up: "input.select.up",
  input_select_down: "input.select.down",
  input_line_home: "input.line.home",
  input_line_end: "input.line.end",
  input_select_line_home: "input.select.line.home",
  input_select_line_end: "input.select.line.end",
  input_visual_line_home: "input.visual.line.home",
  input_visual_line_end: "input.visual.line.end",
  input_select_visual_line_home: "input.select.visual.line.home",
  input_select_visual_line_end: "input.select.visual.line.end",
  input_buffer_home: "input.buffer.home",
  input_buffer_end: "input.buffer.end",
  input_select_buffer_home: "input.select.buffer.home",
  input_select_buffer_end: "input.select.buffer.end",
  input_delete_line: "input.delete.line",
  input_delete_to_line_end: "input.delete.to.line.end",
  input_delete_to_line_start: "input.delete.to.line.start",
  input_backspace: "input.backspace",
  input_delete: "input.delete",
  input_undo: "input.undo",
  input_redo: "input.redo",
  input_word_forward: "input.word.forward",
  input_word_backward: "input.word.backward",
  input_select_word_forward: "input.select.word.forward",
  input_select_word_backward: "input.select.word.backward",
  input_delete_word_forward: "input.delete.word.forward",
  input_delete_word_backward: "input.delete.word.backward",
  input_select_all: "input.select.all",
  history_previous: "prompt.history.previous",
  history_next: "prompt.history.next",
  terminal_suspend: "terminal.suspend",
  terminal_title_toggle: "terminal.title.toggle",
  tips_toggle: "tips.toggle",
  plugin_manager: "plugins.list",
  plugin_install: "plugins.install",
  which_key_toggle: "which-key.toggle",
  which_key_layout_toggle: "which-key.layout.toggle",
  which_key_pending_toggle: "which-key.pending.toggle",
  which_key_group_previous: "which-key.group.previous",
  which_key_group_next: "which-key.group.next",
  which_key_scroll_up: "which-key.scroll.up",
  which_key_scroll_down: "which-key.scroll.down",
  which_key_page_up: "which-key.page.up",
  which_key_page_down: "which-key.page.down",
  which_key_home: "which-key.home",
  which_key_end: "which-key.end"
};
function commandName(value) {
  return COMMAND_ALIASES[value] ?? (value.includes(".") ? value : value.replaceAll("_", "."));
}
function keyToBind(key) {
  if (typeof key === "string")
    return key.trim() ? key : undefined;
  if (!isRecord2(key))
    return;
  const name = nonEmptyString(key.name);
  if (!name)
    return;
  const mods = ["ctrl", "meta", "shift", "option", "super"].filter((mod) => key[mod] === true);
  return [...mods, name].join("+");
}
function hasEmptyCommaEntry(bind) {
  return bind.split(",").some((entry) => entry.trim() === "");
}
function bindingFromValue(command, value) {
  const bind = keyToBind(value);
  if (bind)
    return bind === "none" ? [] : [{
      bind,
      cmd: command
    }];
  if (!Array.isArray(value)) {
    if (!isRecord2(value))
      return [];
    const itemBind = keyToBind(value.key);
    if (!itemBind || itemBind === "none")
      return [];
    return [{
      bind: itemBind,
      cmd: command
    }];
  }
  return value.flatMap((item) => bindingFromValue(command, item));
}
function readNormalBindings(options) {
  const direct = isRecord2(options.normal_keybinds) ? Object.entries(options.normal_keybinds).flatMap(([key, value]) => {
    const bind = keyToBind(key);
    if (!bind || bind === "none")
      return [];
    if (typeof value === "string")
      return [{
        bind,
        cmd: commandName(value)
      }];
    if (!isRecord2(value))
      return [];
    const command = nonEmptyString(value.command) ?? nonEmptyString(value.cmd);
    if (!command)
      return [];
    return [{
      bind,
      cmd: commandName(command)
    }];
  }) : [];
  const keybinds = isRecord2(options.keybinds) && isRecord2(options.keybinds["vim.normal"]) ? options.keybinds["vim.normal"] : undefined;
  const scoped = keybinds ? Object.entries(keybinds).flatMap(([name, value]) => name === "leader" ? [] : bindingFromValue(commandName(name), value)) : [];
  return [...direct, ...scoped];
}
function readOptions(input) {
  const options = isRecord2(input) ? input : {};
  const enabled = typeof options.enabled === "boolean" ? options.enabled : true;
  const initialMode = readInitialMode(options.initial_mode) ?? readInitialMode(options.vim_initial_mode);
  const toggleKey = nonEmptyString(options.toggle_key);
  const indicator = options.indicator === false || options.indicator === "off" ? false : true;
  const enterSubmit = options.enter_submit === true || options.vim_enter_submit === true;
  const insertAfterSubmit = options.insert_after_submit === true || options.vim_insert_after_submit === true;
  const systemClipboardRegister = options.system_clipboard_register === true || options.vim_system_clipboard_register === true;
  const langmapInput = isRecord2(options.langmap) ? options.langmap : isRecord2(options.vim_langmap) ? options.vim_langmap : undefined;
  const langmap = langmapInput ? Object.fromEntries(Object.entries(langmapInput).filter((entry) => entry[0].length === 1 && typeof entry[1] === "string" && entry[1].length === 1)) : undefined;
  const escapeSequenceInput = nonEmptyString(options.escape_sequence) ?? nonEmptyString(options.vim_escape_sequence);
  const vimEscapeSequence = escapeSequenceInput?.length === 2 ? escapeSequenceInput : undefined;
  const keybinds = isRecord2(options.keybinds) && isRecord2(options.keybinds["vim.normal"]) ? options.keybinds["vim.normal"] : undefined;
  const normalLeader = nonEmptyString(options.normal_leader) ?? nonEmptyString(options.vim_normal_leader) ?? nonEmptyString(keybinds?.leader);
  return {
    enabled,
    initialMode,
    toggleKey,
    indicator,
    enterSubmit,
    insertAfterSubmit,
    systemClipboardRegister,
    langmap,
    vimEscapeSequence,
    normalLeader,
    normalBindings: readNormalBindings(options)
  };
}
function Status(props) {
  let releaseText;
  onCleanup(() => releaseText?.());
  if (!props.showIndicator)
    return null;
  return (() => {
    var _el$ = _$createElement("box"), _el$2 = _$createElement("text");
    _$insertNode(_el$, _el$2);
    _$setProp(_el$, "paddingLeft", 1);
    _$setProp(_el$, "flexShrink", 0);
    _$use((text) => {
      releaseText?.();
      releaseText = text ? props.onText(text) : undefined;
    }, _el$2);
    _$insert(_el$2, () => props.indicator() ?? "");
    _$effect((_$p) => _$setProp(_el$2, "fg", props.theme.text.muted, _$p));
    return _el$;
  })();
}
function GlobalCommands(props) {
  const {
    context,
    toggle
  } = props;
  context.keymap.layer(() => ({
    mode: "global",
    commands: [{
      id: COMMAND_TOGGLE,
      title: "Toggle vim mode",
      group: "Plugin",
      palette: true,
      slash: {
        name: "vim"
      },
      run: () => toggle()
    }, {
      id: COMMAND_QUIT,
      title: "Quit",
      group: "System",
      palette: true,
      run: () => context.keymap.dispatch(COMMAND_EXIT)
    }]
  }));
  return null;
}
function KeymapSetup(props) {
  const {
    context,
    options,
    prompt,
    toggle
  } = props;
  onMount(prompt.applyCursorStyle);
  context.keymap.layer(() => ({
    mode: "base",
    priority: 100,
    commands: prompt.vimCommands
  }));
  if (options.toggleKey) {
    try {
      context.keymap.layer(() => ({
        mode: "base",
        priority: 100,
        commands: [{
          bind: options.toggleKey,
          run: () => toggle()
        }]
      }));
    } catch (error) {
      context.ui.toast.show({
        variant: "error",
        message: `Vim plugin: invalid toggle_key: ${error instanceof Error ? error.message : String(error)}`
      });
    }
  }
  const normalBindings = options.normalBindings.filter((binding) => !hasEmptyCommaEntry(binding.bind));
  if (normalBindings.length > 0) {
    try {
      context.keymap.layer(() => ({
        mode: "base",
        priority: 200,
        enabled: () => prompt.active() && prompt.mode() === "normal",
        commands: normalBindings.map((binding) => ({
          bind: binding.bind,
          run: () => {
            if (!prompt.active() || prompt.mode() !== "normal")
              return false;
            context.keymap.dispatch(binding.cmd);
          }
        }))
      }));
    } catch (error) {
      context.ui.toast.show({
        variant: "error",
        message: `Vim plugin: invalid normal_keybinds: ${error instanceof Error ? error.message : String(error)}`
      });
    }
  }
  return null;
}
// Local integration: keep the upstream engine, expose its signals, and mount
// keyboard resources independently of the native prompt footer. See README.md.
function setupVim(context) {
    const options = readOptions(context.options);
    const [enabledStore, setEnabledStore] = context.storage.store(KV_ENABLED, {
      initial: {
        enabled: options.enabled
      }
    });
    const [enabled, setEnabled] = createSignal2(enabledStore.enabled);
    let enabledWrites = 0;
    let enabledWrite = Promise.resolve();
    let disposed = false;
    const prompt = createPromptVim(context, {
      enabled,
      initialMode: enabled() ? options.initialMode ?? "insert" : "insert",
      enterSubmit: options.enterSubmit,
      insertAfterSubmit: options.insertAfterSubmit,
      systemClipboardRegister: options.systemClipboardRegister,
      langmap: () => options.langmap,
      vimEscapeSequence: options.vimEscapeSequence
    });
    function syncEnabledStore() {
      const stored = enabledStore.enabled;
      const current = enabled();
      if (disposed || enabledWrites || current === stored)
        return;
      setEnabled(stored);
      prompt.applyCursorStyle();
    }
    const disposeEnabledSync = createRoot((dispose) => {
      createEffect2(syncEnabledStore);
      return dispose;
    });
    function toggle() {
      prompt.cancelPending();
      const next = !enabled();
      enabledWrites++;
      setEnabled(next);
      const write = enabledWrite.catch(() => {}).then(() => setEnabledStore((draft) => {
        draft.enabled = next;
      }));
      enabledWrite = write;
      write.then(() => {
        enabledWrites--;
        syncEnabledStore();
      }, () => {
        enabledWrites--;
        syncEnabledStore();
        if (!disposed)
          context.ui.toast.show({
            variant: "error",
            message: "Failed to save Vim mode state"
          });
      });
      if (next)
        prompt.setMode("normal");
      prompt.applyCursorStyle();
      context.ui.toast.show({
        variant: next ? "success" : "info",
        message: next ? "Vim mode enabled" : "Vim mode disabled"
      });
    }
    if (options.normalBindings.some((binding) => hasEmptyCommaEntry(binding.bind))) {
      context.ui.toast.show({
        variant: "warning",
        message: "Vim plugin: literal comma keys and empty comma-separated keybind entries are not supported in OpenCode v2 and were skipped"
      });
    }
    if (options.normalLeader) {
      context.ui.toast.show({
        variant: "warning",
        message: "Vim plugin: normal_leader is not supported in OpenCode v2; configure the host 'leader' keybind instead"
      });
    }
    const releaseStatusSlot = context.ui.slot({
      append: "app",
      render: () => _$createComponent(KeymapSetup, {
        context,
        options,
        prompt,
        toggle
      })
    });
    const releaseCommandsSlot = context.ui.slot({
      append: "app",
      render: () => _$createComponent(GlobalCommands, {
        context,
        toggle
      })
    });
    return { enabled, mode: prompt.mode, dispose: () => {
      disposed = true;
      disposeEnabledSync();
      releaseCommandsSlot();
      releaseStatusSlot();
      prompt.dispose();
    } };
}
export {
  setupVim
};

//# debugId=30D68735C32ED4D164756E2164756E21
