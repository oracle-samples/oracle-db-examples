/**
 * Bundled by jsDelivr using Rollup v2.79.1 and Terser v5.17.1.
 * Original file: /npm/graphql@16.6.0/index.mjs
 *
 * Do NOT use SRI with dynamically generated files! More information: https://www.jsdelivr.com/using-sri-with-dynamic-files
 */
const e = "16.6.0",
  t = Object.freeze({ major: 16, minor: 6, patch: 0, preReleaseTag: null });
function n(e, t) {
  if (!Boolean(e)) throw new Error(t);
}
function i(e) {
  return "function" == typeof (null == e ? void 0 : e.then);
}
function r(e) {
  return "object" == typeof e && null !== e;
}
function o(e, t) {
  if (!Boolean(e))
    throw new Error(null != t ? t : "Unexpected invariant triggered.");
}
const s = /\r\n|[\n\r]/g;
function a(e, t) {
  let n = 0,
    i = 1;
  for (const r of e.body.matchAll(s)) {
    if (("number" == typeof r.index || o(!1), r.index >= t)) break;
    (n = r.index + r[0].length), (i += 1);
  }
  return { line: i, column: t + 1 - n };
}
function c(e) {
  return u(e.source, a(e.source, e.start));
}
function u(e, t) {
  const n = e.locationOffset.column - 1,
    i = "".padStart(n) + e.body,
    r = t.line - 1,
    o = e.locationOffset.line - 1,
    s = t.line + o,
    a = 1 === t.line ? n : 0,
    c = t.column + a,
    u = `${e.name}:${s}:${c}\n`,
    p = i.split(/\r\n|[\n\r]/g),
    d = p[r];
  if (d.length > 120) {
    const e = Math.floor(c / 80),
      t = c % 80,
      n = [];
    for (let e = 0; e < d.length; e += 80) n.push(d.slice(e, e + 80));
    return (
      u +
      l([
        [`${s} |`, n[0]],
        ...n.slice(1, e + 1).map((e) => ["|", e]),
        ["|", "^".padStart(t)],
        ["|", n[e + 1]],
      ])
    );
  }
  return (
    u +
    l([
      [s - 1 + " |", p[r - 1]],
      [`${s} |`, d],
      ["|", "^".padStart(c)],
      [`${s + 1} |`, p[r + 1]],
    ])
  );
}
function l(e) {
  const t = e.filter(([e, t]) => void 0 !== t),
    n = Math.max(...t.map(([e]) => e.length));
  return t.map(([e, t]) => e.padStart(n) + (t ? " " + t : "")).join("\n");
}
class p extends Error {
  constructor(e, ...t) {
    var n, i, o;
    const {
      nodes: s,
      source: c,
      positions: u,
      path: l,
      originalError: f,
      extensions: h,
    } = (function (e) {
      const t = e[0];
      return null == t || "kind" in t || "length" in t
        ? {
            nodes: t,
            source: e[1],
            positions: e[2],
            path: e[3],
            originalError: e[4],
            extensions: e[5],
          }
        : t;
    })(t);
    super(e),
      (this.name = "GraphQLError"),
      (this.path = null != l ? l : void 0),
      (this.originalError = null != f ? f : void 0),
      (this.nodes = d(Array.isArray(s) ? s : s ? [s] : void 0));
    const m = d(
      null === (n = this.nodes) || void 0 === n
        ? void 0
        : n.map((e) => e.loc).filter((e) => null != e)
    );
    (this.source =
      null != c
        ? c
        : null == m || null === (i = m[0]) || void 0 === i
        ? void 0
        : i.source),
      (this.positions =
        null != u ? u : null == m ? void 0 : m.map((e) => e.start)),
      (this.locations =
        u && c
          ? u.map((e) => a(c, e))
          : null == m
          ? void 0
          : m.map((e) => a(e.source, e.start)));
    const y = r(null == f ? void 0 : f.extensions)
      ? null == f
        ? void 0
        : f.extensions
      : void 0;
    (this.extensions =
      null !== (o = null != h ? h : y) && void 0 !== o
        ? o
        : Object.create(null)),
      Object.defineProperties(this, {
        message: { writable: !0, enumerable: !0 },
        name: { enumerable: !1 },
        nodes: { enumerable: !1 },
        source: { enumerable: !1 },
        positions: { enumerable: !1 },
        originalError: { enumerable: !1 },
      }),
      null != f && f.stack
        ? Object.defineProperty(this, "stack", {
            value: f.stack,
            writable: !0,
            configurable: !0,
          })
        : Error.captureStackTrace
        ? Error.captureStackTrace(this, p)
        : Object.defineProperty(this, "stack", {
            value: Error().stack,
            writable: !0,
            configurable: !0,
          });
  }
  get [Symbol.toStringTag]() {
    return "GraphQLError";
  }
  toString() {
    let e = this.message;
    if (this.nodes)
      for (const t of this.nodes) t.loc && (e += "\n\n" + c(t.loc));
    else if (this.source && this.locations)
      for (const t of this.locations) e += "\n\n" + u(this.source, t);
    return e;
  }
  toJSON() {
    const e = { message: this.message };
    return (
      null != this.locations && (e.locations = this.locations),
      null != this.path && (e.path = this.path),
      null != this.extensions &&
        Object.keys(this.extensions).length > 0 &&
        (e.extensions = this.extensions),
      e
    );
  }
}
function d(e) {
  return void 0 === e || 0 === e.length ? void 0 : e;
}
function f(e) {
  return e.toString();
}
function h(e) {
  return e.toJSON();
}
function m(e, t, n) {
  return new p(`Syntax Error: ${n}`, { source: e, positions: [t] });
}
class y {
  constructor(e, t, n) {
    (this.start = e.start),
      (this.end = t.end),
      (this.startToken = e),
      (this.endToken = t),
      (this.source = n);
  }
  get [Symbol.toStringTag]() {
    return "Location";
  }
  toJSON() {
    return { start: this.start, end: this.end };
  }
}
class E {
  constructor(e, t, n, i, r, o) {
    (this.kind = e),
      (this.start = t),
      (this.end = n),
      (this.line = i),
      (this.column = r),
      (this.value = o),
      (this.prev = null),
      (this.next = null);
  }
  get [Symbol.toStringTag]() {
    return "Token";
  }
  toJSON() {
    return {
      kind: this.kind,
      value: this.value,
      line: this.line,
      column: this.column,
    };
  }
}
const v = {
    Name: [],
    Document: ["definitions"],
    OperationDefinition: [
      "name",
      "variableDefinitions",
      "directives",
      "selectionSet",
    ],
    VariableDefinition: ["variable", "type", "defaultValue", "directives"],
    Variable: ["name"],
    SelectionSet: ["selections"],
    Field: ["alias", "name", "arguments", "directives", "selectionSet"],
    Argument: ["name", "value"],
    FragmentSpread: ["name", "directives"],
    InlineFragment: ["typeCondition", "directives", "selectionSet"],
    FragmentDefinition: [
      "name",
      "variableDefinitions",
      "typeCondition",
      "directives",
      "selectionSet",
    ],
    IntValue: [],
    FloatValue: [],
    StringValue: [],
    BooleanValue: [],
    NullValue: [],
    EnumValue: [],
    ListValue: ["values"],
    ObjectValue: ["fields"],
    ObjectField: ["name", "value"],
    Directive: ["name", "arguments"],
    NamedType: ["name"],
    ListType: ["type"],
    NonNullType: ["type"],
    SchemaDefinition: ["description", "directives", "operationTypes"],
    OperationTypeDefinition: ["type"],
    ScalarTypeDefinition: ["description", "name", "directives"],
    ObjectTypeDefinition: [
      "description",
      "name",
      "interfaces",
      "directives",
      "fields",
    ],
    FieldDefinition: ["description", "name", "arguments", "type", "directives"],
    InputValueDefinition: [
      "description",
      "name",
      "type",
      "defaultValue",
      "directives",
    ],
    InterfaceTypeDefinition: [
      "description",
      "name",
      "interfaces",
      "directives",
      "fields",
    ],
    UnionTypeDefinition: ["description", "name", "directives", "types"],
    EnumTypeDefinition: ["description", "name", "directives", "values"],
    EnumValueDefinition: ["description", "name", "directives"],
    InputObjectTypeDefinition: ["description", "name", "directives", "fields"],
    DirectiveDefinition: ["description", "name", "arguments", "locations"],
    SchemaExtension: ["directives", "operationTypes"],
    ScalarTypeExtension: ["name", "directives"],
    ObjectTypeExtension: ["name", "interfaces", "directives", "fields"],
    InterfaceTypeExtension: ["name", "interfaces", "directives", "fields"],
    UnionTypeExtension: ["name", "directives", "types"],
    EnumTypeExtension: ["name", "directives", "values"],
    InputObjectTypeExtension: ["name", "directives", "fields"],
  },
  T = new Set(Object.keys(v));
function N(e) {
  const t = null == e ? void 0 : e.kind;
  return "string" == typeof t && T.has(t);
}
var I, g, _, b;
function O(e) {
  return 9 === e || 32 === e;
}
function D(e) {
  return e >= 48 && e <= 57;
}
function A(e) {
  return (e >= 97 && e <= 122) || (e >= 65 && e <= 90);
}
function w(e) {
  return A(e) || 95 === e;
}
function S(e) {
  return A(e) || D(e) || 95 === e;
}
function R(e) {
  var t;
  let n = Number.MAX_SAFE_INTEGER,
    i = null,
    r = -1;
  for (let t = 0; t < e.length; ++t) {
    var o;
    const s = e[t],
      a = $(s);
    a !== s.length &&
      ((i = null !== (o = i) && void 0 !== o ? o : t),
      (r = t),
      0 !== t && a < n && (n = a));
  }
  return e
    .map((e, t) => (0 === t ? e : e.slice(n)))
    .slice(null !== (t = i) && void 0 !== t ? t : 0, r + 1);
}
function $(e) {
  let t = 0;
  for (; t < e.length && O(e.charCodeAt(t)); ) ++t;
  return t;
}
function x(e) {
  if ("" === e) return !0;
  let t = !0,
    n = !1,
    i = !0,
    r = !1;
  for (let o = 0; o < e.length; ++o)
    switch (e.codePointAt(o)) {
      case 0:
      case 1:
      case 2:
      case 3:
      case 4:
      case 5:
      case 6:
      case 7:
      case 8:
      case 11:
      case 12:
      case 14:
      case 15:
      case 13:
        return !1;
      case 10:
        if (t && !r) return !1;
        (r = !0), (t = !0), (n = !1);
        break;
      case 9:
      case 32:
        n || (n = t);
        break;
      default:
        i && (i = n), (t = !1);
    }
  return !t && (!i || !r);
}
function k(e, t) {
  const n = e.replace(/"""/g, '\\"""'),
    i = n.split(/\r\n|[\n\r]/g),
    r = 1 === i.length,
    o =
      i.length > 1 &&
      i.slice(1).every((e) => 0 === e.length || O(e.charCodeAt(0))),
    s = n.endsWith('\\"""'),
    a = e.endsWith('"') && !s,
    c = e.endsWith("\\"),
    u = a || c,
    l = !(null != t && t.minimize) && (!r || e.length > 70 || u || o || s);
  let p = "";
  const d = r && O(e.charCodeAt(0));
  return (
    ((l && !d) || o) && (p += "\n"),
    (p += n),
    (l || u) && (p += "\n"),
    '"""' + p + '"""'
  );
}
!(function (e) {
  (e.QUERY = "query"),
    (e.MUTATION = "mutation"),
    (e.SUBSCRIPTION = "subscription");
})(I || (I = {})),
  (function (e) {
    (e.QUERY = "QUERY"),
      (e.MUTATION = "MUTATION"),
      (e.SUBSCRIPTION = "SUBSCRIPTION"),
      (e.FIELD = "FIELD"),
      (e.FRAGMENT_DEFINITION = "FRAGMENT_DEFINITION"),
      (e.FRAGMENT_SPREAD = "FRAGMENT_SPREAD"),
      (e.INLINE_FRAGMENT = "INLINE_FRAGMENT"),
      (e.VARIABLE_DEFINITION = "VARIABLE_DEFINITION"),
      (e.SCHEMA = "SCHEMA"),
      (e.SCALAR = "SCALAR"),
      (e.OBJECT = "OBJECT"),
      (e.FIELD_DEFINITION = "FIELD_DEFINITION"),
      (e.ARGUMENT_DEFINITION = "ARGUMENT_DEFINITION"),
      (e.INTERFACE = "INTERFACE"),
      (e.UNION = "UNION"),
      (e.ENUM = "ENUM"),
      (e.ENUM_VALUE = "ENUM_VALUE"),
      (e.INPUT_OBJECT = "INPUT_OBJECT"),
      (e.INPUT_FIELD_DEFINITION = "INPUT_FIELD_DEFINITION");
  })(g || (g = {})),
  (function (e) {
    (e.NAME = "Name"),
      (e.DOCUMENT = "Document"),
      (e.OPERATION_DEFINITION = "OperationDefinition"),
      (e.VARIABLE_DEFINITION = "VariableDefinition"),
      (e.SELECTION_SET = "SelectionSet"),
      (e.FIELD = "Field"),
      (e.ARGUMENT = "Argument"),
      (e.FRAGMENT_SPREAD = "FragmentSpread"),
      (e.INLINE_FRAGMENT = "InlineFragment"),
      (e.FRAGMENT_DEFINITION = "FragmentDefinition"),
      (e.VARIABLE = "Variable"),
      (e.INT = "IntValue"),
      (e.FLOAT = "FloatValue"),
      (e.STRING = "StringValue"),
      (e.BOOLEAN = "BooleanValue"),
      (e.NULL = "NullValue"),
      (e.ENUM = "EnumValue"),
      (e.LIST = "ListValue"),
      (e.OBJECT = "ObjectValue"),
      (e.OBJECT_FIELD = "ObjectField"),
      (e.DIRECTIVE = "Directive"),
      (e.NAMED_TYPE = "NamedType"),
      (e.LIST_TYPE = "ListType"),
      (e.NON_NULL_TYPE = "NonNullType"),
      (e.SCHEMA_DEFINITION = "SchemaDefinition"),
      (e.OPERATION_TYPE_DEFINITION = "OperationTypeDefinition"),
      (e.SCALAR_TYPE_DEFINITION = "ScalarTypeDefinition"),
      (e.OBJECT_TYPE_DEFINITION = "ObjectTypeDefinition"),
      (e.FIELD_DEFINITION = "FieldDefinition"),
      (e.INPUT_VALUE_DEFINITION = "InputValueDefinition"),
      (e.INTERFACE_TYPE_DEFINITION = "InterfaceTypeDefinition"),
      (e.UNION_TYPE_DEFINITION = "UnionTypeDefinition"),
      (e.ENUM_TYPE_DEFINITION = "EnumTypeDefinition"),
      (e.ENUM_VALUE_DEFINITION = "EnumValueDefinition"),
      (e.INPUT_OBJECT_TYPE_DEFINITION = "InputObjectTypeDefinition"),
      (e.DIRECTIVE_DEFINITION = "DirectiveDefinition"),
      (e.SCHEMA_EXTENSION = "SchemaExtension"),
      (e.SCALAR_TYPE_EXTENSION = "ScalarTypeExtension"),
      (e.OBJECT_TYPE_EXTENSION = "ObjectTypeExtension"),
      (e.INTERFACE_TYPE_EXTENSION = "InterfaceTypeExtension"),
      (e.UNION_TYPE_EXTENSION = "UnionTypeExtension"),
      (e.ENUM_TYPE_EXTENSION = "EnumTypeExtension"),
      (e.INPUT_OBJECT_TYPE_EXTENSION = "InputObjectTypeExtension");
  })(_ || (_ = {})),
  (function (e) {
    (e.SOF = "<SOF>"),
      (e.EOF = "<EOF>"),
      (e.BANG = "!"),
      (e.DOLLAR = "$"),
      (e.AMP = "&"),
      (e.PAREN_L = "("),
      (e.PAREN_R = ")"),
      (e.SPREAD = "..."),
      (e.COLON = ":"),
      (e.EQUALS = "="),
      (e.AT = "@"),
      (e.BRACKET_L = "["),
      (e.BRACKET_R = "]"),
      (e.BRACE_L = "{"),
      (e.PIPE = "|"),
      (e.BRACE_R = "}"),
      (e.NAME = "Name"),
      (e.INT = "Int"),
      (e.FLOAT = "Float"),
      (e.STRING = "String"),
      (e.BLOCK_STRING = "BlockString"),
      (e.COMMENT = "Comment");
  })(b || (b = {}));
class L {
  constructor(e) {
    const t = new E(b.SOF, 0, 0, 0, 0);
    (this.source = e),
      (this.lastToken = t),
      (this.token = t),
      (this.line = 1),
      (this.lineStart = 0);
  }
  get [Symbol.toStringTag]() {
    return "Lexer";
  }
  advance() {
    this.lastToken = this.token;
    return (this.token = this.lookahead());
  }
  lookahead() {
    let e = this.token;
    if (e.kind !== b.EOF)
      do {
        if (e.next) e = e.next;
        else {
          const t = B(this, e.end);
          (e.next = t), (t.prev = e), (e = t);
        }
      } while (e.kind === b.COMMENT);
    return e;
  }
}
function F(e) {
  return (
    e === b.BANG ||
    e === b.DOLLAR ||
    e === b.AMP ||
    e === b.PAREN_L ||
    e === b.PAREN_R ||
    e === b.SPREAD ||
    e === b.COLON ||
    e === b.EQUALS ||
    e === b.AT ||
    e === b.BRACKET_L ||
    e === b.BRACKET_R ||
    e === b.BRACE_L ||
    e === b.PIPE ||
    e === b.BRACE_R
  );
}
function C(e) {
  return (e >= 0 && e <= 55295) || (e >= 57344 && e <= 1114111);
}
function V(e, t) {
  return U(e.charCodeAt(t)) && M(e.charCodeAt(t + 1));
}
function U(e) {
  return e >= 55296 && e <= 56319;
}
function M(e) {
  return e >= 56320 && e <= 57343;
}
function j(e, t) {
  const n = e.source.body.codePointAt(t);
  if (void 0 === n) return b.EOF;
  if (n >= 32 && n <= 126) {
    const e = String.fromCodePoint(n);
    return '"' === e ? "'\"'" : `"${e}"`;
  }
  return "U+" + n.toString(16).toUpperCase().padStart(4, "0");
}
function P(e, t, n, i, r) {
  const o = e.line,
    s = 1 + n - e.lineStart;
  return new E(t, n, i, o, s, r);
}
function B(e, t) {
  const n = e.source.body,
    i = n.length;
  let r = t;
  for (; r < i; ) {
    const t = n.charCodeAt(r);
    switch (t) {
      case 65279:
      case 9:
      case 32:
      case 44:
        ++r;
        continue;
      case 10:
        ++r, ++e.line, (e.lineStart = r);
        continue;
      case 13:
        10 === n.charCodeAt(r + 1) ? (r += 2) : ++r,
          ++e.line,
          (e.lineStart = r);
        continue;
      case 35:
        return G(e, r);
      case 33:
        return P(e, b.BANG, r, r + 1);
      case 36:
        return P(e, b.DOLLAR, r, r + 1);
      case 38:
        return P(e, b.AMP, r, r + 1);
      case 40:
        return P(e, b.PAREN_L, r, r + 1);
      case 41:
        return P(e, b.PAREN_R, r, r + 1);
      case 46:
        if (46 === n.charCodeAt(r + 1) && 46 === n.charCodeAt(r + 2))
          return P(e, b.SPREAD, r, r + 3);
        break;
      case 58:
        return P(e, b.COLON, r, r + 1);
      case 61:
        return P(e, b.EQUALS, r, r + 1);
      case 64:
        return P(e, b.AT, r, r + 1);
      case 91:
        return P(e, b.BRACKET_L, r, r + 1);
      case 93:
        return P(e, b.BRACKET_R, r, r + 1);
      case 123:
        return P(e, b.BRACE_L, r, r + 1);
      case 124:
        return P(e, b.PIPE, r, r + 1);
      case 125:
        return P(e, b.BRACE_R, r, r + 1);
      case 34:
        return 34 === n.charCodeAt(r + 1) && 34 === n.charCodeAt(r + 2)
          ? W(e, r)
          : J(e, r);
    }
    if (D(t) || 45 === t) return Y(e, r, t);
    if (w(t)) return Z(e, r);
    throw m(
      e.source,
      r,
      39 === t
        ? "Unexpected single quote character ('), did you mean to use a double quote (\")?"
        : C(t) || V(n, r)
        ? `Unexpected character: ${j(e, r)}.`
        : `Invalid character: ${j(e, r)}.`
    );
  }
  return P(e, b.EOF, i, i);
}
function G(e, t) {
  const n = e.source.body,
    i = n.length;
  let r = t + 1;
  for (; r < i; ) {
    const e = n.charCodeAt(r);
    if (10 === e || 13 === e) break;
    if (C(e)) ++r;
    else {
      if (!V(n, r)) break;
      r += 2;
    }
  }
  return P(e, b.COMMENT, t, r, n.slice(t + 1, r));
}
function Y(e, t, n) {
  const i = e.source.body;
  let r = t,
    o = n,
    s = !1;
  if ((45 === o && (o = i.charCodeAt(++r)), 48 === o)) {
    if (((o = i.charCodeAt(++r)), D(o)))
      throw m(
        e.source,
        r,
        `Invalid number, unexpected digit after 0: ${j(e, r)}.`
      );
  } else (r = Q(e, r, o)), (o = i.charCodeAt(r));
  if (
    (46 === o &&
      ((s = !0),
      (o = i.charCodeAt(++r)),
      (r = Q(e, r, o)),
      (o = i.charCodeAt(r))),
    (69 !== o && 101 !== o) ||
      ((s = !0),
      (o = i.charCodeAt(++r)),
      (43 !== o && 45 !== o) || (o = i.charCodeAt(++r)),
      (r = Q(e, r, o)),
      (o = i.charCodeAt(r))),
    46 === o || w(o))
  )
    throw m(e.source, r, `Invalid number, expected digit but got: ${j(e, r)}.`);
  return P(e, s ? b.FLOAT : b.INT, t, r, i.slice(t, r));
}
function Q(e, t, n) {
  if (!D(n))
    throw m(e.source, t, `Invalid number, expected digit but got: ${j(e, t)}.`);
  const i = e.source.body;
  let r = t + 1;
  for (; D(i.charCodeAt(r)); ) ++r;
  return r;
}
function J(e, t) {
  const n = e.source.body,
    i = n.length;
  let r = t + 1,
    o = r,
    s = "";
  for (; r < i; ) {
    const i = n.charCodeAt(r);
    if (34 === i) return (s += n.slice(o, r)), P(e, b.STRING, t, r + 1, s);
    if (92 !== i) {
      if (10 === i || 13 === i) break;
      if (C(i)) ++r;
      else {
        if (!V(n, r))
          throw m(e.source, r, `Invalid character within String: ${j(e, r)}.`);
        r += 2;
      }
    } else {
      s += n.slice(o, r);
      const t =
        117 === n.charCodeAt(r + 1)
          ? 123 === n.charCodeAt(r + 2)
            ? q(e, r)
            : K(e, r)
          : H(e, r);
      (s += t.value), (r += t.size), (o = r);
    }
  }
  throw m(e.source, r, "Unterminated string.");
}
function q(e, t) {
  const n = e.source.body;
  let i = 0,
    r = 3;
  for (; r < 12; ) {
    const e = n.charCodeAt(t + r++);
    if (125 === e) {
      if (r < 5 || !C(i)) break;
      return { value: String.fromCodePoint(i), size: r };
    }
    if (((i = (i << 4) | z(e)), i < 0)) break;
  }
  throw m(
    e.source,
    t,
    `Invalid Unicode escape sequence: "${n.slice(t, t + r)}".`
  );
}
function K(e, t) {
  const n = e.source.body,
    i = X(n, t + 2);
  if (C(i)) return { value: String.fromCodePoint(i), size: 6 };
  if (U(i) && 92 === n.charCodeAt(t + 6) && 117 === n.charCodeAt(t + 7)) {
    const e = X(n, t + 8);
    if (M(e)) return { value: String.fromCodePoint(i, e), size: 12 };
  }
  throw m(
    e.source,
    t,
    `Invalid Unicode escape sequence: "${n.slice(t, t + 6)}".`
  );
}
function X(e, t) {
  return (
    (z(e.charCodeAt(t)) << 12) |
    (z(e.charCodeAt(t + 1)) << 8) |
    (z(e.charCodeAt(t + 2)) << 4) |
    z(e.charCodeAt(t + 3))
  );
}
function z(e) {
  return e >= 48 && e <= 57
    ? e - 48
    : e >= 65 && e <= 70
    ? e - 55
    : e >= 97 && e <= 102
    ? e - 87
    : -1;
}
function H(e, t) {
  const n = e.source.body;
  switch (n.charCodeAt(t + 1)) {
    case 34:
      return { value: '"', size: 2 };
    case 92:
      return { value: "\\", size: 2 };
    case 47:
      return { value: "/", size: 2 };
    case 98:
      return { value: "\b", size: 2 };
    case 102:
      return { value: "\f", size: 2 };
    case 110:
      return { value: "\n", size: 2 };
    case 114:
      return { value: "\r", size: 2 };
    case 116:
      return { value: "\t", size: 2 };
  }
  throw m(
    e.source,
    t,
    `Invalid character escape sequence: "${n.slice(t, t + 2)}".`
  );
}
function W(e, t) {
  const n = e.source.body,
    i = n.length;
  let r = e.lineStart,
    o = t + 3,
    s = o,
    a = "";
  const c = [];
  for (; o < i; ) {
    const i = n.charCodeAt(o);
    if (34 === i && 34 === n.charCodeAt(o + 1) && 34 === n.charCodeAt(o + 2)) {
      (a += n.slice(s, o)), c.push(a);
      const i = P(e, b.BLOCK_STRING, t, o + 3, R(c).join("\n"));
      return (e.line += c.length - 1), (e.lineStart = r), i;
    }
    if (
      92 !== i ||
      34 !== n.charCodeAt(o + 1) ||
      34 !== n.charCodeAt(o + 2) ||
      34 !== n.charCodeAt(o + 3)
    )
      if (10 !== i && 13 !== i)
        if (C(i)) ++o;
        else {
          if (!V(n, o))
            throw m(
              e.source,
              o,
              `Invalid character within String: ${j(e, o)}.`
            );
          o += 2;
        }
      else
        (a += n.slice(s, o)),
          c.push(a),
          13 === i && 10 === n.charCodeAt(o + 1) ? (o += 2) : ++o,
          (a = ""),
          (s = o),
          (r = o);
    else (a += n.slice(s, o)), (s = o + 1), (o += 4);
  }
  throw m(e.source, o, "Unterminated string.");
}
function Z(e, t) {
  const n = e.source.body,
    i = n.length;
  let r = t + 1;
  for (; r < i; ) {
    if (!S(n.charCodeAt(r))) break;
    ++r;
  }
  return P(e, b.NAME, t, r, n.slice(t, r));
}
const ee = 10,
  te = 2;
function ne(e) {
  return ie(e, []);
}
function ie(e, t) {
  switch (typeof e) {
    case "string":
      return JSON.stringify(e);
    case "function":
      return e.name ? `[function ${e.name}]` : "[function]";
    case "object":
      return (function (e, t) {
        if (null === e) return "null";
        if (t.includes(e)) return "[Circular]";
        const n = [...t, e];
        if (
          (function (e) {
            return "function" == typeof e.toJSON;
          })(e)
        ) {
          const t = e.toJSON();
          if (t !== e) return "string" == typeof t ? t : ie(t, n);
        } else if (Array.isArray(e))
          return (function (e, t) {
            if (0 === e.length) return "[]";
            if (t.length > te) return "[Array]";
            const n = Math.min(ee, e.length),
              i = e.length - n,
              r = [];
            for (let i = 0; i < n; ++i) r.push(ie(e[i], t));
            1 === i
              ? r.push("... 1 more item")
              : i > 1 && r.push(`... ${i} more items`);
            return "[" + r.join(", ") + "]";
          })(e, n);
        return (function (e, t) {
          const n = Object.entries(e);
          if (0 === n.length) return "{}";
          if (t.length > te)
            return (
              "[" +
              (function (e) {
                const t = Object.prototype.toString
                  .call(e)
                  .replace(/^\[object /, "")
                  .replace(/]$/, "");
                if ("Object" === t && "function" == typeof e.constructor) {
                  const t = e.constructor.name;
                  if ("string" == typeof t && "" !== t) return t;
                }
                return t;
              })(e) +
              "]"
            );
          const i = n.map(([e, n]) => e + ": " + ie(n, t));
          return "{ " + i.join(", ") + " }";
        })(e, n);
      })(e, t);
    default:
      return String(e);
  }
}
const re = function (e, t) {
  return e instanceof t;
};
class oe {
  constructor(e, t = "GraphQL request", i = { line: 1, column: 1 }) {
    "string" == typeof e || n(!1, `Body must be a string. Received: ${ne(e)}.`),
      (this.body = e),
      (this.name = t),
      (this.locationOffset = i),
      this.locationOffset.line > 0 ||
        n(!1, "line in locationOffset is 1-indexed and must be positive."),
      this.locationOffset.column > 0 ||
        n(!1, "column in locationOffset is 1-indexed and must be positive.");
  }
  get [Symbol.toStringTag]() {
    return "Source";
  }
}
function se(e) {
  return re(e, oe);
}
function ae(e, t) {
  return new pe(e, t).parseDocument();
}
function ce(e, t) {
  const n = new pe(e, t);
  n.expectToken(b.SOF);
  const i = n.parseValueLiteral(!1);
  return n.expectToken(b.EOF), i;
}
function ue(e, t) {
  const n = new pe(e, t);
  n.expectToken(b.SOF);
  const i = n.parseConstValueLiteral();
  return n.expectToken(b.EOF), i;
}
function le(e, t) {
  const n = new pe(e, t);
  n.expectToken(b.SOF);
  const i = n.parseTypeReference();
  return n.expectToken(b.EOF), i;
}
class pe {
  constructor(e, t = {}) {
    const n = se(e) ? e : new oe(e);
    (this._lexer = new L(n)), (this._options = t), (this._tokenCounter = 0);
  }
  parseName() {
    const e = this.expectToken(b.NAME);
    return this.node(e, { kind: _.NAME, value: e.value });
  }
  parseDocument() {
    return this.node(this._lexer.token, {
      kind: _.DOCUMENT,
      definitions: this.many(b.SOF, this.parseDefinition, b.EOF),
    });
  }
  parseDefinition() {
    if (this.peek(b.BRACE_L)) return this.parseOperationDefinition();
    const e = this.peekDescription(),
      t = e ? this._lexer.lookahead() : this._lexer.token;
    if (t.kind === b.NAME) {
      switch (t.value) {
        case "schema":
          return this.parseSchemaDefinition();
        case "scalar":
          return this.parseScalarTypeDefinition();
        case "type":
          return this.parseObjectTypeDefinition();
        case "interface":
          return this.parseInterfaceTypeDefinition();
        case "union":
          return this.parseUnionTypeDefinition();
        case "enum":
          return this.parseEnumTypeDefinition();
        case "input":
          return this.parseInputObjectTypeDefinition();
        case "directive":
          return this.parseDirectiveDefinition();
      }
      if (e)
        throw m(
          this._lexer.source,
          this._lexer.token.start,
          "Unexpected description, descriptions are supported only on type definitions."
        );
      switch (t.value) {
        case "query":
        case "mutation":
        case "subscription":
          return this.parseOperationDefinition();
        case "fragment":
          return this.parseFragmentDefinition();
        case "extend":
          return this.parseTypeSystemExtension();
      }
    }
    throw this.unexpected(t);
  }
  parseOperationDefinition() {
    const e = this._lexer.token;
    if (this.peek(b.BRACE_L))
      return this.node(e, {
        kind: _.OPERATION_DEFINITION,
        operation: I.QUERY,
        name: void 0,
        variableDefinitions: [],
        directives: [],
        selectionSet: this.parseSelectionSet(),
      });
    const t = this.parseOperationType();
    let n;
    return (
      this.peek(b.NAME) && (n = this.parseName()),
      this.node(e, {
        kind: _.OPERATION_DEFINITION,
        operation: t,
        name: n,
        variableDefinitions: this.parseVariableDefinitions(),
        directives: this.parseDirectives(!1),
        selectionSet: this.parseSelectionSet(),
      })
    );
  }
  parseOperationType() {
    const e = this.expectToken(b.NAME);
    switch (e.value) {
      case "query":
        return I.QUERY;
      case "mutation":
        return I.MUTATION;
      case "subscription":
        return I.SUBSCRIPTION;
    }
    throw this.unexpected(e);
  }
  parseVariableDefinitions() {
    return this.optionalMany(
      b.PAREN_L,
      this.parseVariableDefinition,
      b.PAREN_R
    );
  }
  parseVariableDefinition() {
    return this.node(this._lexer.token, {
      kind: _.VARIABLE_DEFINITION,
      variable: this.parseVariable(),
      type: (this.expectToken(b.COLON), this.parseTypeReference()),
      defaultValue: this.expectOptionalToken(b.EQUALS)
        ? this.parseConstValueLiteral()
        : void 0,
      directives: this.parseConstDirectives(),
    });
  }
  parseVariable() {
    const e = this._lexer.token;
    return (
      this.expectToken(b.DOLLAR),
      this.node(e, { kind: _.VARIABLE, name: this.parseName() })
    );
  }
  parseSelectionSet() {
    return this.node(this._lexer.token, {
      kind: _.SELECTION_SET,
      selections: this.many(b.BRACE_L, this.parseSelection, b.BRACE_R),
    });
  }
  parseSelection() {
    return this.peek(b.SPREAD) ? this.parseFragment() : this.parseField();
  }
  parseField() {
    const e = this._lexer.token,
      t = this.parseName();
    let n, i;
    return (
      this.expectOptionalToken(b.COLON)
        ? ((n = t), (i = this.parseName()))
        : (i = t),
      this.node(e, {
        kind: _.FIELD,
        alias: n,
        name: i,
        arguments: this.parseArguments(!1),
        directives: this.parseDirectives(!1),
        selectionSet: this.peek(b.BRACE_L) ? this.parseSelectionSet() : void 0,
      })
    );
  }
  parseArguments(e) {
    const t = e ? this.parseConstArgument : this.parseArgument;
    return this.optionalMany(b.PAREN_L, t, b.PAREN_R);
  }
  parseArgument(e = !1) {
    const t = this._lexer.token,
      n = this.parseName();
    return (
      this.expectToken(b.COLON),
      this.node(t, {
        kind: _.ARGUMENT,
        name: n,
        value: this.parseValueLiteral(e),
      })
    );
  }
  parseConstArgument() {
    return this.parseArgument(!0);
  }
  parseFragment() {
    const e = this._lexer.token;
    this.expectToken(b.SPREAD);
    const t = this.expectOptionalKeyword("on");
    return !t && this.peek(b.NAME)
      ? this.node(e, {
          kind: _.FRAGMENT_SPREAD,
          name: this.parseFragmentName(),
          directives: this.parseDirectives(!1),
        })
      : this.node(e, {
          kind: _.INLINE_FRAGMENT,
          typeCondition: t ? this.parseNamedType() : void 0,
          directives: this.parseDirectives(!1),
          selectionSet: this.parseSelectionSet(),
        });
  }
  parseFragmentDefinition() {
    const e = this._lexer.token;
    return (
      this.expectKeyword("fragment"),
      !0 === this._options.allowLegacyFragmentVariables
        ? this.node(e, {
            kind: _.FRAGMENT_DEFINITION,
            name: this.parseFragmentName(),
            variableDefinitions: this.parseVariableDefinitions(),
            typeCondition: (this.expectKeyword("on"), this.parseNamedType()),
            directives: this.parseDirectives(!1),
            selectionSet: this.parseSelectionSet(),
          })
        : this.node(e, {
            kind: _.FRAGMENT_DEFINITION,
            name: this.parseFragmentName(),
            typeCondition: (this.expectKeyword("on"), this.parseNamedType()),
            directives: this.parseDirectives(!1),
            selectionSet: this.parseSelectionSet(),
          })
    );
  }
  parseFragmentName() {
    if ("on" === this._lexer.token.value) throw this.unexpected();
    return this.parseName();
  }
  parseValueLiteral(e) {
    const t = this._lexer.token;
    switch (t.kind) {
      case b.BRACKET_L:
        return this.parseList(e);
      case b.BRACE_L:
        return this.parseObject(e);
      case b.INT:
        return (
          this.advanceLexer(), this.node(t, { kind: _.INT, value: t.value })
        );
      case b.FLOAT:
        return (
          this.advanceLexer(), this.node(t, { kind: _.FLOAT, value: t.value })
        );
      case b.STRING:
      case b.BLOCK_STRING:
        return this.parseStringLiteral();
      case b.NAME:
        switch ((this.advanceLexer(), t.value)) {
          case "true":
            return this.node(t, { kind: _.BOOLEAN, value: !0 });
          case "false":
            return this.node(t, { kind: _.BOOLEAN, value: !1 });
          case "null":
            return this.node(t, { kind: _.NULL });
          default:
            return this.node(t, { kind: _.ENUM, value: t.value });
        }
      case b.DOLLAR:
        if (e) {
          if ((this.expectToken(b.DOLLAR), this._lexer.token.kind === b.NAME)) {
            const e = this._lexer.token.value;
            throw m(
              this._lexer.source,
              t.start,
              `Unexpected variable "$${e}" in constant value.`
            );
          }
          throw this.unexpected(t);
        }
        return this.parseVariable();
      default:
        throw this.unexpected();
    }
  }
  parseConstValueLiteral() {
    return this.parseValueLiteral(!0);
  }
  parseStringLiteral() {
    const e = this._lexer.token;
    return (
      this.advanceLexer(),
      this.node(e, {
        kind: _.STRING,
        value: e.value,
        block: e.kind === b.BLOCK_STRING,
      })
    );
  }
  parseList(e) {
    return this.node(this._lexer.token, {
      kind: _.LIST,
      values: this.any(
        b.BRACKET_L,
        () => this.parseValueLiteral(e),
        b.BRACKET_R
      ),
    });
  }
  parseObject(e) {
    return this.node(this._lexer.token, {
      kind: _.OBJECT,
      fields: this.any(b.BRACE_L, () => this.parseObjectField(e), b.BRACE_R),
    });
  }
  parseObjectField(e) {
    const t = this._lexer.token,
      n = this.parseName();
    return (
      this.expectToken(b.COLON),
      this.node(t, {
        kind: _.OBJECT_FIELD,
        name: n,
        value: this.parseValueLiteral(e),
      })
    );
  }
  parseDirectives(e) {
    const t = [];
    for (; this.peek(b.AT); ) t.push(this.parseDirective(e));
    return t;
  }
  parseConstDirectives() {
    return this.parseDirectives(!0);
  }
  parseDirective(e) {
    const t = this._lexer.token;
    return (
      this.expectToken(b.AT),
      this.node(t, {
        kind: _.DIRECTIVE,
        name: this.parseName(),
        arguments: this.parseArguments(e),
      })
    );
  }
  parseTypeReference() {
    const e = this._lexer.token;
    let t;
    if (this.expectOptionalToken(b.BRACKET_L)) {
      const n = this.parseTypeReference();
      this.expectToken(b.BRACKET_R),
        (t = this.node(e, { kind: _.LIST_TYPE, type: n }));
    } else t = this.parseNamedType();
    return this.expectOptionalToken(b.BANG)
      ? this.node(e, { kind: _.NON_NULL_TYPE, type: t })
      : t;
  }
  parseNamedType() {
    return this.node(this._lexer.token, {
      kind: _.NAMED_TYPE,
      name: this.parseName(),
    });
  }
  peekDescription() {
    return this.peek(b.STRING) || this.peek(b.BLOCK_STRING);
  }
  parseDescription() {
    if (this.peekDescription()) return this.parseStringLiteral();
  }
  parseSchemaDefinition() {
    const e = this._lexer.token,
      t = this.parseDescription();
    this.expectKeyword("schema");
    const n = this.parseConstDirectives(),
      i = this.many(b.BRACE_L, this.parseOperationTypeDefinition, b.BRACE_R);
    return this.node(e, {
      kind: _.SCHEMA_DEFINITION,
      description: t,
      directives: n,
      operationTypes: i,
    });
  }
  parseOperationTypeDefinition() {
    const e = this._lexer.token,
      t = this.parseOperationType();
    this.expectToken(b.COLON);
    const n = this.parseNamedType();
    return this.node(e, {
      kind: _.OPERATION_TYPE_DEFINITION,
      operation: t,
      type: n,
    });
  }
  parseScalarTypeDefinition() {
    const e = this._lexer.token,
      t = this.parseDescription();
    this.expectKeyword("scalar");
    const n = this.parseName(),
      i = this.parseConstDirectives();
    return this.node(e, {
      kind: _.SCALAR_TYPE_DEFINITION,
      description: t,
      name: n,
      directives: i,
    });
  }
  parseObjectTypeDefinition() {
    const e = this._lexer.token,
      t = this.parseDescription();
    this.expectKeyword("type");
    const n = this.parseName(),
      i = this.parseImplementsInterfaces(),
      r = this.parseConstDirectives(),
      o = this.parseFieldsDefinition();
    return this.node(e, {
      kind: _.OBJECT_TYPE_DEFINITION,
      description: t,
      name: n,
      interfaces: i,
      directives: r,
      fields: o,
    });
  }
  parseImplementsInterfaces() {
    return this.expectOptionalKeyword("implements")
      ? this.delimitedMany(b.AMP, this.parseNamedType)
      : [];
  }
  parseFieldsDefinition() {
    return this.optionalMany(b.BRACE_L, this.parseFieldDefinition, b.BRACE_R);
  }
  parseFieldDefinition() {
    const e = this._lexer.token,
      t = this.parseDescription(),
      n = this.parseName(),
      i = this.parseArgumentDefs();
    this.expectToken(b.COLON);
    const r = this.parseTypeReference(),
      o = this.parseConstDirectives();
    return this.node(e, {
      kind: _.FIELD_DEFINITION,
      description: t,
      name: n,
      arguments: i,
      type: r,
      directives: o,
    });
  }
  parseArgumentDefs() {
    return this.optionalMany(b.PAREN_L, this.parseInputValueDef, b.PAREN_R);
  }
  parseInputValueDef() {
    const e = this._lexer.token,
      t = this.parseDescription(),
      n = this.parseName();
    this.expectToken(b.COLON);
    const i = this.parseTypeReference();
    let r;
    this.expectOptionalToken(b.EQUALS) && (r = this.parseConstValueLiteral());
    const o = this.parseConstDirectives();
    return this.node(e, {
      kind: _.INPUT_VALUE_DEFINITION,
      description: t,
      name: n,
      type: i,
      defaultValue: r,
      directives: o,
    });
  }
  parseInterfaceTypeDefinition() {
    const e = this._lexer.token,
      t = this.parseDescription();
    this.expectKeyword("interface");
    const n = this.parseName(),
      i = this.parseImplementsInterfaces(),
      r = this.parseConstDirectives(),
      o = this.parseFieldsDefinition();
    return this.node(e, {
      kind: _.INTERFACE_TYPE_DEFINITION,
      description: t,
      name: n,
      interfaces: i,
      directives: r,
      fields: o,
    });
  }
  parseUnionTypeDefinition() {
    const e = this._lexer.token,
      t = this.parseDescription();
    this.expectKeyword("union");
    const n = this.parseName(),
      i = this.parseConstDirectives(),
      r = this.parseUnionMemberTypes();
    return this.node(e, {
      kind: _.UNION_TYPE_DEFINITION,
      description: t,
      name: n,
      directives: i,
      types: r,
    });
  }
  parseUnionMemberTypes() {
    return this.expectOptionalToken(b.EQUALS)
      ? this.delimitedMany(b.PIPE, this.parseNamedType)
      : [];
  }
  parseEnumTypeDefinition() {
    const e = this._lexer.token,
      t = this.parseDescription();
    this.expectKeyword("enum");
    const n = this.parseName(),
      i = this.parseConstDirectives(),
      r = this.parseEnumValuesDefinition();
    return this.node(e, {
      kind: _.ENUM_TYPE_DEFINITION,
      description: t,
      name: n,
      directives: i,
      values: r,
    });
  }
  parseEnumValuesDefinition() {
    return this.optionalMany(
      b.BRACE_L,
      this.parseEnumValueDefinition,
      b.BRACE_R
    );
  }
  parseEnumValueDefinition() {
    const e = this._lexer.token,
      t = this.parseDescription(),
      n = this.parseEnumValueName(),
      i = this.parseConstDirectives();
    return this.node(e, {
      kind: _.ENUM_VALUE_DEFINITION,
      description: t,
      name: n,
      directives: i,
    });
  }
  parseEnumValueName() {
    if (
      "true" === this._lexer.token.value ||
      "false" === this._lexer.token.value ||
      "null" === this._lexer.token.value
    )
      throw m(
        this._lexer.source,
        this._lexer.token.start,
        `${de(
          this._lexer.token
        )} is reserved and cannot be used for an enum value.`
      );
    return this.parseName();
  }
  parseInputObjectTypeDefinition() {
    const e = this._lexer.token,
      t = this.parseDescription();
    this.expectKeyword("input");
    const n = this.parseName(),
      i = this.parseConstDirectives(),
      r = this.parseInputFieldsDefinition();
    return this.node(e, {
      kind: _.INPUT_OBJECT_TYPE_DEFINITION,
      description: t,
      name: n,
      directives: i,
      fields: r,
    });
  }
  parseInputFieldsDefinition() {
    return this.optionalMany(b.BRACE_L, this.parseInputValueDef, b.BRACE_R);
  }
  parseTypeSystemExtension() {
    const e = this._lexer.lookahead();
    if (e.kind === b.NAME)
      switch (e.value) {
        case "schema":
          return this.parseSchemaExtension();
        case "scalar":
          return this.parseScalarTypeExtension();
        case "type":
          return this.parseObjectTypeExtension();
        case "interface":
          return this.parseInterfaceTypeExtension();
        case "union":
          return this.parseUnionTypeExtension();
        case "enum":
          return this.parseEnumTypeExtension();
        case "input":
          return this.parseInputObjectTypeExtension();
      }
    throw this.unexpected(e);
  }
  parseSchemaExtension() {
    const e = this._lexer.token;
    this.expectKeyword("extend"), this.expectKeyword("schema");
    const t = this.parseConstDirectives(),
      n = this.optionalMany(
        b.BRACE_L,
        this.parseOperationTypeDefinition,
        b.BRACE_R
      );
    if (0 === t.length && 0 === n.length) throw this.unexpected();
    return this.node(e, {
      kind: _.SCHEMA_EXTENSION,
      directives: t,
      operationTypes: n,
    });
  }
  parseScalarTypeExtension() {
    const e = this._lexer.token;
    this.expectKeyword("extend"), this.expectKeyword("scalar");
    const t = this.parseName(),
      n = this.parseConstDirectives();
    if (0 === n.length) throw this.unexpected();
    return this.node(e, {
      kind: _.SCALAR_TYPE_EXTENSION,
      name: t,
      directives: n,
    });
  }
  parseObjectTypeExtension() {
    const e = this._lexer.token;
    this.expectKeyword("extend"), this.expectKeyword("type");
    const t = this.parseName(),
      n = this.parseImplementsInterfaces(),
      i = this.parseConstDirectives(),
      r = this.parseFieldsDefinition();
    if (0 === n.length && 0 === i.length && 0 === r.length)
      throw this.unexpected();
    return this.node(e, {
      kind: _.OBJECT_TYPE_EXTENSION,
      name: t,
      interfaces: n,
      directives: i,
      fields: r,
    });
  }
  parseInterfaceTypeExtension() {
    const e = this._lexer.token;
    this.expectKeyword("extend"), this.expectKeyword("interface");
    const t = this.parseName(),
      n = this.parseImplementsInterfaces(),
      i = this.parseConstDirectives(),
      r = this.parseFieldsDefinition();
    if (0 === n.length && 0 === i.length && 0 === r.length)
      throw this.unexpected();
    return this.node(e, {
      kind: _.INTERFACE_TYPE_EXTENSION,
      name: t,
      interfaces: n,
      directives: i,
      fields: r,
    });
  }
  parseUnionTypeExtension() {
    const e = this._lexer.token;
    this.expectKeyword("extend"), this.expectKeyword("union");
    const t = this.parseName(),
      n = this.parseConstDirectives(),
      i = this.parseUnionMemberTypes();
    if (0 === n.length && 0 === i.length) throw this.unexpected();
    return this.node(e, {
      kind: _.UNION_TYPE_EXTENSION,
      name: t,
      directives: n,
      types: i,
    });
  }
  parseEnumTypeExtension() {
    const e = this._lexer.token;
    this.expectKeyword("extend"), this.expectKeyword("enum");
    const t = this.parseName(),
      n = this.parseConstDirectives(),
      i = this.parseEnumValuesDefinition();
    if (0 === n.length && 0 === i.length) throw this.unexpected();
    return this.node(e, {
      kind: _.ENUM_TYPE_EXTENSION,
      name: t,
      directives: n,
      values: i,
    });
  }
  parseInputObjectTypeExtension() {
    const e = this._lexer.token;
    this.expectKeyword("extend"), this.expectKeyword("input");
    const t = this.parseName(),
      n = this.parseConstDirectives(),
      i = this.parseInputFieldsDefinition();
    if (0 === n.length && 0 === i.length) throw this.unexpected();
    return this.node(e, {
      kind: _.INPUT_OBJECT_TYPE_EXTENSION,
      name: t,
      directives: n,
      fields: i,
    });
  }
  parseDirectiveDefinition() {
    const e = this._lexer.token,
      t = this.parseDescription();
    this.expectKeyword("directive"), this.expectToken(b.AT);
    const n = this.parseName(),
      i = this.parseArgumentDefs(),
      r = this.expectOptionalKeyword("repeatable");
    this.expectKeyword("on");
    const o = this.parseDirectiveLocations();
    return this.node(e, {
      kind: _.DIRECTIVE_DEFINITION,
      description: t,
      name: n,
      arguments: i,
      repeatable: r,
      locations: o,
    });
  }
  parseDirectiveLocations() {
    return this.delimitedMany(b.PIPE, this.parseDirectiveLocation);
  }
  parseDirectiveLocation() {
    const e = this._lexer.token,
      t = this.parseName();
    if (Object.prototype.hasOwnProperty.call(g, t.value)) return t;
    throw this.unexpected(e);
  }
  node(e, t) {
    return (
      !0 !== this._options.noLocation &&
        (t.loc = new y(e, this._lexer.lastToken, this._lexer.source)),
      t
    );
  }
  peek(e) {
    return this._lexer.token.kind === e;
  }
  expectToken(e) {
    const t = this._lexer.token;
    if (t.kind === e) return this.advanceLexer(), t;
    throw m(this._lexer.source, t.start, `Expected ${fe(e)}, found ${de(t)}.`);
  }
  expectOptionalToken(e) {
    return this._lexer.token.kind === e && (this.advanceLexer(), !0);
  }
  expectKeyword(e) {
    const t = this._lexer.token;
    if (t.kind !== b.NAME || t.value !== e)
      throw m(this._lexer.source, t.start, `Expected "${e}", found ${de(t)}.`);
    this.advanceLexer();
  }
  expectOptionalKeyword(e) {
    const t = this._lexer.token;
    return t.kind === b.NAME && t.value === e && (this.advanceLexer(), !0);
  }
  unexpected(e) {
    const t = null != e ? e : this._lexer.token;
    return m(this._lexer.source, t.start, `Unexpected ${de(t)}.`);
  }
  any(e, t, n) {
    this.expectToken(e);
    const i = [];
    for (; !this.expectOptionalToken(n); ) i.push(t.call(this));
    return i;
  }
  optionalMany(e, t, n) {
    if (this.expectOptionalToken(e)) {
      const e = [];
      do {
        e.push(t.call(this));
      } while (!this.expectOptionalToken(n));
      return e;
    }
    return [];
  }
  many(e, t, n) {
    this.expectToken(e);
    const i = [];
    do {
      i.push(t.call(this));
    } while (!this.expectOptionalToken(n));
    return i;
  }
  delimitedMany(e, t) {
    this.expectOptionalToken(e);
    const n = [];
    do {
      n.push(t.call(this));
    } while (this.expectOptionalToken(e));
    return n;
  }
  advanceLexer() {
    const { maxTokens: e } = this._options,
      t = this._lexer.advance();
    if (
      void 0 !== e &&
      t.kind !== b.EOF &&
      (++this._tokenCounter, this._tokenCounter > e)
    )
      throw m(
        this._lexer.source,
        t.start,
        `Document contains more that ${e} tokens. Parsing aborted.`
      );
  }
}
function de(e) {
  const t = e.value;
  return fe(e.kind) + (null != t ? ` "${t}"` : "");
}
function fe(e) {
  return F(e) ? `"${e}"` : e;
}
const he = 5;
function me(e, t) {
  const [n, i] = t ? [e, t] : [void 0, e];
  let r = " Did you mean ";
  n && (r += n + " ");
  const o = i.map((e) => `"${e}"`);
  switch (o.length) {
    case 0:
      return "";
    case 1:
      return r + o[0] + "?";
    case 2:
      return r + o[0] + " or " + o[1] + "?";
  }
  const s = o.slice(0, he),
    a = s.pop();
  return r + s.join(", ") + ", or " + a + "?";
}
function ye(e) {
  return e;
}
function Ee(e, t) {
  const n = Object.create(null);
  for (const i of e) n[t(i)] = i;
  return n;
}
function ve(e, t, n) {
  const i = Object.create(null);
  for (const r of e) i[t(r)] = n(r);
  return i;
}
function Te(e, t) {
  const n = Object.create(null);
  for (const i of Object.keys(e)) n[i] = t(e[i], i);
  return n;
}
function Ne(e, t) {
  let n = 0,
    i = 0;
  for (; n < e.length && i < t.length; ) {
    let r = e.charCodeAt(n),
      o = t.charCodeAt(i);
    if (_e(r) && _e(o)) {
      let s = 0;
      do {
        ++n, (s = 10 * s + r - Ie), (r = e.charCodeAt(n));
      } while (_e(r) && s > 0);
      let a = 0;
      do {
        ++i, (a = 10 * a + o - Ie), (o = t.charCodeAt(i));
      } while (_e(o) && a > 0);
      if (s < a) return -1;
      if (s > a) return 1;
    } else {
      if (r < o) return -1;
      if (r > o) return 1;
      ++n, ++i;
    }
  }
  return e.length - t.length;
}
const Ie = 48,
  ge = 57;
function _e(e) {
  return !isNaN(e) && Ie <= e && e <= ge;
}
function be(e, t) {
  const n = Object.create(null),
    i = new Oe(e),
    r = Math.floor(0.4 * e.length) + 1;
  for (const e of t) {
    const t = i.measure(e, r);
    void 0 !== t && (n[e] = t);
  }
  return Object.keys(n).sort((e, t) => {
    const i = n[e] - n[t];
    return 0 !== i ? i : Ne(e, t);
  });
}
class Oe {
  constructor(e) {
    (this._input = e),
      (this._inputLowerCase = e.toLowerCase()),
      (this._inputArray = De(this._inputLowerCase)),
      (this._rows = [
        new Array(e.length + 1).fill(0),
        new Array(e.length + 1).fill(0),
        new Array(e.length + 1).fill(0),
      ]);
  }
  measure(e, t) {
    if (this._input === e) return 0;
    const n = e.toLowerCase();
    if (this._inputLowerCase === n) return 1;
    let i = De(n),
      r = this._inputArray;
    if (i.length < r.length) {
      const e = i;
      (i = r), (r = e);
    }
    const o = i.length,
      s = r.length;
    if (o - s > t) return;
    const a = this._rows;
    for (let e = 0; e <= s; e++) a[0][e] = e;
    for (let e = 1; e <= o; e++) {
      const n = a[(e - 1) % 3],
        o = a[e % 3];
      let c = (o[0] = e);
      for (let t = 1; t <= s; t++) {
        const s = i[e - 1] === r[t - 1] ? 0 : 1;
        let u = Math.min(n[t] + 1, o[t - 1] + 1, n[t - 1] + s);
        if (e > 1 && t > 1 && i[e - 1] === r[t - 2] && i[e - 2] === r[t - 1]) {
          const n = a[(e - 2) % 3][t - 2];
          u = Math.min(u, n + 1);
        }
        u < c && (c = u), (o[t] = u);
      }
      if (c > t) return;
    }
    const c = a[o % 3][s];
    return c <= t ? c : void 0;
  }
}
function De(e) {
  const t = e.length,
    n = new Array(t);
  for (let i = 0; i < t; ++i) n[i] = e.charCodeAt(i);
  return n;
}
function Ae(e) {
  if (null == e) return Object.create(null);
  if (null === Object.getPrototypeOf(e)) return e;
  const t = Object.create(null);
  for (const [n, i] of Object.entries(e)) t[n] = i;
  return t;
}
const we = /[\x00-\x1f\x22\x5c\x7f-\x9f]/g;
function Se(e) {
  return Re[e.charCodeAt(0)];
}
const Re = [
    "\\u0000",
    "\\u0001",
    "\\u0002",
    "\\u0003",
    "\\u0004",
    "\\u0005",
    "\\u0006",
    "\\u0007",
    "\\b",
    "\\t",
    "\\n",
    "\\u000B",
    "\\f",
    "\\r",
    "\\u000E",
    "\\u000F",
    "\\u0010",
    "\\u0011",
    "\\u0012",
    "\\u0013",
    "\\u0014",
    "\\u0015",
    "\\u0016",
    "\\u0017",
    "\\u0018",
    "\\u0019",
    "\\u001A",
    "\\u001B",
    "\\u001C",
    "\\u001D",
    "\\u001E",
    "\\u001F",
    "",
    "",
    '\\"',
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "\\\\",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "",
    "\\u007F",
    "\\u0080",
    "\\u0081",
    "\\u0082",
    "\\u0083",
    "\\u0084",
    "\\u0085",
    "\\u0086",
    "\\u0087",
    "\\u0088",
    "\\u0089",
    "\\u008A",
    "\\u008B",
    "\\u008C",
    "\\u008D",
    "\\u008E",
    "\\u008F",
    "\\u0090",
    "\\u0091",
    "\\u0092",
    "\\u0093",
    "\\u0094",
    "\\u0095",
    "\\u0096",
    "\\u0097",
    "\\u0098",
    "\\u0099",
    "\\u009A",
    "\\u009B",
    "\\u009C",
    "\\u009D",
    "\\u009E",
    "\\u009F",
  ],
  $e = Object.freeze({});
function xe(e, t, i = v) {
  const r = new Map();
  for (const e of Object.values(_)) r.set(e, Le(t, e));
  let o,
    s,
    a,
    c = Array.isArray(e),
    u = [e],
    l = -1,
    p = [],
    d = e;
  const f = [],
    h = [];
  do {
    l++;
    const e = l === u.length,
      v = e && 0 !== p.length;
    if (e) {
      if (
        ((s = 0 === h.length ? void 0 : f[f.length - 1]),
        (d = a),
        (a = h.pop()),
        v)
      )
        if (c) {
          d = d.slice();
          let e = 0;
          for (const [t, n] of p) {
            const i = t - e;
            null === n ? (d.splice(i, 1), e++) : (d[i] = n);
          }
        } else {
          d = Object.defineProperties({}, Object.getOwnPropertyDescriptors(d));
          for (const [e, t] of p) d[e] = t;
        }
      (l = o.index), (u = o.keys), (p = o.edits), (c = o.inArray), (o = o.prev);
    } else if (a) {
      if (((s = c ? l : u[l]), (d = a[s]), null == d)) continue;
      f.push(s);
    }
    let T;
    if (!Array.isArray(d)) {
      var m, y;
      N(d) || n(!1, `Invalid AST Node: ${ne(d)}.`);
      const i = e
        ? null === (m = r.get(d.kind)) || void 0 === m
          ? void 0
          : m.leave
        : null === (y = r.get(d.kind)) || void 0 === y
        ? void 0
        : y.enter;
      if (((T = null == i ? void 0 : i.call(t, d, s, a, f, h)), T === $e))
        break;
      if (!1 === T) {
        if (!e) {
          f.pop();
          continue;
        }
      } else if (void 0 !== T && (p.push([s, T]), !e)) {
        if (!N(T)) {
          f.pop();
          continue;
        }
        d = T;
      }
    }
    var E;
    if ((void 0 === T && v && p.push([s, d]), e)) f.pop();
    else
      (o = { inArray: c, index: l, keys: u, edits: p, prev: o }),
        (c = Array.isArray(d)),
        (u = c ? d : null !== (E = i[d.kind]) && void 0 !== E ? E : []),
        (l = -1),
        (p = []),
        a && h.push(a),
        (a = d);
  } while (void 0 !== o);
  return 0 !== p.length ? p[p.length - 1][1] : e;
}
function ke(e) {
  const t = new Array(e.length).fill(null),
    n = Object.create(null);
  for (const i of Object.values(_)) {
    let r = !1;
    const o = new Array(e.length).fill(void 0),
      s = new Array(e.length).fill(void 0);
    for (let t = 0; t < e.length; ++t) {
      const { enter: n, leave: a } = Le(e[t], i);
      r || (r = null != n || null != a), (o[t] = n), (s[t] = a);
    }
    if (!r) continue;
    const a = {
      enter(...n) {
        const i = n[0];
        for (let s = 0; s < e.length; s++)
          if (null === t[s]) {
            var r;
            const a =
              null === (r = o[s]) || void 0 === r ? void 0 : r.apply(e[s], n);
            if (!1 === a) t[s] = i;
            else if (a === $e) t[s] = $e;
            else if (void 0 !== a) return a;
          }
      },
      leave(...n) {
        const i = n[0];
        for (let o = 0; o < e.length; o++)
          if (null === t[o]) {
            var r;
            const i =
              null === (r = s[o]) || void 0 === r ? void 0 : r.apply(e[o], n);
            if (i === $e) t[o] = $e;
            else if (void 0 !== i && !1 !== i) return i;
          } else t[o] === i && (t[o] = null);
      },
    };
    n[i] = a;
  }
  return n;
}
function Le(e, t) {
  const n = e[t];
  return "object" == typeof n
    ? n
    : "function" == typeof n
    ? { enter: n, leave: void 0 }
    : { enter: e.enter, leave: e.leave };
}
function Fe(e, t, n) {
  const { enter: i, leave: r } = Le(e, t);
  return n ? r : i;
}
function Ce(e) {
  return xe(e, Ve);
}
const Ve = {
  Name: { leave: (e) => e.value },
  Variable: { leave: (e) => "$" + e.name },
  Document: { leave: (e) => Ue(e.definitions, "\n\n") },
  OperationDefinition: {
    leave(e) {
      const t = je("(", Ue(e.variableDefinitions, ", "), ")"),
        n = Ue([e.operation, Ue([e.name, t]), Ue(e.directives, " ")], " ");
      return ("query" === n ? "" : n + " ") + e.selectionSet;
    },
  },
  VariableDefinition: {
    leave: ({ variable: e, type: t, defaultValue: n, directives: i }) =>
      e + ": " + t + je(" = ", n) + je(" ", Ue(i, " ")),
  },
  SelectionSet: { leave: ({ selections: e }) => Me(e) },
  Field: {
    leave({ alias: e, name: t, arguments: n, directives: i, selectionSet: r }) {
      const o = je("", e, ": ") + t;
      let s = o + je("(", Ue(n, ", "), ")");
      return (
        s.length > 80 && (s = o + je("(\n", Pe(Ue(n, "\n")), "\n)")),
        Ue([s, Ue(i, " "), r], " ")
      );
    },
  },
  Argument: { leave: ({ name: e, value: t }) => e + ": " + t },
  FragmentSpread: {
    leave: ({ name: e, directives: t }) => "..." + e + je(" ", Ue(t, " ")),
  },
  InlineFragment: {
    leave: ({ typeCondition: e, directives: t, selectionSet: n }) =>
      Ue(["...", je("on ", e), Ue(t, " "), n], " "),
  },
  FragmentDefinition: {
    leave: ({
      name: e,
      typeCondition: t,
      variableDefinitions: n,
      directives: i,
      selectionSet: r,
    }) =>
      `fragment ${e}${je("(", Ue(n, ", "), ")")} on ${t} ${je(
        "",
        Ue(i, " "),
        " "
      )}` + r,
  },
  IntValue: { leave: ({ value: e }) => e },
  FloatValue: { leave: ({ value: e }) => e },
  StringValue: {
    leave: ({ value: e, block: t }) => (t ? k(e) : `"${e.replace(we, Se)}"`),
  },
  BooleanValue: { leave: ({ value: e }) => (e ? "true" : "false") },
  NullValue: { leave: () => "null" },
  EnumValue: { leave: ({ value: e }) => e },
  ListValue: { leave: ({ values: e }) => "[" + Ue(e, ", ") + "]" },
  ObjectValue: { leave: ({ fields: e }) => "{" + Ue(e, ", ") + "}" },
  ObjectField: { leave: ({ name: e, value: t }) => e + ": " + t },
  Directive: {
    leave: ({ name: e, arguments: t }) => "@" + e + je("(", Ue(t, ", "), ")"),
  },
  NamedType: { leave: ({ name: e }) => e },
  ListType: { leave: ({ type: e }) => "[" + e + "]" },
  NonNullType: { leave: ({ type: e }) => e + "!" },
  SchemaDefinition: {
    leave: ({ description: e, directives: t, operationTypes: n }) =>
      je("", e, "\n") + Ue(["schema", Ue(t, " "), Me(n)], " "),
  },
  OperationTypeDefinition: {
    leave: ({ operation: e, type: t }) => e + ": " + t,
  },
  ScalarTypeDefinition: {
    leave: ({ description: e, name: t, directives: n }) =>
      je("", e, "\n") + Ue(["scalar", t, Ue(n, " ")], " "),
  },
  ObjectTypeDefinition: {
    leave: ({
      description: e,
      name: t,
      interfaces: n,
      directives: i,
      fields: r,
    }) =>
      je("", e, "\n") +
      Ue(["type", t, je("implements ", Ue(n, " & ")), Ue(i, " "), Me(r)], " "),
  },
  FieldDefinition: {
    leave: ({
      description: e,
      name: t,
      arguments: n,
      type: i,
      directives: r,
    }) =>
      je("", e, "\n") +
      t +
      (Be(n) ? je("(\n", Pe(Ue(n, "\n")), "\n)") : je("(", Ue(n, ", "), ")")) +
      ": " +
      i +
      je(" ", Ue(r, " ")),
  },
  InputValueDefinition: {
    leave: ({
      description: e,
      name: t,
      type: n,
      defaultValue: i,
      directives: r,
    }) => je("", e, "\n") + Ue([t + ": " + n, je("= ", i), Ue(r, " ")], " "),
  },
  InterfaceTypeDefinition: {
    leave: ({
      description: e,
      name: t,
      interfaces: n,
      directives: i,
      fields: r,
    }) =>
      je("", e, "\n") +
      Ue(
        ["interface", t, je("implements ", Ue(n, " & ")), Ue(i, " "), Me(r)],
        " "
      ),
  },
  UnionTypeDefinition: {
    leave: ({ description: e, name: t, directives: n, types: i }) =>
      je("", e, "\n") +
      Ue(["union", t, Ue(n, " "), je("= ", Ue(i, " | "))], " "),
  },
  EnumTypeDefinition: {
    leave: ({ description: e, name: t, directives: n, values: i }) =>
      je("", e, "\n") + Ue(["enum", t, Ue(n, " "), Me(i)], " "),
  },
  EnumValueDefinition: {
    leave: ({ description: e, name: t, directives: n }) =>
      je("", e, "\n") + Ue([t, Ue(n, " ")], " "),
  },
  InputObjectTypeDefinition: {
    leave: ({ description: e, name: t, directives: n, fields: i }) =>
      je("", e, "\n") + Ue(["input", t, Ue(n, " "), Me(i)], " "),
  },
  DirectiveDefinition: {
    leave: ({
      description: e,
      name: t,
      arguments: n,
      repeatable: i,
      locations: r,
    }) =>
      je("", e, "\n") +
      "directive @" +
      t +
      (Be(n) ? je("(\n", Pe(Ue(n, "\n")), "\n)") : je("(", Ue(n, ", "), ")")) +
      (i ? " repeatable" : "") +
      " on " +
      Ue(r, " | "),
  },
  SchemaExtension: {
    leave: ({ directives: e, operationTypes: t }) =>
      Ue(["extend schema", Ue(e, " "), Me(t)], " "),
  },
  ScalarTypeExtension: {
    leave: ({ name: e, directives: t }) =>
      Ue(["extend scalar", e, Ue(t, " ")], " "),
  },
  ObjectTypeExtension: {
    leave: ({ name: e, interfaces: t, directives: n, fields: i }) =>
      Ue(
        ["extend type", e, je("implements ", Ue(t, " & ")), Ue(n, " "), Me(i)],
        " "
      ),
  },
  InterfaceTypeExtension: {
    leave: ({ name: e, interfaces: t, directives: n, fields: i }) =>
      Ue(
        [
          "extend interface",
          e,
          je("implements ", Ue(t, " & ")),
          Ue(n, " "),
          Me(i),
        ],
        " "
      ),
  },
  UnionTypeExtension: {
    leave: ({ name: e, directives: t, types: n }) =>
      Ue(["extend union", e, Ue(t, " "), je("= ", Ue(n, " | "))], " "),
  },
  EnumTypeExtension: {
    leave: ({ name: e, directives: t, values: n }) =>
      Ue(["extend enum", e, Ue(t, " "), Me(n)], " "),
  },
  InputObjectTypeExtension: {
    leave: ({ name: e, directives: t, fields: n }) =>
      Ue(["extend input", e, Ue(t, " "), Me(n)], " "),
  },
};
function Ue(e, t = "") {
  var n;
  return null !== (n = null == e ? void 0 : e.filter((e) => e).join(t)) &&
    void 0 !== n
    ? n
    : "";
}
function Me(e) {
  return je("{\n", Pe(Ue(e, "\n")), "\n}");
}
function je(e, t, n = "") {
  return null != t && "" !== t ? e + t + n : "";
}
function Pe(e) {
  return je("  ", e.replace(/\n/g, "\n  "));
}
function Be(e) {
  var t;
  return (
    null !== (t = null == e ? void 0 : e.some((e) => e.includes("\n"))) &&
    void 0 !== t &&
    t
  );
}
function Ge(e, t) {
  switch (e.kind) {
    case _.NULL:
      return null;
    case _.INT:
      return parseInt(e.value, 10);
    case _.FLOAT:
      return parseFloat(e.value);
    case _.STRING:
    case _.ENUM:
    case _.BOOLEAN:
      return e.value;
    case _.LIST:
      return e.values.map((e) => Ge(e, t));
    case _.OBJECT:
      return ve(
        e.fields,
        (e) => e.name.value,
        (e) => Ge(e.value, t)
      );
    case _.VARIABLE:
      return null == t ? void 0 : t[e.name.value];
  }
}
function Ye(e) {
  if (
    (null != e || n(!1, "Must provide name."),
    "string" == typeof e || n(!1, "Expected name to be a string."),
    0 === e.length)
  )
    throw new p("Expected name to be a non-empty string.");
  for (let t = 1; t < e.length; ++t)
    if (!S(e.charCodeAt(t)))
      throw new p(`Names must only contain [_a-zA-Z0-9] but "${e}" does not.`);
  if (!w(e.charCodeAt(0)))
    throw new p(`Names must start with [_a-zA-Z] but "${e}" does not.`);
  return e;
}
function Qe(e) {
  if ("true" === e || "false" === e || "null" === e)
    throw new p(`Enum values cannot be named: ${e}`);
  return Ye(e);
}
function Je(e) {
  return Ke(e) || ze(e) || We(e) || et(e) || nt(e) || rt(e) || st(e) || ct(e);
}
function qe(e) {
  if (!Je(e)) throw new Error(`Expected ${ne(e)} to be a GraphQL type.`);
  return e;
}
function Ke(e) {
  return re(e, xt);
}
function Xe(e) {
  if (!Ke(e)) throw new Error(`Expected ${ne(e)} to be a GraphQL Scalar type.`);
  return e;
}
function ze(e) {
  return re(e, kt);
}
function He(e) {
  if (!ze(e)) throw new Error(`Expected ${ne(e)} to be a GraphQL Object type.`);
  return e;
}
function We(e) {
  return re(e, Pt);
}
function Ze(e) {
  if (!We(e))
    throw new Error(`Expected ${ne(e)} to be a GraphQL Interface type.`);
  return e;
}
function et(e) {
  return re(e, Bt);
}
function tt(e) {
  if (!et(e)) throw new Error(`Expected ${ne(e)} to be a GraphQL Union type.`);
  return e;
}
function nt(e) {
  return re(e, Yt);
}
function it(e) {
  if (!nt(e)) throw new Error(`Expected ${ne(e)} to be a GraphQL Enum type.`);
  return e;
}
function rt(e) {
  return re(e, Jt);
}
function ot(e) {
  if (!rt(e))
    throw new Error(`Expected ${ne(e)} to be a GraphQL Input Object type.`);
  return e;
}
function st(e) {
  return re(e, Nt);
}
function at(e) {
  if (!st(e)) throw new Error(`Expected ${ne(e)} to be a GraphQL List type.`);
  return e;
}
function ct(e) {
  return re(e, It);
}
function ut(e) {
  if (!ct(e))
    throw new Error(`Expected ${ne(e)} to be a GraphQL Non-Null type.`);
  return e;
}
function lt(e) {
  return Ke(e) || nt(e) || rt(e) || (gt(e) && lt(e.ofType));
}
function pt(e) {
  if (!lt(e)) throw new Error(`Expected ${ne(e)} to be a GraphQL input type.`);
  return e;
}
function dt(e) {
  return Ke(e) || ze(e) || We(e) || et(e) || nt(e) || (gt(e) && dt(e.ofType));
}
function ft(e) {
  if (!dt(e)) throw new Error(`Expected ${ne(e)} to be a GraphQL output type.`);
  return e;
}
function ht(e) {
  return Ke(e) || nt(e);
}
function mt(e) {
  if (!ht(e)) throw new Error(`Expected ${ne(e)} to be a GraphQL leaf type.`);
  return e;
}
function yt(e) {
  return ze(e) || We(e) || et(e);
}
function Et(e) {
  if (!yt(e))
    throw new Error(`Expected ${ne(e)} to be a GraphQL composite type.`);
  return e;
}
function vt(e) {
  return We(e) || et(e);
}
function Tt(e) {
  if (!vt(e))
    throw new Error(`Expected ${ne(e)} to be a GraphQL abstract type.`);
  return e;
}
class Nt {
  constructor(e) {
    Je(e) || n(!1, `Expected ${ne(e)} to be a GraphQL type.`),
      (this.ofType = e);
  }
  get [Symbol.toStringTag]() {
    return "GraphQLList";
  }
  toString() {
    return "[" + String(this.ofType) + "]";
  }
  toJSON() {
    return this.toString();
  }
}
class It {
  constructor(e) {
    bt(e) || n(!1, `Expected ${ne(e)} to be a GraphQL nullable type.`),
      (this.ofType = e);
  }
  get [Symbol.toStringTag]() {
    return "GraphQLNonNull";
  }
  toString() {
    return String(this.ofType) + "!";
  }
  toJSON() {
    return this.toString();
  }
}
function gt(e) {
  return st(e) || ct(e);
}
function _t(e) {
  if (!gt(e))
    throw new Error(`Expected ${ne(e)} to be a GraphQL wrapping type.`);
  return e;
}
function bt(e) {
  return Je(e) && !ct(e);
}
function Ot(e) {
  if (!bt(e))
    throw new Error(`Expected ${ne(e)} to be a GraphQL nullable type.`);
  return e;
}
function Dt(e) {
  if (e) return ct(e) ? e.ofType : e;
}
function At(e) {
  return Ke(e) || ze(e) || We(e) || et(e) || nt(e) || rt(e);
}
function wt(e) {
  if (!At(e)) throw new Error(`Expected ${ne(e)} to be a GraphQL named type.`);
  return e;
}
function St(e) {
  if (e) {
    let t = e;
    for (; gt(t); ) t = t.ofType;
    return t;
  }
}
function Rt(e) {
  return "function" == typeof e ? e() : e;
}
function $t(e) {
  return "function" == typeof e ? e() : e;
}
class xt {
  constructor(e) {
    var t, i, r, o;
    const s = null !== (t = e.parseValue) && void 0 !== t ? t : ye;
    (this.name = Ye(e.name)),
      (this.description = e.description),
      (this.specifiedByURL = e.specifiedByURL),
      (this.serialize = null !== (i = e.serialize) && void 0 !== i ? i : ye),
      (this.parseValue = s),
      (this.parseLiteral =
        null !== (r = e.parseLiteral) && void 0 !== r
          ? r
          : (e, t) => s(Ge(e, t))),
      (this.extensions = Ae(e.extensions)),
      (this.astNode = e.astNode),
      (this.extensionASTNodes =
        null !== (o = e.extensionASTNodes) && void 0 !== o ? o : []),
      null == e.specifiedByURL ||
        "string" == typeof e.specifiedByURL ||
        n(
          !1,
          `${
            this.name
          } must provide "specifiedByURL" as a string, but got: ${ne(
            e.specifiedByURL
          )}.`
        ),
      null == e.serialize ||
        "function" == typeof e.serialize ||
        n(
          !1,
          `${this.name} must provide "serialize" function. If this custom Scalar is also used as an input type, ensure "parseValue" and "parseLiteral" functions are also provided.`
        ),
      e.parseLiteral &&
        (("function" == typeof e.parseValue &&
          "function" == typeof e.parseLiteral) ||
          n(
            !1,
            `${this.name} must provide both "parseValue" and "parseLiteral" functions.`
          ));
  }
  get [Symbol.toStringTag]() {
    return "GraphQLScalarType";
  }
  toConfig() {
    return {
      name: this.name,
      description: this.description,
      specifiedByURL: this.specifiedByURL,
      serialize: this.serialize,
      parseValue: this.parseValue,
      parseLiteral: this.parseLiteral,
      extensions: this.extensions,
      astNode: this.astNode,
      extensionASTNodes: this.extensionASTNodes,
    };
  }
  toString() {
    return this.name;
  }
  toJSON() {
    return this.toString();
  }
}
class kt {
  constructor(e) {
    var t;
    (this.name = Ye(e.name)),
      (this.description = e.description),
      (this.isTypeOf = e.isTypeOf),
      (this.extensions = Ae(e.extensions)),
      (this.astNode = e.astNode),
      (this.extensionASTNodes =
        null !== (t = e.extensionASTNodes) && void 0 !== t ? t : []),
      (this._fields = () => Ft(e)),
      (this._interfaces = () => Lt(e)),
      null == e.isTypeOf ||
        "function" == typeof e.isTypeOf ||
        n(
          !1,
          `${this.name} must provide "isTypeOf" as a function, but got: ${ne(
            e.isTypeOf
          )}.`
        );
  }
  get [Symbol.toStringTag]() {
    return "GraphQLObjectType";
  }
  getFields() {
    return (
      "function" == typeof this._fields && (this._fields = this._fields()),
      this._fields
    );
  }
  getInterfaces() {
    return (
      "function" == typeof this._interfaces &&
        (this._interfaces = this._interfaces()),
      this._interfaces
    );
  }
  toConfig() {
    return {
      name: this.name,
      description: this.description,
      interfaces: this.getInterfaces(),
      fields: Ut(this.getFields()),
      isTypeOf: this.isTypeOf,
      extensions: this.extensions,
      astNode: this.astNode,
      extensionASTNodes: this.extensionASTNodes,
    };
  }
  toString() {
    return this.name;
  }
  toJSON() {
    return this.toString();
  }
}
function Lt(e) {
  var t;
  const i = Rt(null !== (t = e.interfaces) && void 0 !== t ? t : []);
  return (
    Array.isArray(i) ||
      n(
        !1,
        `${e.name} interfaces must be an Array or a function which returns an Array.`
      ),
    i
  );
}
function Ft(e) {
  const t = $t(e.fields);
  return (
    Vt(t) ||
      n(
        !1,
        `${e.name} fields must be an object with field names as keys or a function which returns such an object.`
      ),
    Te(t, (t, i) => {
      var r;
      Vt(t) || n(!1, `${e.name}.${i} field config must be an object.`),
        null == t.resolve ||
          "function" == typeof t.resolve ||
          n(
            !1,
            `${
              e.name
            }.${i} field resolver must be a function if provided, but got: ${ne(
              t.resolve
            )}.`
          );
      const o = null !== (r = t.args) && void 0 !== r ? r : {};
      return (
        Vt(o) ||
          n(
            !1,
            `${e.name}.${i} args must be an object with argument names as keys.`
          ),
        {
          name: Ye(i),
          description: t.description,
          type: t.type,
          args: Ct(o),
          resolve: t.resolve,
          subscribe: t.subscribe,
          deprecationReason: t.deprecationReason,
          extensions: Ae(t.extensions),
          astNode: t.astNode,
        }
      );
    })
  );
}
function Ct(e) {
  return Object.entries(e).map(([e, t]) => ({
    name: Ye(e),
    description: t.description,
    type: t.type,
    defaultValue: t.defaultValue,
    deprecationReason: t.deprecationReason,
    extensions: Ae(t.extensions),
    astNode: t.astNode,
  }));
}
function Vt(e) {
  return r(e) && !Array.isArray(e);
}
function Ut(e) {
  return Te(e, (e) => ({
    description: e.description,
    type: e.type,
    args: Mt(e.args),
    resolve: e.resolve,
    subscribe: e.subscribe,
    deprecationReason: e.deprecationReason,
    extensions: e.extensions,
    astNode: e.astNode,
  }));
}
function Mt(e) {
  return ve(
    e,
    (e) => e.name,
    (e) => ({
      description: e.description,
      type: e.type,
      defaultValue: e.defaultValue,
      deprecationReason: e.deprecationReason,
      extensions: e.extensions,
      astNode: e.astNode,
    })
  );
}
function jt(e) {
  return ct(e.type) && void 0 === e.defaultValue;
}
class Pt {
  constructor(e) {
    var t;
    (this.name = Ye(e.name)),
      (this.description = e.description),
      (this.resolveType = e.resolveType),
      (this.extensions = Ae(e.extensions)),
      (this.astNode = e.astNode),
      (this.extensionASTNodes =
        null !== (t = e.extensionASTNodes) && void 0 !== t ? t : []),
      (this._fields = Ft.bind(void 0, e)),
      (this._interfaces = Lt.bind(void 0, e)),
      null == e.resolveType ||
        "function" == typeof e.resolveType ||
        n(
          !1,
          `${this.name} must provide "resolveType" as a function, but got: ${ne(
            e.resolveType
          )}.`
        );
  }
  get [Symbol.toStringTag]() {
    return "GraphQLInterfaceType";
  }
  getFields() {
    return (
      "function" == typeof this._fields && (this._fields = this._fields()),
      this._fields
    );
  }
  getInterfaces() {
    return (
      "function" == typeof this._interfaces &&
        (this._interfaces = this._interfaces()),
      this._interfaces
    );
  }
  toConfig() {
    return {
      name: this.name,
      description: this.description,
      interfaces: this.getInterfaces(),
      fields: Ut(this.getFields()),
      resolveType: this.resolveType,
      extensions: this.extensions,
      astNode: this.astNode,
      extensionASTNodes: this.extensionASTNodes,
    };
  }
  toString() {
    return this.name;
  }
  toJSON() {
    return this.toString();
  }
}
class Bt {
  constructor(e) {
    var t;
    (this.name = Ye(e.name)),
      (this.description = e.description),
      (this.resolveType = e.resolveType),
      (this.extensions = Ae(e.extensions)),
      (this.astNode = e.astNode),
      (this.extensionASTNodes =
        null !== (t = e.extensionASTNodes) && void 0 !== t ? t : []),
      (this._types = Gt.bind(void 0, e)),
      null == e.resolveType ||
        "function" == typeof e.resolveType ||
        n(
          !1,
          `${this.name} must provide "resolveType" as a function, but got: ${ne(
            e.resolveType
          )}.`
        );
  }
  get [Symbol.toStringTag]() {
    return "GraphQLUnionType";
  }
  getTypes() {
    return (
      "function" == typeof this._types && (this._types = this._types()),
      this._types
    );
  }
  toConfig() {
    return {
      name: this.name,
      description: this.description,
      types: this.getTypes(),
      resolveType: this.resolveType,
      extensions: this.extensions,
      astNode: this.astNode,
      extensionASTNodes: this.extensionASTNodes,
    };
  }
  toString() {
    return this.name;
  }
  toJSON() {
    return this.toString();
  }
}
function Gt(e) {
  const t = Rt(e.types);
  return (
    Array.isArray(t) ||
      n(
        !1,
        `Must provide Array of types or a function which returns such an array for Union ${e.name}.`
      ),
    t
  );
}
class Yt {
  constructor(e) {
    var t, i, r;
    (this.name = Ye(e.name)),
      (this.description = e.description),
      (this.extensions = Ae(e.extensions)),
      (this.astNode = e.astNode),
      (this.extensionASTNodes =
        null !== (t = e.extensionASTNodes) && void 0 !== t ? t : []),
      (this._values =
        ((i = this.name),
        Vt((r = e.values)) ||
          n(!1, `${i} values must be an object with value names as keys.`),
        Object.entries(r).map(
          ([e, t]) => (
            Vt(t) ||
              n(
                !1,
                `${i}.${e} must refer to an object with a "value" key representing an internal value but got: ${ne(
                  t
                )}.`
              ),
            {
              name: Qe(e),
              description: t.description,
              value: void 0 !== t.value ? t.value : e,
              deprecationReason: t.deprecationReason,
              extensions: Ae(t.extensions),
              astNode: t.astNode,
            }
          )
        ))),
      (this._valueLookup = new Map(this._values.map((e) => [e.value, e]))),
      (this._nameLookup = Ee(this._values, (e) => e.name));
  }
  get [Symbol.toStringTag]() {
    return "GraphQLEnumType";
  }
  getValues() {
    return this._values;
  }
  getValue(e) {
    return this._nameLookup[e];
  }
  serialize(e) {
    const t = this._valueLookup.get(e);
    if (void 0 === t)
      throw new p(`Enum "${this.name}" cannot represent value: ${ne(e)}`);
    return t.name;
  }
  parseValue(e) {
    if ("string" != typeof e) {
      const t = ne(e);
      throw new p(
        `Enum "${this.name}" cannot represent non-string value: ${t}.` +
          Qt(this, t)
      );
    }
    const t = this.getValue(e);
    if (null == t)
      throw new p(
        `Value "${e}" does not exist in "${this.name}" enum.` + Qt(this, e)
      );
    return t.value;
  }
  parseLiteral(e, t) {
    if (e.kind !== _.ENUM) {
      const t = Ce(e);
      throw new p(
        `Enum "${this.name}" cannot represent non-enum value: ${t}.` +
          Qt(this, t),
        { nodes: e }
      );
    }
    const n = this.getValue(e.value);
    if (null == n) {
      const t = Ce(e);
      throw new p(
        `Value "${t}" does not exist in "${this.name}" enum.` + Qt(this, t),
        { nodes: e }
      );
    }
    return n.value;
  }
  toConfig() {
    const e = ve(
      this.getValues(),
      (e) => e.name,
      (e) => ({
        description: e.description,
        value: e.value,
        deprecationReason: e.deprecationReason,
        extensions: e.extensions,
        astNode: e.astNode,
      })
    );
    return {
      name: this.name,
      description: this.description,
      values: e,
      extensions: this.extensions,
      astNode: this.astNode,
      extensionASTNodes: this.extensionASTNodes,
    };
  }
  toString() {
    return this.name;
  }
  toJSON() {
    return this.toString();
  }
}
function Qt(e, t) {
  return me(
    "the enum value",
    be(
      t,
      e.getValues().map((e) => e.name)
    )
  );
}
class Jt {
  constructor(e) {
    var t;
    (this.name = Ye(e.name)),
      (this.description = e.description),
      (this.extensions = Ae(e.extensions)),
      (this.astNode = e.astNode),
      (this.extensionASTNodes =
        null !== (t = e.extensionASTNodes) && void 0 !== t ? t : []),
      (this._fields = qt.bind(void 0, e));
  }
  get [Symbol.toStringTag]() {
    return "GraphQLInputObjectType";
  }
  getFields() {
    return (
      "function" == typeof this._fields && (this._fields = this._fields()),
      this._fields
    );
  }
  toConfig() {
    const e = Te(this.getFields(), (e) => ({
      description: e.description,
      type: e.type,
      defaultValue: e.defaultValue,
      deprecationReason: e.deprecationReason,
      extensions: e.extensions,
      astNode: e.astNode,
    }));
    return {
      name: this.name,
      description: this.description,
      fields: e,
      extensions: this.extensions,
      astNode: this.astNode,
      extensionASTNodes: this.extensionASTNodes,
    };
  }
  toString() {
    return this.name;
  }
  toJSON() {
    return this.toString();
  }
}
function qt(e) {
  const t = $t(e.fields);
  return (
    Vt(t) ||
      n(
        !1,
        `${e.name} fields must be an object with field names as keys or a function which returns such an object.`
      ),
    Te(
      t,
      (t, i) => (
        !("resolve" in t) ||
          n(
            !1,
            `${e.name}.${i} field has a resolve property, but Input Types cannot define resolvers.`
          ),
        {
          name: Ye(i),
          description: t.description,
          type: t.type,
          defaultValue: t.defaultValue,
          deprecationReason: t.deprecationReason,
          extensions: Ae(t.extensions),
          astNode: t.astNode,
        }
      )
    )
  );
}
function Kt(e) {
  return ct(e.type) && void 0 === e.defaultValue;
}
function Xt(e, t) {
  return (
    e === t ||
    (((ct(e) && ct(t)) || !(!st(e) || !st(t))) && Xt(e.ofType, t.ofType))
  );
}
function zt(e, t, n) {
  return (
    t === n ||
    (ct(n)
      ? !!ct(t) && zt(e, t.ofType, n.ofType)
      : ct(t)
      ? zt(e, t.ofType, n)
      : st(n)
      ? !!st(t) && zt(e, t.ofType, n.ofType)
      : !st(t) && vt(n) && (We(t) || ze(t)) && e.isSubType(n, t))
  );
}
function Ht(e, t, n) {
  return (
    t === n ||
    (vt(t)
      ? vt(n)
        ? e.getPossibleTypes(t).some((t) => e.isSubType(n, t))
        : e.isSubType(t, n)
      : !!vt(n) && e.isSubType(n, t))
  );
}
const Wt = 2147483647,
  Zt = -2147483648,
  en = new xt({
    name: "Int",
    description:
      "The `Int` scalar type represents non-fractional signed whole numeric values. Int can represent values between -(2^31) and 2^31 - 1.",
    serialize(e) {
      const t = cn(e);
      if ("boolean" == typeof t) return t ? 1 : 0;
      let n = t;
      if (
        ("string" == typeof t && "" !== t && (n = Number(t)),
        "number" != typeof n || !Number.isInteger(n))
      )
        throw new p(`Int cannot represent non-integer value: ${ne(t)}`);
      if (n > Wt || n < Zt)
        throw new p(
          "Int cannot represent non 32-bit signed integer value: " + ne(t)
        );
      return n;
    },
    parseValue(e) {
      if ("number" != typeof e || !Number.isInteger(e))
        throw new p(`Int cannot represent non-integer value: ${ne(e)}`);
      if (e > Wt || e < Zt)
        throw new p(
          `Int cannot represent non 32-bit signed integer value: ${e}`
        );
      return e;
    },
    parseLiteral(e) {
      if (e.kind !== _.INT)
        throw new p(`Int cannot represent non-integer value: ${Ce(e)}`, {
          nodes: e,
        });
      const t = parseInt(e.value, 10);
      if (t > Wt || t < Zt)
        throw new p(
          `Int cannot represent non 32-bit signed integer value: ${e.value}`,
          { nodes: e }
        );
      return t;
    },
  }),
  tn = new xt({
    name: "Float",
    description:
      "The `Float` scalar type represents signed double-precision fractional values as specified by [IEEE 754](https://en.wikipedia.org/wiki/IEEE_floating_point).",
    serialize(e) {
      const t = cn(e);
      if ("boolean" == typeof t) return t ? 1 : 0;
      let n = t;
      if (
        ("string" == typeof t && "" !== t && (n = Number(t)),
        "number" != typeof n || !Number.isFinite(n))
      )
        throw new p(`Float cannot represent non numeric value: ${ne(t)}`);
      return n;
    },
    parseValue(e) {
      if ("number" != typeof e || !Number.isFinite(e))
        throw new p(`Float cannot represent non numeric value: ${ne(e)}`);
      return e;
    },
    parseLiteral(e) {
      if (e.kind !== _.FLOAT && e.kind !== _.INT)
        throw new p(`Float cannot represent non numeric value: ${Ce(e)}`, e);
      return parseFloat(e.value);
    },
  }),
  nn = new xt({
    name: "String",
    description:
      "The `String` scalar type represents textual data, represented as UTF-8 character sequences. The String type is most often used by GraphQL to represent free-form human-readable text.",
    serialize(e) {
      const t = cn(e);
      if ("string" == typeof t) return t;
      if ("boolean" == typeof t) return t ? "true" : "false";
      if ("number" == typeof t && Number.isFinite(t)) return t.toString();
      throw new p(`String cannot represent value: ${ne(e)}`);
    },
    parseValue(e) {
      if ("string" != typeof e)
        throw new p(`String cannot represent a non string value: ${ne(e)}`);
      return e;
    },
    parseLiteral(e) {
      if (e.kind !== _.STRING)
        throw new p(`String cannot represent a non string value: ${Ce(e)}`, {
          nodes: e,
        });
      return e.value;
    },
  }),
  rn = new xt({
    name: "Boolean",
    description: "The `Boolean` scalar type represents `true` or `false`.",
    serialize(e) {
      const t = cn(e);
      if ("boolean" == typeof t) return t;
      if (Number.isFinite(t)) return 0 !== t;
      throw new p(`Boolean cannot represent a non boolean value: ${ne(t)}`);
    },
    parseValue(e) {
      if ("boolean" != typeof e)
        throw new p(`Boolean cannot represent a non boolean value: ${ne(e)}`);
      return e;
    },
    parseLiteral(e) {
      if (e.kind !== _.BOOLEAN)
        throw new p(`Boolean cannot represent a non boolean value: ${Ce(e)}`, {
          nodes: e,
        });
      return e.value;
    },
  }),
  on = new xt({
    name: "ID",
    description:
      'The `ID` scalar type represents a unique identifier, often used to refetch an object or as key for a cache. The ID type appears in a JSON response as a String; however, it is not intended to be human-readable. When expected as an input type, any string (such as `"4"`) or integer (such as `4`) input value will be accepted as an ID.',
    serialize(e) {
      const t = cn(e);
      if ("string" == typeof t) return t;
      if (Number.isInteger(t)) return String(t);
      throw new p(`ID cannot represent value: ${ne(e)}`);
    },
    parseValue(e) {
      if ("string" == typeof e) return e;
      if ("number" == typeof e && Number.isInteger(e)) return e.toString();
      throw new p(`ID cannot represent value: ${ne(e)}`);
    },
    parseLiteral(e) {
      if (e.kind !== _.STRING && e.kind !== _.INT)
        throw new p(
          "ID cannot represent a non-string and non-integer value: " + Ce(e),
          { nodes: e }
        );
      return e.value;
    },
  }),
  sn = Object.freeze([nn, en, tn, rn, on]);
function an(e) {
  return sn.some(({ name: t }) => e.name === t);
}
function cn(e) {
  if (r(e)) {
    if ("function" == typeof e.valueOf) {
      const t = e.valueOf();
      if (!r(t)) return t;
    }
    if ("function" == typeof e.toJSON) return e.toJSON();
  }
  return e;
}
function un(e) {
  return re(e, pn);
}
function ln(e) {
  if (!un(e)) throw new Error(`Expected ${ne(e)} to be a GraphQL directive.`);
  return e;
}
class pn {
  constructor(e) {
    var t, i;
    (this.name = Ye(e.name)),
      (this.description = e.description),
      (this.locations = e.locations),
      (this.isRepeatable = null !== (t = e.isRepeatable) && void 0 !== t && t),
      (this.extensions = Ae(e.extensions)),
      (this.astNode = e.astNode),
      Array.isArray(e.locations) ||
        n(!1, `@${e.name} locations must be an Array.`);
    const o = null !== (i = e.args) && void 0 !== i ? i : {};
    (r(o) && !Array.isArray(o)) ||
      n(!1, `@${e.name} args must be an object with argument names as keys.`),
      (this.args = Ct(o));
  }
  get [Symbol.toStringTag]() {
    return "GraphQLDirective";
  }
  toConfig() {
    return {
      name: this.name,
      description: this.description,
      locations: this.locations,
      args: Mt(this.args),
      isRepeatable: this.isRepeatable,
      extensions: this.extensions,
      astNode: this.astNode,
    };
  }
  toString() {
    return "@" + this.name;
  }
  toJSON() {
    return this.toString();
  }
}
const dn = new pn({
    name: "include",
    description:
      "Directs the executor to include this field or fragment only when the `if` argument is true.",
    locations: [g.FIELD, g.FRAGMENT_SPREAD, g.INLINE_FRAGMENT],
    args: { if: { type: new It(rn), description: "Included when true." } },
  }),
  fn = new pn({
    name: "skip",
    description:
      "Directs the executor to skip this field or fragment when the `if` argument is true.",
    locations: [g.FIELD, g.FRAGMENT_SPREAD, g.INLINE_FRAGMENT],
    args: { if: { type: new It(rn), description: "Skipped when true." } },
  }),
  hn = "No longer supported",
  mn = new pn({
    name: "deprecated",
    description: "Marks an element of a GraphQL schema as no longer supported.",
    locations: [
      g.FIELD_DEFINITION,
      g.ARGUMENT_DEFINITION,
      g.INPUT_FIELD_DEFINITION,
      g.ENUM_VALUE,
    ],
    args: {
      reason: {
        type: nn,
        description:
          "Explains why this element was deprecated, usually also including a suggestion for how to access supported similar data. Formatted using the Markdown syntax, as specified by [CommonMark](https://commonmark.org/).",
        defaultValue: hn,
      },
    },
  }),
  yn = new pn({
    name: "specifiedBy",
    description: "Exposes a URL that specifies the behavior of this scalar.",
    locations: [g.SCALAR],
    args: {
      url: {
        type: new It(nn),
        description: "The URL that specifies the behavior of this scalar.",
      },
    },
  }),
  En = Object.freeze([dn, fn, mn, yn]);
function vn(e) {
  return En.some(({ name: t }) => t === e.name);
}
function Tn(e) {
  return (
    "object" == typeof e &&
    "function" == typeof (null == e ? void 0 : e[Symbol.iterator])
  );
}
function Nn(e, t) {
  if (ct(t)) {
    const n = Nn(e, t.ofType);
    return (null == n ? void 0 : n.kind) === _.NULL ? null : n;
  }
  if (null === e) return { kind: _.NULL };
  if (void 0 === e) return null;
  if (st(t)) {
    const n = t.ofType;
    if (Tn(e)) {
      const t = [];
      for (const i of e) {
        const e = Nn(i, n);
        null != e && t.push(e);
      }
      return { kind: _.LIST, values: t };
    }
    return Nn(e, n);
  }
  if (rt(t)) {
    if (!r(e)) return null;
    const n = [];
    for (const i of Object.values(t.getFields())) {
      const t = Nn(e[i.name], i.type);
      t &&
        n.push({
          kind: _.OBJECT_FIELD,
          name: { kind: _.NAME, value: i.name },
          value: t,
        });
    }
    return { kind: _.OBJECT, fields: n };
  }
  if (ht(t)) {
    const n = t.serialize(e);
    if (null == n) return null;
    if ("boolean" == typeof n) return { kind: _.BOOLEAN, value: n };
    if ("number" == typeof n && Number.isFinite(n)) {
      const e = String(n);
      return In.test(e)
        ? { kind: _.INT, value: e }
        : { kind: _.FLOAT, value: e };
    }
    if ("string" == typeof n)
      return nt(t)
        ? { kind: _.ENUM, value: n }
        : t === on && In.test(n)
        ? { kind: _.INT, value: n }
        : { kind: _.STRING, value: n };
    throw new TypeError(`Cannot convert value to AST: ${ne(n)}.`);
  }
  o(!1, "Unexpected input type: " + ne(t));
}
const In = /^-?(?:0|[1-9][0-9]*)$/,
  gn = new kt({
    name: "__Schema",
    description:
      "A GraphQL Schema defines the capabilities of a GraphQL server. It exposes all available types and directives on the server, as well as the entry points for query, mutation, and subscription operations.",
    fields: () => ({
      description: { type: nn, resolve: (e) => e.description },
      types: {
        description: "A list of all types supported by this server.",
        type: new It(new Nt(new It(On))),
        resolve: (e) => Object.values(e.getTypeMap()),
      },
      queryType: {
        description: "The type that query operations will be rooted at.",
        type: new It(On),
        resolve: (e) => e.getQueryType(),
      },
      mutationType: {
        description:
          "If this server supports mutation, the type that mutation operations will be rooted at.",
        type: On,
        resolve: (e) => e.getMutationType(),
      },
      subscriptionType: {
        description:
          "If this server support subscription, the type that subscription operations will be rooted at.",
        type: On,
        resolve: (e) => e.getSubscriptionType(),
      },
      directives: {
        description: "A list of all directives supported by this server.",
        type: new It(new Nt(new It(_n))),
        resolve: (e) => e.getDirectives(),
      },
    }),
  }),
  _n = new kt({
    name: "__Directive",
    description:
      "A Directive provides a way to describe alternate runtime execution and type validation behavior in a GraphQL document.\n\nIn some cases, you need to provide options to alter GraphQL's execution behavior in ways field arguments will not suffice, such as conditionally including or skipping a field. Directives provide this by describing additional information to the executor.",
    fields: () => ({
      name: { type: new It(nn), resolve: (e) => e.name },
      description: { type: nn, resolve: (e) => e.description },
      isRepeatable: { type: new It(rn), resolve: (e) => e.isRepeatable },
      locations: {
        type: new It(new Nt(new It(bn))),
        resolve: (e) => e.locations,
      },
      args: {
        type: new It(new Nt(new It(An))),
        args: { includeDeprecated: { type: rn, defaultValue: !1 } },
        resolve: (e, { includeDeprecated: t }) =>
          t ? e.args : e.args.filter((e) => null == e.deprecationReason),
      },
    }),
  }),
  bn = new Yt({
    name: "__DirectiveLocation",
    description:
      "A Directive can be adjacent to many parts of the GraphQL language, a __DirectiveLocation describes one such possible adjacencies.",
    values: {
      QUERY: {
        value: g.QUERY,
        description: "Location adjacent to a query operation.",
      },
      MUTATION: {
        value: g.MUTATION,
        description: "Location adjacent to a mutation operation.",
      },
      SUBSCRIPTION: {
        value: g.SUBSCRIPTION,
        description: "Location adjacent to a subscription operation.",
      },
      FIELD: { value: g.FIELD, description: "Location adjacent to a field." },
      FRAGMENT_DEFINITION: {
        value: g.FRAGMENT_DEFINITION,
        description: "Location adjacent to a fragment definition.",
      },
      FRAGMENT_SPREAD: {
        value: g.FRAGMENT_SPREAD,
        description: "Location adjacent to a fragment spread.",
      },
      INLINE_FRAGMENT: {
        value: g.INLINE_FRAGMENT,
        description: "Location adjacent to an inline fragment.",
      },
      VARIABLE_DEFINITION: {
        value: g.VARIABLE_DEFINITION,
        description: "Location adjacent to a variable definition.",
      },
      SCHEMA: {
        value: g.SCHEMA,
        description: "Location adjacent to a schema definition.",
      },
      SCALAR: {
        value: g.SCALAR,
        description: "Location adjacent to a scalar definition.",
      },
      OBJECT: {
        value: g.OBJECT,
        description: "Location adjacent to an object type definition.",
      },
      FIELD_DEFINITION: {
        value: g.FIELD_DEFINITION,
        description: "Location adjacent to a field definition.",
      },
      ARGUMENT_DEFINITION: {
        value: g.ARGUMENT_DEFINITION,
        description: "Location adjacent to an argument definition.",
      },
      INTERFACE: {
        value: g.INTERFACE,
        description: "Location adjacent to an interface definition.",
      },
      UNION: {
        value: g.UNION,
        description: "Location adjacent to a union definition.",
      },
      ENUM: {
        value: g.ENUM,
        description: "Location adjacent to an enum definition.",
      },
      ENUM_VALUE: {
        value: g.ENUM_VALUE,
        description: "Location adjacent to an enum value definition.",
      },
      INPUT_OBJECT: {
        value: g.INPUT_OBJECT,
        description: "Location adjacent to an input object type definition.",
      },
      INPUT_FIELD_DEFINITION: {
        value: g.INPUT_FIELD_DEFINITION,
        description: "Location adjacent to an input object field definition.",
      },
    },
  }),
  On = new kt({
    name: "__Type",
    description:
      "The fundamental unit of any GraphQL Schema is the type. There are many kinds of types in GraphQL as represented by the `__TypeKind` enum.\n\nDepending on the kind of a type, certain fields describe information about that type. Scalar types provide no information beyond a name, description and optional `specifiedByURL`, while Enum types provide their values. Object and Interface types provide the fields they describe. Abstract types, Union and Interface, provide the Object types possible at runtime. List and NonNull types compose other types.",
    fields: () => ({
      kind: {
        type: new It(Rn),
        resolve: (e) =>
          Ke(e)
            ? Sn.SCALAR
            : ze(e)
            ? Sn.OBJECT
            : We(e)
            ? Sn.INTERFACE
            : et(e)
            ? Sn.UNION
            : nt(e)
            ? Sn.ENUM
            : rt(e)
            ? Sn.INPUT_OBJECT
            : st(e)
            ? Sn.LIST
            : ct(e)
            ? Sn.NON_NULL
            : void o(!1, `Unexpected type: "${ne(e)}".`),
      },
      name: { type: nn, resolve: (e) => ("name" in e ? e.name : void 0) },
      description: {
        type: nn,
        resolve: (e) => ("description" in e ? e.description : void 0),
      },
      specifiedByURL: {
        type: nn,
        resolve: (e) => ("specifiedByURL" in e ? e.specifiedByURL : void 0),
      },
      fields: {
        type: new Nt(new It(Dn)),
        args: { includeDeprecated: { type: rn, defaultValue: !1 } },
        resolve(e, { includeDeprecated: t }) {
          if (ze(e) || We(e)) {
            const n = Object.values(e.getFields());
            return t ? n : n.filter((e) => null == e.deprecationReason);
          }
        },
      },
      interfaces: {
        type: new Nt(new It(On)),
        resolve(e) {
          if (ze(e) || We(e)) return e.getInterfaces();
        },
      },
      possibleTypes: {
        type: new Nt(new It(On)),
        resolve(e, t, n, { schema: i }) {
          if (vt(e)) return i.getPossibleTypes(e);
        },
      },
      enumValues: {
        type: new Nt(new It(wn)),
        args: { includeDeprecated: { type: rn, defaultValue: !1 } },
        resolve(e, { includeDeprecated: t }) {
          if (nt(e)) {
            const n = e.getValues();
            return t ? n : n.filter((e) => null == e.deprecationReason);
          }
        },
      },
      inputFields: {
        type: new Nt(new It(An)),
        args: { includeDeprecated: { type: rn, defaultValue: !1 } },
        resolve(e, { includeDeprecated: t }) {
          if (rt(e)) {
            const n = Object.values(e.getFields());
            return t ? n : n.filter((e) => null == e.deprecationReason);
          }
        },
      },
      ofType: { type: On, resolve: (e) => ("ofType" in e ? e.ofType : void 0) },
    }),
  }),
  Dn = new kt({
    name: "__Field",
    description:
      "Object and Interface types are described by a list of Fields, each of which has a name, potentially a list of arguments, and a return type.",
    fields: () => ({
      name: { type: new It(nn), resolve: (e) => e.name },
      description: { type: nn, resolve: (e) => e.description },
      args: {
        type: new It(new Nt(new It(An))),
        args: { includeDeprecated: { type: rn, defaultValue: !1 } },
        resolve: (e, { includeDeprecated: t }) =>
          t ? e.args : e.args.filter((e) => null == e.deprecationReason),
      },
      type: { type: new It(On), resolve: (e) => e.type },
      isDeprecated: {
        type: new It(rn),
        resolve: (e) => null != e.deprecationReason,
      },
      deprecationReason: { type: nn, resolve: (e) => e.deprecationReason },
    }),
  }),
  An = new kt({
    name: "__InputValue",
    description:
      "Arguments provided to Fields or Directives and the input fields of an InputObject are represented as Input Values which describe their type and optionally a default value.",
    fields: () => ({
      name: { type: new It(nn), resolve: (e) => e.name },
      description: { type: nn, resolve: (e) => e.description },
      type: { type: new It(On), resolve: (e) => e.type },
      defaultValue: {
        type: nn,
        description:
          "A GraphQL-formatted string representing the default value for this input value.",
        resolve(e) {
          const { type: t, defaultValue: n } = e,
            i = Nn(n, t);
          return i ? Ce(i) : null;
        },
      },
      isDeprecated: {
        type: new It(rn),
        resolve: (e) => null != e.deprecationReason,
      },
      deprecationReason: { type: nn, resolve: (e) => e.deprecationReason },
    }),
  }),
  wn = new kt({
    name: "__EnumValue",
    description:
      "One possible value for a given Enum. Enum values are unique values, not a placeholder for a string or numeric value. However an Enum value is returned in a JSON response as a string.",
    fields: () => ({
      name: { type: new It(nn), resolve: (e) => e.name },
      description: { type: nn, resolve: (e) => e.description },
      isDeprecated: {
        type: new It(rn),
        resolve: (e) => null != e.deprecationReason,
      },
      deprecationReason: { type: nn, resolve: (e) => e.deprecationReason },
    }),
  });
var Sn;
!(function (e) {
  (e.SCALAR = "SCALAR"),
    (e.OBJECT = "OBJECT"),
    (e.INTERFACE = "INTERFACE"),
    (e.UNION = "UNION"),
    (e.ENUM = "ENUM"),
    (e.INPUT_OBJECT = "INPUT_OBJECT"),
    (e.LIST = "LIST"),
    (e.NON_NULL = "NON_NULL");
})(Sn || (Sn = {}));
const Rn = new Yt({
    name: "__TypeKind",
    description: "An enum describing what kind of type a given `__Type` is.",
    values: {
      SCALAR: {
        value: Sn.SCALAR,
        description: "Indicates this type is a scalar.",
      },
      OBJECT: {
        value: Sn.OBJECT,
        description:
          "Indicates this type is an object. `fields` and `interfaces` are valid fields.",
      },
      INTERFACE: {
        value: Sn.INTERFACE,
        description:
          "Indicates this type is an interface. `fields`, `interfaces`, and `possibleTypes` are valid fields.",
      },
      UNION: {
        value: Sn.UNION,
        description:
          "Indicates this type is a union. `possibleTypes` is a valid field.",
      },
      ENUM: {
        value: Sn.ENUM,
        description:
          "Indicates this type is an enum. `enumValues` is a valid field.",
      },
      INPUT_OBJECT: {
        value: Sn.INPUT_OBJECT,
        description:
          "Indicates this type is an input object. `inputFields` is a valid field.",
      },
      LIST: {
        value: Sn.LIST,
        description:
          "Indicates this type is a list. `ofType` is a valid field.",
      },
      NON_NULL: {
        value: Sn.NON_NULL,
        description:
          "Indicates this type is a non-null. `ofType` is a valid field.",
      },
    },
  }),
  $n = {
    name: "__schema",
    type: new It(gn),
    description: "Access the current type schema of this server.",
    args: [],
    resolve: (e, t, n, { schema: i }) => i,
    deprecationReason: void 0,
    extensions: Object.create(null),
    astNode: void 0,
  },
  xn = {
    name: "__type",
    type: On,
    description: "Request the type information of a single type.",
    args: [
      {
        name: "name",
        description: void 0,
        type: new It(nn),
        defaultValue: void 0,
        deprecationReason: void 0,
        extensions: Object.create(null),
        astNode: void 0,
      },
    ],
    resolve: (e, { name: t }, n, { schema: i }) => i.getType(t),
    deprecationReason: void 0,
    extensions: Object.create(null),
    astNode: void 0,
  },
  kn = {
    name: "__typename",
    type: new It(nn),
    description: "The name of the current Object type at runtime.",
    args: [],
    resolve: (e, t, n, { parentType: i }) => i.name,
    deprecationReason: void 0,
    extensions: Object.create(null),
    astNode: void 0,
  },
  Ln = Object.freeze([gn, _n, bn, On, Dn, An, wn, Rn]);
function Fn(e) {
  return Ln.some(({ name: t }) => e.name === t);
}
function Cn(e) {
  return re(e, Un);
}
function Vn(e) {
  if (!Cn(e)) throw new Error(`Expected ${ne(e)} to be a GraphQL schema.`);
  return e;
}
class Un {
  constructor(e) {
    var t, i;
    (this.__validationErrors = !0 === e.assumeValid ? [] : void 0),
      r(e) || n(!1, "Must provide configuration object."),
      !e.types ||
        Array.isArray(e.types) ||
        n(!1, `"types" must be Array if provided but got: ${ne(e.types)}.`),
      !e.directives ||
        Array.isArray(e.directives) ||
        n(
          !1,
          `"directives" must be Array if provided but got: ${ne(e.directives)}.`
        ),
      (this.description = e.description),
      (this.extensions = Ae(e.extensions)),
      (this.astNode = e.astNode),
      (this.extensionASTNodes =
        null !== (t = e.extensionASTNodes) && void 0 !== t ? t : []),
      (this._queryType = e.query),
      (this._mutationType = e.mutation),
      (this._subscriptionType = e.subscription),
      (this._directives = null !== (i = e.directives) && void 0 !== i ? i : En);
    const o = new Set(e.types);
    if (null != e.types) for (const t of e.types) o.delete(t), Mn(t, o);
    null != this._queryType && Mn(this._queryType, o),
      null != this._mutationType && Mn(this._mutationType, o),
      null != this._subscriptionType && Mn(this._subscriptionType, o);
    for (const e of this._directives)
      if (un(e)) for (const t of e.args) Mn(t.type, o);
    Mn(gn, o),
      (this._typeMap = Object.create(null)),
      (this._subTypeMap = Object.create(null)),
      (this._implementationsMap = Object.create(null));
    for (const e of o) {
      if (null == e) continue;
      const t = e.name;
      if (
        (t ||
          n(
            !1,
            "One of the provided types for building the Schema is missing a name."
          ),
        void 0 !== this._typeMap[t])
      )
        throw new Error(
          `Schema must contain uniquely named types but contains multiple types named "${t}".`
        );
      if (((this._typeMap[t] = e), We(e))) {
        for (const t of e.getInterfaces())
          if (We(t)) {
            let n = this._implementationsMap[t.name];
            void 0 === n &&
              (n = this._implementationsMap[t.name] =
                { objects: [], interfaces: [] }),
              n.interfaces.push(e);
          }
      } else if (ze(e))
        for (const t of e.getInterfaces())
          if (We(t)) {
            let n = this._implementationsMap[t.name];
            void 0 === n &&
              (n = this._implementationsMap[t.name] =
                { objects: [], interfaces: [] }),
              n.objects.push(e);
          }
    }
  }
  get [Symbol.toStringTag]() {
    return "GraphQLSchema";
  }
  getQueryType() {
    return this._queryType;
  }
  getMutationType() {
    return this._mutationType;
  }
  getSubscriptionType() {
    return this._subscriptionType;
  }
  getRootType(e) {
    switch (e) {
      case I.QUERY:
        return this.getQueryType();
      case I.MUTATION:
        return this.getMutationType();
      case I.SUBSCRIPTION:
        return this.getSubscriptionType();
    }
  }
  getTypeMap() {
    return this._typeMap;
  }
  getType(e) {
    return this.getTypeMap()[e];
  }
  getPossibleTypes(e) {
    return et(e) ? e.getTypes() : this.getImplementations(e).objects;
  }
  getImplementations(e) {
    const t = this._implementationsMap[e.name];
    return null != t ? t : { objects: [], interfaces: [] };
  }
  isSubType(e, t) {
    let n = this._subTypeMap[e.name];
    if (void 0 === n) {
      if (((n = Object.create(null)), et(e)))
        for (const t of e.getTypes()) n[t.name] = !0;
      else {
        const t = this.getImplementations(e);
        for (const e of t.objects) n[e.name] = !0;
        for (const e of t.interfaces) n[e.name] = !0;
      }
      this._subTypeMap[e.name] = n;
    }
    return void 0 !== n[t.name];
  }
  getDirectives() {
    return this._directives;
  }
  getDirective(e) {
    return this.getDirectives().find((t) => t.name === e);
  }
  toConfig() {
    return {
      description: this.description,
      query: this.getQueryType(),
      mutation: this.getMutationType(),
      subscription: this.getSubscriptionType(),
      types: Object.values(this.getTypeMap()),
      directives: this.getDirectives(),
      extensions: this.extensions,
      astNode: this.astNode,
      extensionASTNodes: this.extensionASTNodes,
      assumeValid: void 0 !== this.__validationErrors,
    };
  }
}
function Mn(e, t) {
  const n = St(e);
  if (!t.has(n))
    if ((t.add(n), et(n))) for (const e of n.getTypes()) Mn(e, t);
    else if (ze(n) || We(n)) {
      for (const e of n.getInterfaces()) Mn(e, t);
      for (const e of Object.values(n.getFields())) {
        Mn(e.type, t);
        for (const n of e.args) Mn(n.type, t);
      }
    } else if (rt(n))
      for (const e of Object.values(n.getFields())) Mn(e.type, t);
  return t;
}
function jn(e) {
  if ((Vn(e), e.__validationErrors)) return e.__validationErrors;
  const t = new Bn(e);
  !(function (e) {
    const t = e.schema,
      n = t.getQueryType();
    if (n) {
      if (!ze(n)) {
        var i;
        e.reportError(
          `Query root type must be Object type, it cannot be ${ne(n)}.`,
          null !== (i = Gn(t, I.QUERY)) && void 0 !== i ? i : n.astNode
        );
      }
    } else e.reportError("Query root type must be provided.", t.astNode);
    const r = t.getMutationType();
    var o;
    r &&
      !ze(r) &&
      e.reportError(
        `Mutation root type must be Object type if provided, it cannot be ${ne(
          r
        )}.`,
        null !== (o = Gn(t, I.MUTATION)) && void 0 !== o ? o : r.astNode
      );
    const s = t.getSubscriptionType();
    var a;
    s &&
      !ze(s) &&
      e.reportError(
        `Subscription root type must be Object type if provided, it cannot be ${ne(
          s
        )}.`,
        null !== (a = Gn(t, I.SUBSCRIPTION)) && void 0 !== a ? a : s.astNode
      );
  })(t),
    (function (e) {
      for (const n of e.schema.getDirectives())
        if (un(n)) {
          Yn(e, n);
          for (const i of n.args) {
            var t;
            if (
              (Yn(e, i),
              lt(i.type) ||
                e.reportError(
                  `The type of @${n.name}(${
                    i.name
                  }:) must be Input Type but got: ${ne(i.type)}.`,
                  i.astNode
                ),
              jt(i) && null != i.deprecationReason)
            )
              e.reportError(
                `Required argument @${n.name}(${i.name}:) cannot be deprecated.`,
                [
                  ei(i.astNode),
                  null === (t = i.astNode) || void 0 === t ? void 0 : t.type,
                ]
              );
          }
        } else
          e.reportError(
            `Expected directive but got: ${ne(n)}.`,
            null == n ? void 0 : n.astNode
          );
    })(t),
    (function (e) {
      const t = (function (e) {
          const t = Object.create(null),
            n = [],
            i = Object.create(null);
          return r;
          function r(o) {
            if (t[o.name]) return;
            (t[o.name] = !0), (i[o.name] = n.length);
            const s = Object.values(o.getFields());
            for (const t of s)
              if (ct(t.type) && rt(t.type.ofType)) {
                const o = t.type.ofType,
                  s = i[o.name];
                if ((n.push(t), void 0 === s)) r(o);
                else {
                  const t = n.slice(s),
                    i = t.map((e) => e.name).join(".");
                  e.reportError(
                    `Cannot reference Input Object "${o.name}" within itself through a series of non-null fields: "${i}".`,
                    t.map((e) => e.astNode)
                  );
                }
                n.pop();
              }
            i[o.name] = void 0;
          }
        })(e),
        n = e.schema.getTypeMap();
      for (const i of Object.values(n))
        At(i)
          ? (Fn(i) || Yn(e, i),
            ze(i) || We(i)
              ? (Qn(e, i), Jn(e, i))
              : et(i)
              ? Xn(e, i)
              : nt(i)
              ? zn(e, i)
              : rt(i) && (Hn(e, i), t(i)))
          : e.reportError(
              `Expected GraphQL named type but got: ${ne(i)}.`,
              i.astNode
            );
    })(t);
  const n = t.getErrors();
  return (e.__validationErrors = n), n;
}
function Pn(e) {
  const t = jn(e);
  if (0 !== t.length) throw new Error(t.map((e) => e.message).join("\n\n"));
}
class Bn {
  constructor(e) {
    (this._errors = []), (this.schema = e);
  }
  reportError(e, t) {
    const n = Array.isArray(t) ? t.filter(Boolean) : t;
    this._errors.push(new p(e, { nodes: n }));
  }
  getErrors() {
    return this._errors;
  }
}
function Gn(e, t) {
  var n;
  return null ===
    (n = [e.astNode, ...e.extensionASTNodes]
      .flatMap((e) => {
        var t;
        return null !== (t = null == e ? void 0 : e.operationTypes) &&
          void 0 !== t
          ? t
          : [];
      })
      .find((e) => e.operation === t)) || void 0 === n
    ? void 0
    : n.type;
}
function Yn(e, t) {
  t.name.startsWith("__") &&
    e.reportError(
      `Name "${t.name}" must not begin with "__", which is reserved by GraphQL introspection.`,
      t.astNode
    );
}
function Qn(e, t) {
  const n = Object.values(t.getFields());
  0 === n.length &&
    e.reportError(`Type ${t.name} must define one or more fields.`, [
      t.astNode,
      ...t.extensionASTNodes,
    ]);
  for (const s of n) {
    var i;
    if ((Yn(e, s), !dt(s.type)))
      e.reportError(
        `The type of ${t.name}.${s.name} must be Output Type but got: ${ne(
          s.type
        )}.`,
        null === (i = s.astNode) || void 0 === i ? void 0 : i.type
      );
    for (const n of s.args) {
      const i = n.name;
      var r, o;
      if ((Yn(e, n), !lt(n.type)))
        e.reportError(
          `The type of ${t.name}.${
            s.name
          }(${i}:) must be Input Type but got: ${ne(n.type)}.`,
          null === (r = n.astNode) || void 0 === r ? void 0 : r.type
        );
      if (jt(n) && null != n.deprecationReason)
        e.reportError(
          `Required argument ${t.name}.${s.name}(${i}:) cannot be deprecated.`,
          [
            ei(n.astNode),
            null === (o = n.astNode) || void 0 === o ? void 0 : o.type,
          ]
        );
    }
  }
}
function Jn(e, t) {
  const n = Object.create(null);
  for (const i of t.getInterfaces())
    We(i)
      ? t !== i
        ? n[i.name]
          ? e.reportError(
              `Type ${t.name} can only implement ${i.name} once.`,
              Wn(t, i)
            )
          : ((n[i.name] = !0), Kn(e, t, i), qn(e, t, i))
        : e.reportError(
            `Type ${t.name} cannot implement itself because it would create a circular reference.`,
            Wn(t, i)
          )
      : e.reportError(
          `Type ${ne(
            t
          )} must only implement Interface types, it cannot implement ${ne(
            i
          )}.`,
          Wn(t, i)
        );
}
function qn(e, t, n) {
  const i = t.getFields();
  for (const c of Object.values(n.getFields())) {
    const u = c.name,
      l = i[u];
    if (l) {
      var r, o;
      if (!zt(e.schema, l.type, c.type))
        e.reportError(
          `Interface field ${n.name}.${u} expects type ${ne(c.type)} but ${
            t.name
          }.${u} is type ${ne(l.type)}.`,
          [
            null === (r = c.astNode) || void 0 === r ? void 0 : r.type,
            null === (o = l.astNode) || void 0 === o ? void 0 : o.type,
          ]
        );
      for (const i of c.args) {
        const r = i.name,
          o = l.args.find((e) => e.name === r);
        var s, a;
        if (o) {
          if (!Xt(i.type, o.type))
            e.reportError(
              `Interface field argument ${n.name}.${u}(${r}:) expects type ${ne(
                i.type
              )} but ${t.name}.${u}(${r}:) is type ${ne(o.type)}.`,
              [
                null === (s = i.astNode) || void 0 === s ? void 0 : s.type,
                null === (a = o.astNode) || void 0 === a ? void 0 : a.type,
              ]
            );
        } else
          e.reportError(
            `Interface field argument ${n.name}.${u}(${r}:) expected but ${t.name}.${u} does not provide it.`,
            [i.astNode, l.astNode]
          );
      }
      for (const i of l.args) {
        const r = i.name;
        !c.args.find((e) => e.name === r) &&
          jt(i) &&
          e.reportError(
            `Object field ${t.name}.${u} includes required argument ${r} that is missing from the Interface field ${n.name}.${u}.`,
            [i.astNode, c.astNode]
          );
      }
    } else
      e.reportError(
        `Interface field ${n.name}.${u} expected but ${t.name} does not provide it.`,
        [c.astNode, t.astNode, ...t.extensionASTNodes]
      );
  }
}
function Kn(e, t, n) {
  const i = t.getInterfaces();
  for (const r of n.getInterfaces())
    i.includes(r) ||
      e.reportError(
        r === t
          ? `Type ${t.name} cannot implement ${n.name} because it would create a circular reference.`
          : `Type ${t.name} must implement ${r.name} because it is implemented by ${n.name}.`,
        [...Wn(n, r), ...Wn(t, n)]
      );
}
function Xn(e, t) {
  const n = t.getTypes();
  0 === n.length &&
    e.reportError(
      `Union type ${t.name} must define one or more member types.`,
      [t.astNode, ...t.extensionASTNodes]
    );
  const i = Object.create(null);
  for (const r of n)
    i[r.name]
      ? e.reportError(
          `Union type ${t.name} can only include type ${r.name} once.`,
          Zn(t, r.name)
        )
      : ((i[r.name] = !0),
        ze(r) ||
          e.reportError(
            `Union type ${
              t.name
            } can only include Object types, it cannot include ${ne(r)}.`,
            Zn(t, String(r))
          ));
}
function zn(e, t) {
  const n = t.getValues();
  0 === n.length &&
    e.reportError(`Enum type ${t.name} must define one or more values.`, [
      t.astNode,
      ...t.extensionASTNodes,
    ]);
  for (const t of n) Yn(e, t);
}
function Hn(e, t) {
  const n = Object.values(t.getFields());
  0 === n.length &&
    e.reportError(
      `Input Object type ${t.name} must define one or more fields.`,
      [t.astNode, ...t.extensionASTNodes]
    );
  for (const o of n) {
    var i, r;
    if ((Yn(e, o), !lt(o.type)))
      e.reportError(
        `The type of ${t.name}.${o.name} must be Input Type but got: ${ne(
          o.type
        )}.`,
        null === (i = o.astNode) || void 0 === i ? void 0 : i.type
      );
    if (Kt(o) && null != o.deprecationReason)
      e.reportError(
        `Required input field ${t.name}.${o.name} cannot be deprecated.`,
        [
          ei(o.astNode),
          null === (r = o.astNode) || void 0 === r ? void 0 : r.type,
        ]
      );
  }
}
function Wn(e, t) {
  const { astNode: n, extensionASTNodes: i } = e;
  return (null != n ? [n, ...i] : i)
    .flatMap((e) => {
      var t;
      return null !== (t = e.interfaces) && void 0 !== t ? t : [];
    })
    .filter((e) => e.name.value === t.name);
}
function Zn(e, t) {
  const { astNode: n, extensionASTNodes: i } = e;
  return (null != n ? [n, ...i] : i)
    .flatMap((e) => {
      var t;
      return null !== (t = e.types) && void 0 !== t ? t : [];
    })
    .filter((e) => e.name.value === t);
}
function ei(e) {
  var t;
  return null == e || null === (t = e.directives) || void 0 === t
    ? void 0
    : t.find((e) => e.name.value === mn.name);
}
function ti(e, t) {
  switch (t.kind) {
    case _.LIST_TYPE: {
      const n = ti(e, t.type);
      return n && new Nt(n);
    }
    case _.NON_NULL_TYPE: {
      const n = ti(e, t.type);
      return n && new It(n);
    }
    case _.NAMED_TYPE:
      return e.getType(t.name.value);
  }
}
class ni {
  constructor(e, t, n) {
    (this._schema = e),
      (this._typeStack = []),
      (this._parentTypeStack = []),
      (this._inputTypeStack = []),
      (this._fieldDefStack = []),
      (this._defaultValueStack = []),
      (this._directive = null),
      (this._argument = null),
      (this._enumValue = null),
      (this._getFieldDef = null != n ? n : ii),
      t &&
        (lt(t) && this._inputTypeStack.push(t),
        yt(t) && this._parentTypeStack.push(t),
        dt(t) && this._typeStack.push(t));
  }
  get [Symbol.toStringTag]() {
    return "TypeInfo";
  }
  getType() {
    if (this._typeStack.length > 0)
      return this._typeStack[this._typeStack.length - 1];
  }
  getParentType() {
    if (this._parentTypeStack.length > 0)
      return this._parentTypeStack[this._parentTypeStack.length - 1];
  }
  getInputType() {
    if (this._inputTypeStack.length > 0)
      return this._inputTypeStack[this._inputTypeStack.length - 1];
  }
  getParentInputType() {
    if (this._inputTypeStack.length > 1)
      return this._inputTypeStack[this._inputTypeStack.length - 2];
  }
  getFieldDef() {
    if (this._fieldDefStack.length > 0)
      return this._fieldDefStack[this._fieldDefStack.length - 1];
  }
  getDefaultValue() {
    if (this._defaultValueStack.length > 0)
      return this._defaultValueStack[this._defaultValueStack.length - 1];
  }
  getDirective() {
    return this._directive;
  }
  getArgument() {
    return this._argument;
  }
  getEnumValue() {
    return this._enumValue;
  }
  enter(e) {
    const t = this._schema;
    switch (e.kind) {
      case _.SELECTION_SET: {
        const e = St(this.getType());
        this._parentTypeStack.push(yt(e) ? e : void 0);
        break;
      }
      case _.FIELD: {
        const n = this.getParentType();
        let i, r;
        n && ((i = this._getFieldDef(t, n, e)), i && (r = i.type)),
          this._fieldDefStack.push(i),
          this._typeStack.push(dt(r) ? r : void 0);
        break;
      }
      case _.DIRECTIVE:
        this._directive = t.getDirective(e.name.value);
        break;
      case _.OPERATION_DEFINITION: {
        const n = t.getRootType(e.operation);
        this._typeStack.push(ze(n) ? n : void 0);
        break;
      }
      case _.INLINE_FRAGMENT:
      case _.FRAGMENT_DEFINITION: {
        const n = e.typeCondition,
          i = n ? ti(t, n) : St(this.getType());
        this._typeStack.push(dt(i) ? i : void 0);
        break;
      }
      case _.VARIABLE_DEFINITION: {
        const n = ti(t, e.type);
        this._inputTypeStack.push(lt(n) ? n : void 0);
        break;
      }
      case _.ARGUMENT: {
        var n;
        let t, i;
        const r =
          null !== (n = this.getDirective()) && void 0 !== n
            ? n
            : this.getFieldDef();
        r &&
          ((t = r.args.find((t) => t.name === e.name.value)),
          t && (i = t.type)),
          (this._argument = t),
          this._defaultValueStack.push(t ? t.defaultValue : void 0),
          this._inputTypeStack.push(lt(i) ? i : void 0);
        break;
      }
      case _.LIST: {
        const e = Dt(this.getInputType()),
          t = st(e) ? e.ofType : e;
        this._defaultValueStack.push(void 0),
          this._inputTypeStack.push(lt(t) ? t : void 0);
        break;
      }
      case _.OBJECT_FIELD: {
        const t = St(this.getInputType());
        let n, i;
        rt(t) && ((i = t.getFields()[e.name.value]), i && (n = i.type)),
          this._defaultValueStack.push(i ? i.defaultValue : void 0),
          this._inputTypeStack.push(lt(n) ? n : void 0);
        break;
      }
      case _.ENUM: {
        const t = St(this.getInputType());
        let n;
        nt(t) && (n = t.getValue(e.value)), (this._enumValue = n);
        break;
      }
    }
  }
  leave(e) {
    switch (e.kind) {
      case _.SELECTION_SET:
        this._parentTypeStack.pop();
        break;
      case _.FIELD:
        this._fieldDefStack.pop(), this._typeStack.pop();
        break;
      case _.DIRECTIVE:
        this._directive = null;
        break;
      case _.OPERATION_DEFINITION:
      case _.INLINE_FRAGMENT:
      case _.FRAGMENT_DEFINITION:
        this._typeStack.pop();
        break;
      case _.VARIABLE_DEFINITION:
        this._inputTypeStack.pop();
        break;
      case _.ARGUMENT:
        (this._argument = null),
          this._defaultValueStack.pop(),
          this._inputTypeStack.pop();
        break;
      case _.LIST:
      case _.OBJECT_FIELD:
        this._defaultValueStack.pop(), this._inputTypeStack.pop();
        break;
      case _.ENUM:
        this._enumValue = null;
    }
  }
}
function ii(e, t, n) {
  const i = n.name.value;
  return i === $n.name && e.getQueryType() === t
    ? $n
    : i === xn.name && e.getQueryType() === t
    ? xn
    : i === kn.name && yt(t)
    ? kn
    : ze(t) || We(t)
    ? t.getFields()[i]
    : void 0;
}
function ri(e, t) {
  return {
    enter(...n) {
      const i = n[0];
      e.enter(i);
      const r = Le(t, i.kind).enter;
      if (r) {
        const o = r.apply(t, n);
        return void 0 !== o && (e.leave(i), N(o) && e.enter(o)), o;
      }
    },
    leave(...n) {
      const i = n[0],
        r = Le(t, i.kind).leave;
      let o;
      return r && (o = r.apply(t, n)), e.leave(i), o;
    },
  };
}
function oi(e) {
  return si(e) || pi(e) || fi(e);
}
function si(e) {
  return e.kind === _.OPERATION_DEFINITION || e.kind === _.FRAGMENT_DEFINITION;
}
function ai(e) {
  return (
    e.kind === _.FIELD ||
    e.kind === _.FRAGMENT_SPREAD ||
    e.kind === _.INLINE_FRAGMENT
  );
}
function ci(e) {
  return (
    e.kind === _.VARIABLE ||
    e.kind === _.INT ||
    e.kind === _.FLOAT ||
    e.kind === _.STRING ||
    e.kind === _.BOOLEAN ||
    e.kind === _.NULL ||
    e.kind === _.ENUM ||
    e.kind === _.LIST ||
    e.kind === _.OBJECT
  );
}
function ui(e) {
  return (
    ci(e) &&
    (e.kind === _.LIST
      ? e.values.some(ui)
      : e.kind === _.OBJECT
      ? e.fields.some((e) => ui(e.value))
      : e.kind !== _.VARIABLE)
  );
}
function li(e) {
  return (
    e.kind === _.NAMED_TYPE ||
    e.kind === _.LIST_TYPE ||
    e.kind === _.NON_NULL_TYPE
  );
}
function pi(e) {
  return (
    e.kind === _.SCHEMA_DEFINITION || di(e) || e.kind === _.DIRECTIVE_DEFINITION
  );
}
function di(e) {
  return (
    e.kind === _.SCALAR_TYPE_DEFINITION ||
    e.kind === _.OBJECT_TYPE_DEFINITION ||
    e.kind === _.INTERFACE_TYPE_DEFINITION ||
    e.kind === _.UNION_TYPE_DEFINITION ||
    e.kind === _.ENUM_TYPE_DEFINITION ||
    e.kind === _.INPUT_OBJECT_TYPE_DEFINITION
  );
}
function fi(e) {
  return e.kind === _.SCHEMA_EXTENSION || hi(e);
}
function hi(e) {
  return (
    e.kind === _.SCALAR_TYPE_EXTENSION ||
    e.kind === _.OBJECT_TYPE_EXTENSION ||
    e.kind === _.INTERFACE_TYPE_EXTENSION ||
    e.kind === _.UNION_TYPE_EXTENSION ||
    e.kind === _.ENUM_TYPE_EXTENSION ||
    e.kind === _.INPUT_OBJECT_TYPE_EXTENSION
  );
}
function mi(e) {
  return {
    Document(t) {
      for (const n of t.definitions)
        if (!si(n)) {
          const t =
            n.kind === _.SCHEMA_DEFINITION || n.kind === _.SCHEMA_EXTENSION
              ? "schema"
              : '"' + n.name.value + '"';
          e.reportError(
            new p(`The ${t} definition is not executable.`, { nodes: n })
          );
        }
      return !1;
    },
  };
}
function yi(e) {
  return {
    Field(t) {
      const n = e.getParentType();
      if (n) {
        if (!e.getFieldDef()) {
          const i = e.getSchema(),
            r = t.name.value;
          let o = me(
            "to use an inline fragment on",
            (function (e, t, n) {
              if (!vt(t)) return [];
              const i = new Set(),
                r = Object.create(null);
              for (const s of e.getPossibleTypes(t))
                if (s.getFields()[n]) {
                  i.add(s), (r[s.name] = 1);
                  for (const e of s.getInterfaces()) {
                    var o;
                    e.getFields()[n] &&
                      (i.add(e),
                      (r[e.name] =
                        (null !== (o = r[e.name]) && void 0 !== o ? o : 0) +
                        1));
                  }
                }
              return [...i]
                .sort((t, n) => {
                  const i = r[n.name] - r[t.name];
                  return 0 !== i
                    ? i
                    : We(t) && e.isSubType(t, n)
                    ? -1
                    : We(n) && e.isSubType(n, t)
                    ? 1
                    : Ne(t.name, n.name);
                })
                .map((e) => e.name);
            })(i, n, r)
          );
          "" === o &&
            (o = me(
              (function (e, t) {
                if (ze(e) || We(e)) {
                  return be(t, Object.keys(e.getFields()));
                }
                return [];
              })(n, r)
            )),
            e.reportError(
              new p(`Cannot query field "${r}" on type "${n.name}".` + o, {
                nodes: t,
              })
            );
        }
      }
    },
  };
}
function Ei(e) {
  return {
    InlineFragment(t) {
      const n = t.typeCondition;
      if (n) {
        const t = ti(e.getSchema(), n);
        if (t && !yt(t)) {
          const t = Ce(n);
          e.reportError(
            new p(`Fragment cannot condition on non composite type "${t}".`, {
              nodes: n,
            })
          );
        }
      }
    },
    FragmentDefinition(t) {
      const n = ti(e.getSchema(), t.typeCondition);
      if (n && !yt(n)) {
        const n = Ce(t.typeCondition);
        e.reportError(
          new p(
            `Fragment "${t.name.value}" cannot condition on non composite type "${n}".`,
            { nodes: t.typeCondition }
          )
        );
      }
    },
  };
}
function vi(e) {
  return {
    ...Ti(e),
    Argument(t) {
      const n = e.getArgument(),
        i = e.getFieldDef(),
        r = e.getParentType();
      if (!n && i && r) {
        const n = t.name.value,
          o = be(
            n,
            i.args.map((e) => e.name)
          );
        e.reportError(
          new p(
            `Unknown argument "${n}" on field "${r.name}.${i.name}".` + me(o),
            { nodes: t }
          )
        );
      }
    },
  };
}
function Ti(e) {
  const t = Object.create(null),
    n = e.getSchema(),
    i = n ? n.getDirectives() : En;
  for (const e of i) t[e.name] = e.args.map((e) => e.name);
  const r = e.getDocument().definitions;
  for (const e of r)
    if (e.kind === _.DIRECTIVE_DEFINITION) {
      var o;
      const n = null !== (o = e.arguments) && void 0 !== o ? o : [];
      t[e.name.value] = n.map((e) => e.name.value);
    }
  return {
    Directive(n) {
      const i = n.name.value,
        r = t[i];
      if (n.arguments && r)
        for (const t of n.arguments) {
          const n = t.name.value;
          if (!r.includes(n)) {
            const o = be(n, r);
            e.reportError(
              new p(`Unknown argument "${n}" on directive "@${i}".` + me(o), {
                nodes: t,
              })
            );
          }
        }
      return !1;
    },
  };
}
function Ni(e) {
  const t = Object.create(null),
    n = e.getSchema(),
    i = n ? n.getDirectives() : En;
  for (const e of i) t[e.name] = e.locations;
  const r = e.getDocument().definitions;
  for (const e of r)
    e.kind === _.DIRECTIVE_DEFINITION &&
      (t[e.name.value] = e.locations.map((e) => e.value));
  return {
    Directive(n, i, r, s, a) {
      const c = n.name.value,
        u = t[c];
      if (!u)
        return void e.reportError(
          new p(`Unknown directive "@${c}".`, { nodes: n })
        );
      const l = (function (e) {
        const t = e[e.length - 1];
        switch (("kind" in t || o(!1), t.kind)) {
          case _.OPERATION_DEFINITION:
            return (function (e) {
              switch (e) {
                case I.QUERY:
                  return g.QUERY;
                case I.MUTATION:
                  return g.MUTATION;
                case I.SUBSCRIPTION:
                  return g.SUBSCRIPTION;
              }
            })(t.operation);
          case _.FIELD:
            return g.FIELD;
          case _.FRAGMENT_SPREAD:
            return g.FRAGMENT_SPREAD;
          case _.INLINE_FRAGMENT:
            return g.INLINE_FRAGMENT;
          case _.FRAGMENT_DEFINITION:
            return g.FRAGMENT_DEFINITION;
          case _.VARIABLE_DEFINITION:
            return g.VARIABLE_DEFINITION;
          case _.SCHEMA_DEFINITION:
          case _.SCHEMA_EXTENSION:
            return g.SCHEMA;
          case _.SCALAR_TYPE_DEFINITION:
          case _.SCALAR_TYPE_EXTENSION:
            return g.SCALAR;
          case _.OBJECT_TYPE_DEFINITION:
          case _.OBJECT_TYPE_EXTENSION:
            return g.OBJECT;
          case _.FIELD_DEFINITION:
            return g.FIELD_DEFINITION;
          case _.INTERFACE_TYPE_DEFINITION:
          case _.INTERFACE_TYPE_EXTENSION:
            return g.INTERFACE;
          case _.UNION_TYPE_DEFINITION:
          case _.UNION_TYPE_EXTENSION:
            return g.UNION;
          case _.ENUM_TYPE_DEFINITION:
          case _.ENUM_TYPE_EXTENSION:
            return g.ENUM;
          case _.ENUM_VALUE_DEFINITION:
            return g.ENUM_VALUE;
          case _.INPUT_OBJECT_TYPE_DEFINITION:
          case _.INPUT_OBJECT_TYPE_EXTENSION:
            return g.INPUT_OBJECT;
          case _.INPUT_VALUE_DEFINITION: {
            const t = e[e.length - 3];
            return (
              "kind" in t || o(!1),
              t.kind === _.INPUT_OBJECT_TYPE_DEFINITION
                ? g.INPUT_FIELD_DEFINITION
                : g.ARGUMENT_DEFINITION
            );
          }
          default:
            o(!1, "Unexpected kind: " + ne(t.kind));
        }
      })(a);
      l &&
        !u.includes(l) &&
        e.reportError(
          new p(`Directive "@${c}" may not be used on ${l}.`, { nodes: n })
        );
    },
  };
}
function Ii(e) {
  return {
    FragmentSpread(t) {
      const n = t.name.value;
      e.getFragment(n) ||
        e.reportError(new p(`Unknown fragment "${n}".`, { nodes: t.name }));
    },
  };
}
function gi(e) {
  const t = e.getSchema(),
    n = t ? t.getTypeMap() : Object.create(null),
    i = Object.create(null);
  for (const t of e.getDocument().definitions) di(t) && (i[t.name.value] = !0);
  const r = [...Object.keys(n), ...Object.keys(i)];
  return {
    NamedType(t, o, s, a, c) {
      const u = t.name.value;
      if (!n[u] && !i[u]) {
        var l;
        const n = null !== (l = c[2]) && void 0 !== l ? l : s,
          i = null != n && "kind" in (d = n) && (pi(d) || fi(d));
        if (i && _i.includes(u)) return;
        const o = be(u, i ? _i.concat(r) : r);
        e.reportError(new p(`Unknown type "${u}".` + me(o), { nodes: t }));
      }
      var d;
    },
  };
}
const _i = [...sn, ...Ln].map((e) => e.name);
function bi(e) {
  let t = 0;
  return {
    Document(e) {
      t = e.definitions.filter((e) => e.kind === _.OPERATION_DEFINITION).length;
    },
    OperationDefinition(n) {
      !n.name &&
        t > 1 &&
        e.reportError(
          new p(
            "This anonymous operation must be the only defined operation.",
            { nodes: n }
          )
        );
    },
  };
}
function Oi(e) {
  var t, n, i;
  const r = e.getSchema(),
    o =
      null !==
        (t =
          null !==
            (n =
              null !== (i = null == r ? void 0 : r.astNode) && void 0 !== i
                ? i
                : null == r
                ? void 0
                : r.getQueryType()) && void 0 !== n
            ? n
            : null == r
            ? void 0
            : r.getMutationType()) && void 0 !== t
        ? t
        : null == r
        ? void 0
        : r.getSubscriptionType();
  let s = 0;
  return {
    SchemaDefinition(t) {
      o
        ? e.reportError(
            new p("Cannot define a new schema within a schema extension.", {
              nodes: t,
            })
          )
        : (s > 0 &&
            e.reportError(
              new p("Must provide only one schema definition.", { nodes: t })
            ),
          ++s);
    },
  };
}
function Di(e) {
  const t = Object.create(null),
    n = [],
    i = Object.create(null);
  return {
    OperationDefinition: () => !1,
    FragmentDefinition: (e) => (r(e), !1),
  };
  function r(o) {
    if (t[o.name.value]) return;
    const s = o.name.value;
    t[s] = !0;
    const a = e.getFragmentSpreads(o.selectionSet);
    if (0 !== a.length) {
      i[s] = n.length;
      for (const t of a) {
        const o = t.name.value,
          s = i[o];
        if ((n.push(t), void 0 === s)) {
          const t = e.getFragment(o);
          t && r(t);
        } else {
          const t = n.slice(s),
            i = t
              .slice(0, -1)
              .map((e) => '"' + e.name.value + '"')
              .join(", ");
          e.reportError(
            new p(
              `Cannot spread fragment "${o}" within itself` +
                ("" !== i ? ` via ${i}.` : "."),
              { nodes: t }
            )
          );
        }
        n.pop();
      }
      i[s] = void 0;
    }
  }
}
function Ai(e) {
  let t = Object.create(null);
  return {
    OperationDefinition: {
      enter() {
        t = Object.create(null);
      },
      leave(n) {
        const i = e.getRecursiveVariableUsages(n);
        for (const { node: r } of i) {
          const i = r.name.value;
          !0 !== t[i] &&
            e.reportError(
              new p(
                n.name
                  ? `Variable "$${i}" is not defined by operation "${n.name.value}".`
                  : `Variable "$${i}" is not defined.`,
                { nodes: [r, n] }
              )
            );
        }
      },
    },
    VariableDefinition(e) {
      t[e.variable.name.value] = !0;
    },
  };
}
function wi(e) {
  const t = [],
    n = [];
  return {
    OperationDefinition: (e) => (t.push(e), !1),
    FragmentDefinition: (e) => (n.push(e), !1),
    Document: {
      leave() {
        const i = Object.create(null);
        for (const n of t)
          for (const t of e.getRecursivelyReferencedFragments(n))
            i[t.name.value] = !0;
        for (const t of n) {
          const n = t.name.value;
          !0 !== i[n] &&
            e.reportError(
              new p(`Fragment "${n}" is never used.`, { nodes: t })
            );
        }
      },
    },
  };
}
function Si(e) {
  let t = [];
  return {
    OperationDefinition: {
      enter() {
        t = [];
      },
      leave(n) {
        const i = Object.create(null),
          r = e.getRecursiveVariableUsages(n);
        for (const { node: e } of r) i[e.name.value] = !0;
        for (const r of t) {
          const t = r.variable.name.value;
          !0 !== i[t] &&
            e.reportError(
              new p(
                n.name
                  ? `Variable "$${t}" is never used in operation "${n.name.value}".`
                  : `Variable "$${t}" is never used.`,
                { nodes: r }
              )
            );
        }
      },
    },
    VariableDefinition(e) {
      t.push(e);
    },
  };
}
function Ri(e) {
  switch (e.kind) {
    case _.OBJECT:
      return {
        ...e,
        fields:
          ((t = e.fields),
          t
            .map((e) => ({ ...e, value: Ri(e.value) }))
            .sort((e, t) => Ne(e.name.value, t.name.value))),
      };
    case _.LIST:
      return { ...e, values: e.values.map(Ri) };
    case _.INT:
    case _.FLOAT:
    case _.STRING:
    case _.BOOLEAN:
    case _.NULL:
    case _.ENUM:
    case _.VARIABLE:
      return e;
  }
  var t;
}
function $i(e) {
  return Array.isArray(e)
    ? e
        .map(([e, t]) => `subfields "${e}" conflict because ` + $i(t))
        .join(" and ")
    : e;
}
function xi(e) {
  const t = new Bi(),
    n = new Map();
  return {
    SelectionSet(i) {
      const r = (function (e, t, n, i, r) {
        const o = [],
          [s, a] = Mi(e, t, i, r);
        if (
          ((function (e, t, n, i, r) {
            for (const [o, s] of Object.entries(r))
              if (s.length > 1)
                for (let r = 0; r < s.length; r++)
                  for (let a = r + 1; a < s.length; a++) {
                    const c = Ci(e, n, i, !1, o, s[r], s[a]);
                    c && t.push(c);
                  }
          })(e, o, t, n, s),
          0 !== a.length)
        )
          for (let i = 0; i < a.length; i++) {
            ki(e, o, t, n, !1, s, a[i]);
            for (let r = i + 1; r < a.length; r++)
              Li(e, o, t, n, !1, a[i], a[r]);
          }
        return o;
      })(e, n, t, e.getParentType(), i);
      for (const [[t, n], i, o] of r) {
        const r = $i(n);
        e.reportError(
          new p(
            `Fields "${t}" conflict because ${r}. Use different aliases on the fields to fetch both if this was intentional.`,
            { nodes: i.concat(o) }
          )
        );
      }
    },
  };
}
function ki(e, t, n, i, r, o, s) {
  const a = e.getFragment(s);
  if (!a) return;
  const [c, u] = ji(e, n, a);
  if (o !== c) {
    Fi(e, t, n, i, r, o, c);
    for (const a of u)
      i.has(a, s, r) || (i.add(a, s, r), ki(e, t, n, i, r, o, a));
  }
}
function Li(e, t, n, i, r, o, s) {
  if (o === s) return;
  if (i.has(o, s, r)) return;
  i.add(o, s, r);
  const a = e.getFragment(o),
    c = e.getFragment(s);
  if (!a || !c) return;
  const [u, l] = ji(e, n, a),
    [p, d] = ji(e, n, c);
  Fi(e, t, n, i, r, u, p);
  for (const s of d) Li(e, t, n, i, r, o, s);
  for (const o of l) Li(e, t, n, i, r, o, s);
}
function Fi(e, t, n, i, r, o, s) {
  for (const [a, c] of Object.entries(o)) {
    const o = s[a];
    if (o)
      for (const s of c)
        for (const c of o) {
          const o = Ci(e, n, i, r, a, s, c);
          o && t.push(o);
        }
  }
}
function Ci(e, t, n, i, r, o, s) {
  const [a, c, u] = o,
    [l, p, d] = s,
    f = i || (a !== l && ze(a) && ze(l));
  if (!f) {
    const e = c.name.value,
      t = p.name.value;
    if (e !== t)
      return [[r, `"${e}" and "${t}" are different fields`], [c], [p]];
    if (Vi(c) !== Vi(p))
      return [[r, "they have differing arguments"], [c], [p]];
  }
  const h = null == u ? void 0 : u.type,
    m = null == d ? void 0 : d.type;
  if (h && m && Ui(h, m))
    return [
      [r, `they return conflicting types "${ne(h)}" and "${ne(m)}"`],
      [c],
      [p],
    ];
  const y = c.selectionSet,
    E = p.selectionSet;
  if (y && E) {
    const i = (function (e, t, n, i, r, o, s, a) {
      const c = [],
        [u, l] = Mi(e, t, r, o),
        [p, d] = Mi(e, t, s, a);
      Fi(e, c, t, n, i, u, p);
      for (const r of d) ki(e, c, t, n, i, u, r);
      for (const r of l) ki(e, c, t, n, i, p, r);
      for (const r of l) for (const o of d) Li(e, c, t, n, i, r, o);
      return c;
    })(e, t, n, f, St(h), y, St(m), E);
    return (function (e, t, n, i) {
      if (e.length > 0)
        return [
          [t, e.map(([e]) => e)],
          [n, ...e.map(([, e]) => e).flat()],
          [i, ...e.map(([, , e]) => e).flat()],
        ];
    })(i, r, c, p);
  }
}
function Vi(e) {
  var t;
  const n = null !== (t = e.arguments) && void 0 !== t ? t : [];
  return Ce(
    Ri({
      kind: _.OBJECT,
      fields: n.map((e) => ({
        kind: _.OBJECT_FIELD,
        name: e.name,
        value: e.value,
      })),
    })
  );
}
function Ui(e, t) {
  return st(e)
    ? !st(t) || Ui(e.ofType, t.ofType)
    : !!st(t) ||
        (ct(e)
          ? !ct(t) || Ui(e.ofType, t.ofType)
          : !!ct(t) || (!(!ht(e) && !ht(t)) && e !== t));
}
function Mi(e, t, n, i) {
  const r = t.get(i);
  if (r) return r;
  const o = Object.create(null),
    s = Object.create(null);
  Pi(e, n, i, o, s);
  const a = [o, Object.keys(s)];
  return t.set(i, a), a;
}
function ji(e, t, n) {
  const i = t.get(n.selectionSet);
  if (i) return i;
  const r = ti(e.getSchema(), n.typeCondition);
  return Mi(e, t, r, n.selectionSet);
}
function Pi(e, t, n, i, r) {
  for (const o of n.selections)
    switch (o.kind) {
      case _.FIELD: {
        const e = o.name.value;
        let n;
        (ze(t) || We(t)) && (n = t.getFields()[e]);
        const r = o.alias ? o.alias.value : e;
        i[r] || (i[r] = []), i[r].push([t, o, n]);
        break;
      }
      case _.FRAGMENT_SPREAD:
        r[o.name.value] = !0;
        break;
      case _.INLINE_FRAGMENT: {
        const n = o.typeCondition,
          s = n ? ti(e.getSchema(), n) : t;
        Pi(e, s, o.selectionSet, i, r);
        break;
      }
    }
}
class Bi {
  constructor() {
    this._data = new Map();
  }
  has(e, t, n) {
    var i;
    const [r, o] = e < t ? [e, t] : [t, e],
      s = null === (i = this._data.get(r)) || void 0 === i ? void 0 : i.get(o);
    return void 0 !== s && (!!n || n === s);
  }
  add(e, t, n) {
    const [i, r] = e < t ? [e, t] : [t, e],
      o = this._data.get(i);
    void 0 === o ? this._data.set(i, new Map([[r, n]])) : o.set(r, n);
  }
}
function Gi(e) {
  return {
    InlineFragment(t) {
      const n = e.getType(),
        i = e.getParentType();
      if (yt(n) && yt(i) && !Ht(e.getSchema(), n, i)) {
        const r = ne(i),
          o = ne(n);
        e.reportError(
          new p(
            `Fragment cannot be spread here as objects of type "${r}" can never be of type "${o}".`,
            { nodes: t }
          )
        );
      }
    },
    FragmentSpread(t) {
      const n = t.name.value,
        i = (function (e, t) {
          const n = e.getFragment(t);
          if (n) {
            const t = ti(e.getSchema(), n.typeCondition);
            if (yt(t)) return t;
          }
        })(e, n),
        r = e.getParentType();
      if (i && r && !Ht(e.getSchema(), i, r)) {
        const o = ne(r),
          s = ne(i);
        e.reportError(
          new p(
            `Fragment "${n}" cannot be spread here as objects of type "${o}" can never be of type "${s}".`,
            { nodes: t }
          )
        );
      }
    },
  };
}
function Yi(e) {
  const t = e.getSchema(),
    n = Object.create(null);
  for (const t of e.getDocument().definitions) di(t) && (n[t.name.value] = t);
  return {
    ScalarTypeExtension: i,
    ObjectTypeExtension: i,
    InterfaceTypeExtension: i,
    UnionTypeExtension: i,
    EnumTypeExtension: i,
    InputObjectTypeExtension: i,
  };
  function i(i) {
    const r = i.name.value,
      s = n[r],
      a = null == t ? void 0 : t.getType(r);
    let c;
    if (
      (s
        ? (c = Qi[s.kind])
        : a &&
          (c = (function (e) {
            if (Ke(e)) return _.SCALAR_TYPE_EXTENSION;
            if (ze(e)) return _.OBJECT_TYPE_EXTENSION;
            if (We(e)) return _.INTERFACE_TYPE_EXTENSION;
            if (et(e)) return _.UNION_TYPE_EXTENSION;
            if (nt(e)) return _.ENUM_TYPE_EXTENSION;
            if (rt(e)) return _.INPUT_OBJECT_TYPE_EXTENSION;
            o(!1, "Unexpected type: " + ne(e));
          })(a)),
      c)
    ) {
      if (c !== i.kind) {
        const t = (function (e) {
          switch (e) {
            case _.SCALAR_TYPE_EXTENSION:
              return "scalar";
            case _.OBJECT_TYPE_EXTENSION:
              return "object";
            case _.INTERFACE_TYPE_EXTENSION:
              return "interface";
            case _.UNION_TYPE_EXTENSION:
              return "union";
            case _.ENUM_TYPE_EXTENSION:
              return "enum";
            case _.INPUT_OBJECT_TYPE_EXTENSION:
              return "input object";
            default:
              o(!1, "Unexpected kind: " + ne(e));
          }
        })(i.kind);
        e.reportError(
          new p(`Cannot extend non-${t} type "${r}".`, {
            nodes: s ? [s, i] : i,
          })
        );
      }
    } else {
      const o = be(
        r,
        Object.keys({ ...n, ...(null == t ? void 0 : t.getTypeMap()) })
      );
      e.reportError(
        new p(`Cannot extend type "${r}" because it is not defined.` + me(o), {
          nodes: i.name,
        })
      );
    }
  }
}
const Qi = {
  [_.SCALAR_TYPE_DEFINITION]: _.SCALAR_TYPE_EXTENSION,
  [_.OBJECT_TYPE_DEFINITION]: _.OBJECT_TYPE_EXTENSION,
  [_.INTERFACE_TYPE_DEFINITION]: _.INTERFACE_TYPE_EXTENSION,
  [_.UNION_TYPE_DEFINITION]: _.UNION_TYPE_EXTENSION,
  [_.ENUM_TYPE_DEFINITION]: _.ENUM_TYPE_EXTENSION,
  [_.INPUT_OBJECT_TYPE_DEFINITION]: _.INPUT_OBJECT_TYPE_EXTENSION,
};
function Ji(e) {
  return {
    ...qi(e),
    Field: {
      leave(t) {
        var n;
        const i = e.getFieldDef();
        if (!i) return !1;
        const r = new Set(
          null === (n = t.arguments) || void 0 === n
            ? void 0
            : n.map((e) => e.name.value)
        );
        for (const n of i.args)
          if (!r.has(n.name) && jt(n)) {
            const r = ne(n.type);
            e.reportError(
              new p(
                `Field "${i.name}" argument "${n.name}" of type "${r}" is required, but it was not provided.`,
                { nodes: t }
              )
            );
          }
      },
    },
  };
}
function qi(e) {
  var t;
  const n = Object.create(null),
    i = e.getSchema(),
    r =
      null !== (t = null == i ? void 0 : i.getDirectives()) && void 0 !== t
        ? t
        : En;
  for (const e of r) n[e.name] = Ee(e.args.filter(jt), (e) => e.name);
  const o = e.getDocument().definitions;
  for (const e of o)
    if (e.kind === _.DIRECTIVE_DEFINITION) {
      var s;
      const t = null !== (s = e.arguments) && void 0 !== s ? s : [];
      n[e.name.value] = Ee(t.filter(Ki), (e) => e.name.value);
    }
  return {
    Directive: {
      leave(t) {
        const i = t.name.value,
          r = n[i];
        if (r) {
          var o;
          const n = null !== (o = t.arguments) && void 0 !== o ? o : [],
            s = new Set(n.map((e) => e.name.value));
          for (const [n, o] of Object.entries(r))
            if (!s.has(n)) {
              const r = Je(o.type) ? ne(o.type) : Ce(o.type);
              e.reportError(
                new p(
                  `Directive "@${i}" argument "${n}" of type "${r}" is required, but it was not provided.`,
                  { nodes: t }
                )
              );
            }
        }
      },
    },
  };
}
function Ki(e) {
  return e.type.kind === _.NON_NULL_TYPE && null == e.defaultValue;
}
function Xi(e) {
  return {
    Field(t) {
      const n = e.getType(),
        i = t.selectionSet;
      if (n)
        if (ht(St(n))) {
          if (i) {
            const r = t.name.value,
              o = ne(n);
            e.reportError(
              new p(
                `Field "${r}" must not have a selection since type "${o}" has no subfields.`,
                { nodes: i }
              )
            );
          }
        } else if (!i) {
          const i = t.name.value,
            r = ne(n);
          e.reportError(
            new p(
              `Field "${i}" of type "${r}" must have a selection of subfields. Did you mean "${i} { ... }"?`,
              { nodes: t }
            )
          );
        }
    },
  };
}
function zi(e) {
  return e
    .map((e) => ("number" == typeof e ? "[" + e.toString() + "]" : "." + e))
    .join("");
}
function Hi(e, t, n) {
  return { prev: e, key: t, typename: n };
}
function Wi(e) {
  const t = [];
  let n = e;
  for (; n; ) t.push(n.key), (n = n.prev);
  return t.reverse();
}
function Zi(e, t, n = er) {
  return tr(e, t, n, void 0);
}
function er(e, t, n) {
  let i = "Invalid value " + ne(t);
  throw (
    (e.length > 0 && (i += ` at "value${zi(e)}"`),
    (n.message = i + ": " + n.message),
    n)
  );
}
function tr(e, t, n, i) {
  if (ct(t))
    return null != e
      ? tr(e, t.ofType, n, i)
      : void n(
          Wi(i),
          e,
          new p(`Expected non-nullable type "${ne(t)}" not to be null.`)
        );
  if (null == e) return null;
  if (st(t)) {
    const r = t.ofType;
    return Tn(e)
      ? Array.from(e, (e, t) => {
          const o = Hi(i, t, void 0);
          return tr(e, r, n, o);
        })
      : [tr(e, r, n, i)];
  }
  if (rt(t)) {
    if (!r(e))
      return void n(
        Wi(i),
        e,
        new p(`Expected type "${t.name}" to be an object.`)
      );
    const o = {},
      s = t.getFields();
    for (const r of Object.values(s)) {
      const s = e[r.name];
      if (void 0 !== s) o[r.name] = tr(s, r.type, n, Hi(i, r.name, t.name));
      else if (void 0 !== r.defaultValue) o[r.name] = r.defaultValue;
      else if (ct(r.type)) {
        const t = ne(r.type);
        n(
          Wi(i),
          e,
          new p(`Field "${r.name}" of required type "${t}" was not provided.`)
        );
      }
    }
    for (const r of Object.keys(e))
      if (!s[r]) {
        const o = be(r, Object.keys(t.getFields()));
        n(
          Wi(i),
          e,
          new p(`Field "${r}" is not defined by type "${t.name}".` + me(o))
        );
      }
    return o;
  }
  if (ht(t)) {
    let r;
    try {
      r = t.parseValue(e);
    } catch (r) {
      return void n(
        Wi(i),
        e,
        r instanceof p
          ? r
          : new p(`Expected type "${t.name}". ` + r.message, {
              originalError: r,
            })
      );
    }
    return void 0 === r && n(Wi(i), e, new p(`Expected type "${t.name}".`)), r;
  }
  o(!1, "Unexpected input type: " + ne(t));
}
function nr(e, t, n) {
  if (e) {
    if (e.kind === _.VARIABLE) {
      const i = e.name.value;
      if (null == n || void 0 === n[i]) return;
      const r = n[i];
      if (null === r && ct(t)) return;
      return r;
    }
    if (ct(t)) {
      if (e.kind === _.NULL) return;
      return nr(e, t.ofType, n);
    }
    if (e.kind === _.NULL) return null;
    if (st(t)) {
      const i = t.ofType;
      if (e.kind === _.LIST) {
        const t = [];
        for (const r of e.values)
          if (ir(r, n)) {
            if (ct(i)) return;
            t.push(null);
          } else {
            const e = nr(r, i, n);
            if (void 0 === e) return;
            t.push(e);
          }
        return t;
      }
      const r = nr(e, i, n);
      if (void 0 === r) return;
      return [r];
    }
    if (rt(t)) {
      if (e.kind !== _.OBJECT) return;
      const i = Object.create(null),
        r = Ee(e.fields, (e) => e.name.value);
      for (const e of Object.values(t.getFields())) {
        const t = r[e.name];
        if (!t || ir(t.value, n)) {
          if (void 0 !== e.defaultValue) i[e.name] = e.defaultValue;
          else if (ct(e.type)) return;
          continue;
        }
        const o = nr(t.value, e.type, n);
        if (void 0 === o) return;
        i[e.name] = o;
      }
      return i;
    }
    if (ht(t)) {
      let i;
      try {
        i = t.parseLiteral(e, n);
      } catch (e) {
        return;
      }
      if (void 0 === i) return;
      return i;
    }
    o(!1, "Unexpected input type: " + ne(t));
  }
}
function ir(e, t) {
  return e.kind === _.VARIABLE && (null == t || void 0 === t[e.name.value]);
}
function rr(e, t, n, i) {
  const r = [],
    o = null == i ? void 0 : i.maxErrors;
  try {
    const i = (function (e, t, n, i) {
      const r = {};
      for (const o of t) {
        const t = o.variable.name.value,
          s = ti(e, o.type);
        if (!lt(s)) {
          const e = Ce(o.type);
          i(
            new p(
              `Variable "$${t}" expected value of type "${e}" which cannot be used as an input type.`,
              { nodes: o.type }
            )
          );
          continue;
        }
        if (!ar(n, t)) {
          if (o.defaultValue) r[t] = nr(o.defaultValue, s);
          else if (ct(s)) {
            const e = ne(s);
            i(
              new p(
                `Variable "$${t}" of required type "${e}" was not provided.`,
                { nodes: o }
              )
            );
          }
          continue;
        }
        const a = n[t];
        if (null === a && ct(s)) {
          const e = ne(s);
          i(
            new p(
              `Variable "$${t}" of non-null type "${e}" must not be null.`,
              { nodes: o }
            )
          );
        } else
          r[t] = Zi(a, s, (e, n, r) => {
            let s = `Variable "$${t}" got invalid value ` + ne(n);
            e.length > 0 && (s += ` at "${t}${zi(e)}"`),
              i(
                new p(s + "; " + r.message, {
                  nodes: o,
                  originalError: r.originalError,
                })
              );
          });
      }
      return r;
    })(e, t, n, (e) => {
      if (null != o && r.length >= o)
        throw new p(
          "Too many errors processing variables, error limit reached. Execution aborted."
        );
      r.push(e);
    });
    if (0 === r.length) return { coerced: i };
  } catch (e) {
    r.push(e);
  }
  return { errors: r };
}
function or(e, t, n) {
  var i;
  const r = {},
    o = Ee(
      null !== (i = t.arguments) && void 0 !== i ? i : [],
      (e) => e.name.value
    );
  for (const i of e.args) {
    const e = i.name,
      s = i.type,
      a = o[e];
    if (!a) {
      if (void 0 !== i.defaultValue) r[e] = i.defaultValue;
      else if (ct(s))
        throw new p(
          `Argument "${e}" of required type "${ne(s)}" was not provided.`,
          { nodes: t }
        );
      continue;
    }
    const c = a.value;
    let u = c.kind === _.NULL;
    if (c.kind === _.VARIABLE) {
      const t = c.name.value;
      if (null == n || !ar(n, t)) {
        if (void 0 !== i.defaultValue) r[e] = i.defaultValue;
        else if (ct(s))
          throw new p(
            `Argument "${e}" of required type "${ne(
              s
            )}" was provided the variable "$${t}" which was not provided a runtime value.`,
            { nodes: c }
          );
        continue;
      }
      u = null == n[t];
    }
    if (u && ct(s))
      throw new p(
        `Argument "${e}" of non-null type "${ne(s)}" must not be null.`,
        { nodes: c }
      );
    const l = nr(c, s, n);
    if (void 0 === l)
      throw new p(`Argument "${e}" has invalid value ${Ce(c)}.`, { nodes: c });
    r[e] = l;
  }
  return r;
}
function sr(e, t, n) {
  var i;
  const r =
    null === (i = t.directives) || void 0 === i
      ? void 0
      : i.find((t) => t.name.value === e.name);
  if (r) return or(e, r, n);
}
function ar(e, t) {
  return Object.prototype.hasOwnProperty.call(e, t);
}
function cr(e, t, n, i, r) {
  const o = new Map();
  return ur(e, t, n, i, r, o, new Set()), o;
}
function ur(e, t, n, i, r, o, s) {
  for (const c of r.selections)
    switch (c.kind) {
      case _.FIELD: {
        if (!lr(n, c)) continue;
        const e = (a = c).alias ? a.alias.value : a.name.value,
          t = o.get(e);
        void 0 !== t ? t.push(c) : o.set(e, [c]);
        break;
      }
      case _.INLINE_FRAGMENT:
        if (!lr(n, c) || !pr(e, c, i)) continue;
        ur(e, t, n, i, c.selectionSet, o, s);
        break;
      case _.FRAGMENT_SPREAD: {
        const r = c.name.value;
        if (s.has(r) || !lr(n, c)) continue;
        s.add(r);
        const a = t[r];
        if (!a || !pr(e, a, i)) continue;
        ur(e, t, n, i, a.selectionSet, o, s);
        break;
      }
    }
  var a;
}
function lr(e, t) {
  const n = sr(fn, t, e);
  if (!0 === (null == n ? void 0 : n.if)) return !1;
  const i = sr(dn, t, e);
  return !1 !== (null == i ? void 0 : i.if);
}
function pr(e, t, n) {
  const i = t.typeCondition;
  if (!i) return !0;
  const r = ti(e, i);
  return r === n || (!!vt(r) && e.isSubType(r, n));
}
function dr(e) {
  return {
    OperationDefinition(t) {
      if ("subscription" === t.operation) {
        const n = e.getSchema(),
          i = n.getSubscriptionType();
        if (i) {
          const r = t.name ? t.name.value : null,
            o = Object.create(null),
            s = e.getDocument(),
            a = Object.create(null);
          for (const e of s.definitions)
            e.kind === _.FRAGMENT_DEFINITION && (a[e.name.value] = e);
          const c = cr(n, a, o, i, t.selectionSet);
          if (c.size > 1) {
            const t = [...c.values()].slice(1).flat();
            e.reportError(
              new p(
                null != r
                  ? `Subscription "${r}" must select only one top level field.`
                  : "Anonymous Subscription must select only one top level field.",
                { nodes: t }
              )
            );
          }
          for (const t of c.values()) {
            t[0].name.value.startsWith("__") &&
              e.reportError(
                new p(
                  null != r
                    ? `Subscription "${r}" must not select an introspection top level field.`
                    : "Anonymous Subscription must not select an introspection top level field.",
                  { nodes: t }
                )
              );
          }
        }
      }
    },
  };
}
function fr(e, t) {
  const n = new Map();
  for (const i of e) {
    const e = t(i),
      r = n.get(e);
    void 0 === r ? n.set(e, [i]) : r.push(i);
  }
  return n;
}
function hr(e) {
  return {
    DirectiveDefinition(e) {
      var t;
      const i = null !== (t = e.arguments) && void 0 !== t ? t : [];
      return n(`@${e.name.value}`, i);
    },
    InterfaceTypeDefinition: t,
    InterfaceTypeExtension: t,
    ObjectTypeDefinition: t,
    ObjectTypeExtension: t,
  };
  function t(e) {
    var t;
    const i = e.name.value,
      r = null !== (t = e.fields) && void 0 !== t ? t : [];
    for (const e of r) {
      var o;
      n(
        `${i}.${e.name.value}`,
        null !== (o = e.arguments) && void 0 !== o ? o : []
      );
    }
    return !1;
  }
  function n(t, n) {
    const i = fr(n, (e) => e.name.value);
    for (const [n, r] of i)
      r.length > 1 &&
        e.reportError(
          new p(`Argument "${t}(${n}:)" can only be defined once.`, {
            nodes: r.map((e) => e.name),
          })
        );
    return !1;
  }
}
function mr(e) {
  return { Field: t, Directive: t };
  function t(t) {
    var n;
    const i = fr(
      null !== (n = t.arguments) && void 0 !== n ? n : [],
      (e) => e.name.value
    );
    for (const [t, n] of i)
      n.length > 1 &&
        e.reportError(
          new p(`There can be only one argument named "${t}".`, {
            nodes: n.map((e) => e.name),
          })
        );
  }
}
function yr(e) {
  const t = Object.create(null),
    n = e.getSchema();
  return {
    DirectiveDefinition(i) {
      const r = i.name.value;
      if (null == n || !n.getDirective(r))
        return (
          t[r]
            ? e.reportError(
                new p(`There can be only one directive named "@${r}".`, {
                  nodes: [t[r], i.name],
                })
              )
            : (t[r] = i.name),
          !1
        );
      e.reportError(
        new p(
          `Directive "@${r}" already exists in the schema. It cannot be redefined.`,
          { nodes: i.name }
        )
      );
    },
  };
}
function Er(e) {
  const t = Object.create(null),
    n = e.getSchema(),
    i = n ? n.getDirectives() : En;
  for (const e of i) t[e.name] = !e.isRepeatable;
  const r = e.getDocument().definitions;
  for (const e of r)
    e.kind === _.DIRECTIVE_DEFINITION && (t[e.name.value] = !e.repeatable);
  const o = Object.create(null),
    s = Object.create(null);
  return {
    enter(n) {
      if (!("directives" in n) || !n.directives) return;
      let i;
      if (n.kind === _.SCHEMA_DEFINITION || n.kind === _.SCHEMA_EXTENSION)
        i = o;
      else if (di(n) || hi(n)) {
        const e = n.name.value;
        (i = s[e]), void 0 === i && (s[e] = i = Object.create(null));
      } else i = Object.create(null);
      for (const r of n.directives) {
        const n = r.name.value;
        t[n] &&
          (i[n]
            ? e.reportError(
                new p(
                  `The directive "@${n}" can only be used once at this location.`,
                  { nodes: [i[n], r] }
                )
              )
            : (i[n] = r));
      }
    },
  };
}
function vr(e) {
  const t = e.getSchema(),
    n = t ? t.getTypeMap() : Object.create(null),
    i = Object.create(null);
  return { EnumTypeDefinition: r, EnumTypeExtension: r };
  function r(t) {
    var r;
    const o = t.name.value;
    i[o] || (i[o] = Object.create(null));
    const s = null !== (r = t.values) && void 0 !== r ? r : [],
      a = i[o];
    for (const t of s) {
      const i = t.name.value,
        r = n[o];
      nt(r) && r.getValue(i)
        ? e.reportError(
            new p(
              `Enum value "${o}.${i}" already exists in the schema. It cannot also be defined in this type extension.`,
              { nodes: t.name }
            )
          )
        : a[i]
        ? e.reportError(
            new p(`Enum value "${o}.${i}" can only be defined once.`, {
              nodes: [a[i], t.name],
            })
          )
        : (a[i] = t.name);
    }
    return !1;
  }
}
function Tr(e) {
  const t = e.getSchema(),
    n = t ? t.getTypeMap() : Object.create(null),
    i = Object.create(null);
  return {
    InputObjectTypeDefinition: r,
    InputObjectTypeExtension: r,
    InterfaceTypeDefinition: r,
    InterfaceTypeExtension: r,
    ObjectTypeDefinition: r,
    ObjectTypeExtension: r,
  };
  function r(t) {
    var r;
    const o = t.name.value;
    i[o] || (i[o] = Object.create(null));
    const s = null !== (r = t.fields) && void 0 !== r ? r : [],
      a = i[o];
    for (const t of s) {
      const i = t.name.value;
      Nr(n[o], i)
        ? e.reportError(
            new p(
              `Field "${o}.${i}" already exists in the schema. It cannot also be defined in this type extension.`,
              { nodes: t.name }
            )
          )
        : a[i]
        ? e.reportError(
            new p(`Field "${o}.${i}" can only be defined once.`, {
              nodes: [a[i], t.name],
            })
          )
        : (a[i] = t.name);
    }
    return !1;
  }
}
function Nr(e, t) {
  return !!(ze(e) || We(e) || rt(e)) && null != e.getFields()[t];
}
function Ir(e) {
  const t = Object.create(null);
  return {
    OperationDefinition: () => !1,
    FragmentDefinition(n) {
      const i = n.name.value;
      return (
        t[i]
          ? e.reportError(
              new p(`There can be only one fragment named "${i}".`, {
                nodes: [t[i], n.name],
              })
            )
          : (t[i] = n.name),
        !1
      );
    },
  };
}
function gr(e) {
  const t = [];
  let n = Object.create(null);
  return {
    ObjectValue: {
      enter() {
        t.push(n), (n = Object.create(null));
      },
      leave() {
        const e = t.pop();
        e || o(!1), (n = e);
      },
    },
    ObjectField(t) {
      const i = t.name.value;
      n[i]
        ? e.reportError(
            new p(`There can be only one input field named "${i}".`, {
              nodes: [n[i], t.name],
            })
          )
        : (n[i] = t.name);
    },
  };
}
function _r(e) {
  const t = Object.create(null);
  return {
    OperationDefinition(n) {
      const i = n.name;
      return (
        i &&
          (t[i.value]
            ? e.reportError(
                new p(`There can be only one operation named "${i.value}".`, {
                  nodes: [t[i.value], i],
                })
              )
            : (t[i.value] = i)),
        !1
      );
    },
    FragmentDefinition: () => !1,
  };
}
function br(e) {
  const t = e.getSchema(),
    n = Object.create(null),
    i = t
      ? {
          query: t.getQueryType(),
          mutation: t.getMutationType(),
          subscription: t.getSubscriptionType(),
        }
      : {};
  return { SchemaDefinition: r, SchemaExtension: r };
  function r(t) {
    var r;
    const o = null !== (r = t.operationTypes) && void 0 !== r ? r : [];
    for (const t of o) {
      const r = t.operation,
        o = n[r];
      i[r]
        ? e.reportError(
            new p(
              `Type for ${r} already defined in the schema. It cannot be redefined.`,
              { nodes: t }
            )
          )
        : o
        ? e.reportError(
            new p(`There can be only one ${r} type in schema.`, {
              nodes: [o, t],
            })
          )
        : (n[r] = t);
    }
    return !1;
  }
}
function Or(e) {
  const t = Object.create(null),
    n = e.getSchema();
  return {
    ScalarTypeDefinition: i,
    ObjectTypeDefinition: i,
    InterfaceTypeDefinition: i,
    UnionTypeDefinition: i,
    EnumTypeDefinition: i,
    InputObjectTypeDefinition: i,
  };
  function i(i) {
    const r = i.name.value;
    if (null == n || !n.getType(r))
      return (
        t[r]
          ? e.reportError(
              new p(`There can be only one type named "${r}".`, {
                nodes: [t[r], i.name],
              })
            )
          : (t[r] = i.name),
        !1
      );
    e.reportError(
      new p(
        `Type "${r}" already exists in the schema. It cannot also be defined in this type definition.`,
        { nodes: i.name }
      )
    );
  }
}
function Dr(e) {
  return {
    OperationDefinition(t) {
      var n;
      const i = fr(
        null !== (n = t.variableDefinitions) && void 0 !== n ? n : [],
        (e) => e.variable.name.value
      );
      for (const [t, n] of i)
        n.length > 1 &&
          e.reportError(
            new p(`There can be only one variable named "$${t}".`, {
              nodes: n.map((e) => e.variable.name),
            })
          );
    },
  };
}
function Ar(e) {
  return {
    ListValue(t) {
      if (!st(Dt(e.getParentInputType()))) return wr(e, t), !1;
    },
    ObjectValue(t) {
      const n = St(e.getInputType());
      if (!rt(n)) return wr(e, t), !1;
      const i = Ee(t.fields, (e) => e.name.value);
      for (const r of Object.values(n.getFields())) {
        if (!i[r.name] && Kt(r)) {
          const i = ne(r.type);
          e.reportError(
            new p(
              `Field "${n.name}.${r.name}" of required type "${i}" was not provided.`,
              { nodes: t }
            )
          );
        }
      }
    },
    ObjectField(t) {
      const n = St(e.getParentInputType());
      if (!e.getInputType() && rt(n)) {
        const i = be(t.name.value, Object.keys(n.getFields()));
        e.reportError(
          new p(
            `Field "${t.name.value}" is not defined by type "${n.name}".` +
              me(i),
            { nodes: t }
          )
        );
      }
    },
    NullValue(t) {
      const n = e.getInputType();
      ct(n) &&
        e.reportError(
          new p(`Expected value of type "${ne(n)}", found ${Ce(t)}.`, {
            nodes: t,
          })
        );
    },
    EnumValue: (t) => wr(e, t),
    IntValue: (t) => wr(e, t),
    FloatValue: (t) => wr(e, t),
    StringValue: (t) => wr(e, t),
    BooleanValue: (t) => wr(e, t),
  };
}
function wr(e, t) {
  const n = e.getInputType();
  if (!n) return;
  const i = St(n);
  if (ht(i))
    try {
      if (void 0 === i.parseLiteral(t, void 0)) {
        const i = ne(n);
        e.reportError(
          new p(`Expected value of type "${i}", found ${Ce(t)}.`, { nodes: t })
        );
      }
    } catch (i) {
      const r = ne(n);
      i instanceof p
        ? e.reportError(i)
        : e.reportError(
            new p(
              `Expected value of type "${r}", found ${Ce(t)}; ` + i.message,
              { nodes: t, originalError: i }
            )
          );
    }
  else {
    const i = ne(n);
    e.reportError(
      new p(`Expected value of type "${i}", found ${Ce(t)}.`, { nodes: t })
    );
  }
}
function Sr(e) {
  return {
    VariableDefinition(t) {
      const n = ti(e.getSchema(), t.type);
      if (void 0 !== n && !lt(n)) {
        const n = t.variable.name.value,
          i = Ce(t.type);
        e.reportError(
          new p(`Variable "$${n}" cannot be non-input type "${i}".`, {
            nodes: t.type,
          })
        );
      }
    },
  };
}
function Rr(e) {
  let t = Object.create(null);
  return {
    OperationDefinition: {
      enter() {
        t = Object.create(null);
      },
      leave(n) {
        const i = e.getRecursiveVariableUsages(n);
        for (const { node: n, type: r, defaultValue: o } of i) {
          const i = n.name.value,
            s = t[i];
          if (s && r) {
            const t = e.getSchema(),
              a = ti(t, s.type);
            if (a && !$r(t, a, s.defaultValue, r, o)) {
              const t = ne(a),
                o = ne(r);
              e.reportError(
                new p(
                  `Variable "$${i}" of type "${t}" used in position expecting type "${o}".`,
                  { nodes: [s, n] }
                )
              );
            }
          }
        }
      },
    },
    VariableDefinition(e) {
      t[e.variable.name.value] = e;
    },
  };
}
function $r(e, t, n, i, r) {
  if (ct(i) && !ct(t)) {
    if (!(null != n && n.kind !== _.NULL) && !(void 0 !== r)) return !1;
    return zt(e, t, i.ofType);
  }
  return zt(e, t, i);
}
const xr = Object.freeze([
    mi,
    _r,
    bi,
    dr,
    gi,
    Ei,
    Sr,
    Xi,
    yi,
    Ir,
    Ii,
    wi,
    Gi,
    Di,
    Dr,
    Ai,
    Si,
    Ni,
    Er,
    vi,
    mr,
    Ar,
    Ji,
    Rr,
    xi,
    gr,
  ]),
  kr = Object.freeze([
    Oi,
    br,
    Or,
    vr,
    Tr,
    hr,
    yr,
    gi,
    Ni,
    Er,
    Yi,
    Ti,
    mr,
    gr,
    qi,
  ]);
class Lr {
  constructor(e, t) {
    (this._ast = e),
      (this._fragments = void 0),
      (this._fragmentSpreads = new Map()),
      (this._recursivelyReferencedFragments = new Map()),
      (this._onError = t);
  }
  get [Symbol.toStringTag]() {
    return "ASTValidationContext";
  }
  reportError(e) {
    this._onError(e);
  }
  getDocument() {
    return this._ast;
  }
  getFragment(e) {
    let t;
    if (this._fragments) t = this._fragments;
    else {
      t = Object.create(null);
      for (const e of this.getDocument().definitions)
        e.kind === _.FRAGMENT_DEFINITION && (t[e.name.value] = e);
      this._fragments = t;
    }
    return t[e];
  }
  getFragmentSpreads(e) {
    let t = this._fragmentSpreads.get(e);
    if (!t) {
      t = [];
      const n = [e];
      let i;
      for (; (i = n.pop()); )
        for (const e of i.selections)
          e.kind === _.FRAGMENT_SPREAD
            ? t.push(e)
            : e.selectionSet && n.push(e.selectionSet);
      this._fragmentSpreads.set(e, t);
    }
    return t;
  }
  getRecursivelyReferencedFragments(e) {
    let t = this._recursivelyReferencedFragments.get(e);
    if (!t) {
      t = [];
      const n = Object.create(null),
        i = [e.selectionSet];
      let r;
      for (; (r = i.pop()); )
        for (const e of this.getFragmentSpreads(r)) {
          const r = e.name.value;
          if (!0 !== n[r]) {
            n[r] = !0;
            const e = this.getFragment(r);
            e && (t.push(e), i.push(e.selectionSet));
          }
        }
      this._recursivelyReferencedFragments.set(e, t);
    }
    return t;
  }
}
class Fr extends Lr {
  constructor(e, t, n) {
    super(e, n), (this._schema = t);
  }
  get [Symbol.toStringTag]() {
    return "SDLValidationContext";
  }
  getSchema() {
    return this._schema;
  }
}
class Cr extends Lr {
  constructor(e, t, n, i) {
    super(t, i),
      (this._schema = e),
      (this._typeInfo = n),
      (this._variableUsages = new Map()),
      (this._recursiveVariableUsages = new Map());
  }
  get [Symbol.toStringTag]() {
    return "ValidationContext";
  }
  getSchema() {
    return this._schema;
  }
  getVariableUsages(e) {
    let t = this._variableUsages.get(e);
    if (!t) {
      const n = [],
        i = new ni(this._schema);
      xe(
        e,
        ri(i, {
          VariableDefinition: () => !1,
          Variable(e) {
            n.push({
              node: e,
              type: i.getInputType(),
              defaultValue: i.getDefaultValue(),
            });
          },
        })
      ),
        (t = n),
        this._variableUsages.set(e, t);
    }
    return t;
  }
  getRecursiveVariableUsages(e) {
    let t = this._recursiveVariableUsages.get(e);
    if (!t) {
      t = this.getVariableUsages(e);
      for (const n of this.getRecursivelyReferencedFragments(e))
        t = t.concat(this.getVariableUsages(n));
      this._recursiveVariableUsages.set(e, t);
    }
    return t;
  }
  getType() {
    return this._typeInfo.getType();
  }
  getParentType() {
    return this._typeInfo.getParentType();
  }
  getInputType() {
    return this._typeInfo.getInputType();
  }
  getParentInputType() {
    return this._typeInfo.getParentInputType();
  }
  getFieldDef() {
    return this._typeInfo.getFieldDef();
  }
  getDirective() {
    return this._typeInfo.getDirective();
  }
  getArgument() {
    return this._typeInfo.getArgument();
  }
  getEnumValue() {
    return this._typeInfo.getEnumValue();
  }
}
function Vr(e, t, i = xr, r, o = new ni(e)) {
  var s;
  const a =
    null !== (s = null == r ? void 0 : r.maxErrors) && void 0 !== s ? s : 100;
  t || n(!1, "Must provide document."), Pn(e);
  const c = Object.freeze({}),
    u = [],
    l = new Cr(e, t, o, (e) => {
      if (u.length >= a)
        throw (
          (u.push(
            new p(
              "Too many validation errors, error limit reached. Validation aborted."
            )
          ),
          c)
        );
      u.push(e);
    }),
    d = ke(i.map((e) => e(l)));
  try {
    xe(t, ri(o, d));
  } catch (e) {
    if (e !== c) throw e;
  }
  return u;
}
function Ur(e, t, n = kr) {
  const i = [],
    r = new Fr(e, t, (e) => {
      i.push(e);
    });
  return xe(e, ke(n.map((e) => e(r)))), i;
}
class Mr extends Error {
  constructor(e) {
    super("Unexpected error value: " + ne(e)),
      (this.name = "NonErrorThrown"),
      (this.thrownValue = e);
  }
}
function jr(e, t, n) {
  var i;
  const r = (o = e) instanceof Error ? o : new Mr(o);
  var o, s;
  return (
    (s = r),
    Array.isArray(s.path)
      ? r
      : new p(r.message, {
          nodes: null !== (i = r.nodes) && void 0 !== i ? i : t,
          source: r.source,
          positions: r.positions,
          path: n,
          originalError: r,
        })
  );
}
const Pr = (function (e) {
  let t;
  return function (n, i, r) {
    void 0 === t && (t = new WeakMap());
    let o = t.get(n);
    void 0 === o && ((o = new WeakMap()), t.set(n, o));
    let s = o.get(i);
    void 0 === s && ((s = new WeakMap()), o.set(i, s));
    let a = s.get(r);
    return void 0 === a && ((a = e(n, i, r)), s.set(r, a)), a;
  };
})((e, t, n) =>
  (function (e, t, n, i, r) {
    const o = new Map(),
      s = new Set();
    for (const a of r) a.selectionSet && ur(e, t, n, i, a.selectionSet, o, s);
    return o;
  })(e.schema, e.fragments, e.variableValues, t, n)
);
function Br(e) {
  arguments.length < 2 ||
    n(
      !1,
      "graphql@16 dropped long-deprecated support for positional arguments, please pass an object instead."
    );
  const { schema: t, document: r, variableValues: o, rootValue: s } = e;
  Qr(t, r, o);
  const a = Jr(e);
  if (!("schema" in a)) return { errors: a };
  try {
    const { operation: e } = a,
      t = (function (e, t, n) {
        const r = e.schema.getRootType(t.operation);
        if (null == r)
          throw new p(
            `Schema is not configured to execute ${t.operation} operation.`,
            { nodes: t }
          );
        const o = cr(
            e.schema,
            e.fragments,
            e.variableValues,
            r,
            t.selectionSet
          ),
          s = void 0;
        switch (t.operation) {
          case I.QUERY:
            return qr(e, r, n, s, o);
          case I.MUTATION:
            return (function (e, t, n, r, o) {
              return (function (e, t, n) {
                let r = n;
                for (const n of e) r = i(r) ? r.then((e) => t(e, n)) : t(r, n);
                return r;
              })(
                o.entries(),
                (o, [s, a]) => {
                  const c = Hi(r, s, t.name),
                    u = Kr(e, t, n, a, c);
                  return void 0 === u
                    ? o
                    : i(u)
                    ? u.then((e) => ((o[s] = e), o))
                    : ((o[s] = u), o);
                },
                Object.create(null)
              );
            })(e, r, n, s, o);
          case I.SUBSCRIPTION:
            return qr(e, r, n, s, o);
        }
      })(a, e, s);
    return i(t)
      ? t.then(
          (e) => Yr(e, a.errors),
          (e) => (a.errors.push(e), Yr(null, a.errors))
        )
      : Yr(t, a.errors);
  } catch (e) {
    return a.errors.push(e), Yr(null, a.errors);
  }
}
function Gr(e) {
  const t = Br(e);
  if (i(t))
    throw new Error("GraphQL execution failed to complete synchronously.");
  return t;
}
function Yr(e, t) {
  return 0 === t.length ? { data: e } : { errors: t, data: e };
}
function Qr(e, t, i) {
  t || n(!1, "Must provide document."),
    Pn(e),
    null == i ||
      r(i) ||
      n(
        !1,
        "Variables must be provided as an Object where each property is a variable value. Perhaps look to see if an unparsed JSON string was provided."
      );
}
function Jr(e) {
  var t, n;
  const {
    schema: i,
    document: r,
    rootValue: o,
    contextValue: s,
    variableValues: a,
    operationName: c,
    fieldResolver: u,
    typeResolver: l,
    subscribeFieldResolver: d,
  } = e;
  let f;
  const h = Object.create(null);
  for (const e of r.definitions)
    switch (e.kind) {
      case _.OPERATION_DEFINITION:
        if (null == c) {
          if (void 0 !== f)
            return [
              new p(
                "Must provide operation name if query contains multiple operations."
              ),
            ];
          f = e;
        } else
          (null === (t = e.name) || void 0 === t ? void 0 : t.value) === c &&
            (f = e);
        break;
      case _.FRAGMENT_DEFINITION:
        h[e.name.value] = e;
    }
  if (!f)
    return null != c
      ? [new p(`Unknown operation named "${c}".`)]
      : [new p("Must provide an operation.")];
  const m = rr(
    i,
    null !== (n = f.variableDefinitions) && void 0 !== n ? n : [],
    null != a ? a : {},
    { maxErrors: 50 }
  );
  return m.errors
    ? m.errors
    : {
        schema: i,
        fragments: h,
        rootValue: o,
        contextValue: s,
        operation: f,
        variableValues: m.coerced,
        fieldResolver: null != u ? u : no,
        typeResolver: null != l ? l : to,
        subscribeFieldResolver: null != d ? d : no,
        errors: [],
      };
}
function qr(e, t, n, r, o) {
  const s = Object.create(null);
  let a = !1;
  for (const [c, u] of o.entries()) {
    const o = Kr(e, t, n, u, Hi(r, c, t.name));
    void 0 !== o && ((s[c] = o), i(o) && (a = !0));
  }
  return a
    ? ((c = s),
      Promise.all(Object.values(c)).then((e) => {
        const t = Object.create(null);
        for (const [n, i] of Object.keys(c).entries()) t[i] = e[n];
        return t;
      }))
    : s;
  var c;
}
function Kr(e, t, n, r, o) {
  var s;
  const a = io(e.schema, t, r[0]);
  if (!a) return;
  const c = a.type,
    u = null !== (s = a.resolve) && void 0 !== s ? s : e.fieldResolver,
    l = Xr(e, a, r, t, o);
  try {
    const t = or(a, r[0], e.variableValues),
      s = u(n, t, e.contextValue, l);
    let p;
    return (
      (p = i(s) ? s.then((t) => Hr(e, c, r, l, o, t)) : Hr(e, c, r, l, o, s)),
      i(p) ? p.then(void 0, (t) => zr(jr(t, r, Wi(o)), c, e)) : p
    );
  } catch (t) {
    return zr(jr(t, r, Wi(o)), c, e);
  }
}
function Xr(e, t, n, i, r) {
  return {
    fieldName: t.name,
    fieldNodes: n,
    returnType: t.type,
    parentType: i,
    path: r,
    schema: e.schema,
    fragments: e.fragments,
    rootValue: e.rootValue,
    operation: e.operation,
    variableValues: e.variableValues,
  };
}
function zr(e, t, n) {
  if (ct(t)) throw e;
  return n.errors.push(e), null;
}
function Hr(e, t, n, r, s, a) {
  if (a instanceof Error) throw a;
  if (ct(t)) {
    const i = Hr(e, t.ofType, n, r, s, a);
    if (null === i)
      throw new Error(
        `Cannot return null for non-nullable field ${r.parentType.name}.${r.fieldName}.`
      );
    return i;
  }
  return null == a
    ? null
    : st(t)
    ? (function (e, t, n, r, o, s) {
        if (!Tn(s))
          throw new p(
            `Expected Iterable, but did not find one for field "${r.parentType.name}.${r.fieldName}".`
          );
        const a = t.ofType;
        let c = !1;
        const u = Array.from(s, (t, s) => {
          const u = Hi(o, s, void 0);
          try {
            let o;
            return (
              (o = i(t)
                ? t.then((t) => Hr(e, a, n, r, u, t))
                : Hr(e, a, n, r, u, t)),
              i(o)
                ? ((c = !0), o.then(void 0, (t) => zr(jr(t, n, Wi(u)), a, e)))
                : o
            );
          } catch (t) {
            return zr(jr(t, n, Wi(u)), a, e);
          }
        });
        return c ? Promise.all(u) : u;
      })(e, t, n, r, s, a)
    : ht(t)
    ? (function (e, t) {
        const n = e.serialize(t);
        if (null == n)
          throw new Error(
            `Expected \`${ne(e)}.serialize(${ne(
              t
            )})\` to return non-nullable value, returned: ${ne(n)}`
          );
        return n;
      })(t, a)
    : vt(t)
    ? (function (e, t, n, r, o, s) {
        var a;
        const c =
            null !== (a = t.resolveType) && void 0 !== a ? a : e.typeResolver,
          u = e.contextValue,
          l = c(s, u, r, t);
        if (i(l)) return l.then((i) => Zr(e, Wr(i, e, t, n, r, s), n, r, o, s));
        return Zr(e, Wr(l, e, t, n, r, s), n, r, o, s);
      })(e, t, n, r, s, a)
    : ze(t)
    ? Zr(e, t, n, r, s, a)
    : void o(!1, "Cannot complete value of unexpected output type: " + ne(t));
}
function Wr(e, t, n, i, r, o) {
  if (null == e)
    throw new p(
      `Abstract type "${n.name}" must resolve to an Object type at runtime for field "${r.parentType.name}.${r.fieldName}". Either the "${n.name}" type should provide a "resolveType" function or each possible type should provide an "isTypeOf" function.`,
      i
    );
  if (ze(e))
    throw new p(
      "Support for returning GraphQLObjectType from resolveType was removed in graphql-js@16.0.0 please return type name instead."
    );
  if ("string" != typeof e)
    throw new p(
      `Abstract type "${
        n.name
      }" must resolve to an Object type at runtime for field "${
        r.parentType.name
      }.${r.fieldName}" with value ${ne(o)}, received "${ne(e)}".`
    );
  const s = t.schema.getType(e);
  if (null == s)
    throw new p(
      `Abstract type "${n.name}" was resolved to a type "${e}" that does not exist inside the schema.`,
      { nodes: i }
    );
  if (!ze(s))
    throw new p(
      `Abstract type "${n.name}" was resolved to a non-object type "${e}".`,
      { nodes: i }
    );
  if (!t.schema.isSubType(n, s))
    throw new p(
      `Runtime Object type "${s.name}" is not a possible type for "${n.name}".`,
      { nodes: i }
    );
  return s;
}
function Zr(e, t, n, r, o, s) {
  const a = Pr(e, t, n);
  if (t.isTypeOf) {
    const c = t.isTypeOf(s, e.contextValue, r);
    if (i(c))
      return c.then((i) => {
        if (!i) throw eo(t, s, n);
        return qr(e, t, s, o, a);
      });
    if (!c) throw eo(t, s, n);
  }
  return qr(e, t, s, o, a);
}
function eo(e, t, n) {
  return new p(`Expected value of type "${e.name}" but got: ${ne(t)}.`, {
    nodes: n,
  });
}
const to = function (e, t, n, o) {
    if (r(e) && "string" == typeof e.__typename) return e.__typename;
    const s = n.schema.getPossibleTypes(o),
      a = [];
    for (let r = 0; r < s.length; r++) {
      const o = s[r];
      if (o.isTypeOf) {
        const s = o.isTypeOf(e, t, n);
        if (i(s)) a[r] = s;
        else if (s) return o.name;
      }
    }
    return a.length
      ? Promise.all(a).then((e) => {
          for (let t = 0; t < e.length; t++) if (e[t]) return s[t].name;
        })
      : void 0;
  },
  no = function (e, t, n, i) {
    if (r(e) || "function" == typeof e) {
      const r = e[i.fieldName];
      return "function" == typeof r ? e[i.fieldName](t, n, i) : r;
    }
  };
function io(e, t, n) {
  const i = n.name.value;
  return i === $n.name && e.getQueryType() === t
    ? $n
    : i === xn.name && e.getQueryType() === t
    ? xn
    : i === kn.name
    ? kn
    : t.getFields()[i];
}
function ro(e) {
  return new Promise((t) => t(so(e)));
}
function oo(e) {
  const t = so(e);
  if (i(t))
    throw new Error("GraphQL execution failed to complete synchronously.");
  return t;
}
function so(e) {
  arguments.length < 2 ||
    n(
      !1,
      "graphql@16 dropped long-deprecated support for positional arguments, please pass an object instead."
    );
  const {
      schema: t,
      source: i,
      rootValue: r,
      contextValue: o,
      variableValues: s,
      operationName: a,
      fieldResolver: c,
      typeResolver: u,
    } = e,
    l = jn(t);
  if (l.length > 0) return { errors: l };
  let p;
  try {
    p = ae(i);
  } catch (e) {
    return { errors: [e] };
  }
  const d = Vr(t, p);
  return d.length > 0
    ? { errors: d }
    : Br({
        schema: t,
        document: p,
        rootValue: r,
        contextValue: o,
        variableValues: s,
        operationName: a,
        fieldResolver: c,
        typeResolver: u,
      });
}
function ao(e) {
  return "function" == typeof (null == e ? void 0 : e[Symbol.asyncIterator]);
}
async function co(e) {
  arguments.length < 2 ||
    n(
      !1,
      "graphql@16 dropped long-deprecated support for positional arguments, please pass an object instead."
    );
  const t = await uo(e);
  if (!ao(t)) return t;
  return (function (e, t) {
    const n = e[Symbol.asyncIterator]();
    async function i(e) {
      if (e.done) return e;
      try {
        return { value: await t(e.value), done: !1 };
      } catch (e) {
        if ("function" == typeof n.return)
          try {
            await n.return();
          } catch (e) {}
        throw e;
      }
    }
    return {
      next: async () => i(await n.next()),
      return: async () =>
        "function" == typeof n.return
          ? i(await n.return())
          : { value: void 0, done: !0 },
      async throw(e) {
        if ("function" == typeof n.throw) return i(await n.throw(e));
        throw e;
      },
      [Symbol.asyncIterator]() {
        return this;
      },
    };
  })(t, (t) => Br({ ...e, rootValue: t }));
}
async function uo(...e) {
  const t = (function (e) {
      const t = e[0];
      return t && "document" in t
        ? t
        : {
            schema: t,
            document: e[1],
            rootValue: e[2],
            contextValue: e[3],
            variableValues: e[4],
            operationName: e[5],
            subscribeFieldResolver: e[6],
          };
    })(e),
    { schema: n, document: i, variableValues: r } = t;
  Qr(n, i, r);
  const o = Jr(t);
  if (!("schema" in o)) return { errors: o };
  try {
    const e = await (async function (e) {
      const {
          schema: t,
          fragments: n,
          operation: i,
          variableValues: r,
          rootValue: o,
        } = e,
        s = t.getSubscriptionType();
      if (null == s)
        throw new p(
          "Schema is not configured to execute subscription operation.",
          { nodes: i }
        );
      const a = cr(t, n, r, s, i.selectionSet),
        [c, u] = [...a.entries()][0],
        l = io(t, s, u[0]);
      if (!l) {
        const e = u[0].name.value;
        throw new p(`The subscription field "${e}" is not defined.`, {
          nodes: u,
        });
      }
      const d = Hi(void 0, c, s.name),
        f = Xr(e, l, u, s, d);
      try {
        var h;
        const t = or(l, u[0], r),
          n = e.contextValue,
          i =
            null !== (h = l.subscribe) && void 0 !== h
              ? h
              : e.subscribeFieldResolver,
          s = await i(o, t, n, f);
        if (s instanceof Error) throw s;
        return s;
      } catch (e) {
        throw jr(e, u, Wi(d));
      }
    })(o);
    if (!ao(e))
      throw new Error(
        `Subscription field must return Async Iterable. Received: ${ne(e)}.`
      );
    return e;
  } catch (e) {
    if (e instanceof p) return { errors: [e] };
    throw e;
  }
}
function lo(e) {
  return {
    Field(t) {
      const n = e.getFieldDef(),
        i = null == n ? void 0 : n.deprecationReason;
      if (n && null != i) {
        const r = e.getParentType();
        null != r || o(!1),
          e.reportError(
            new p(`The field ${r.name}.${n.name} is deprecated. ${i}`, {
              nodes: t,
            })
          );
      }
    },
    Argument(t) {
      const n = e.getArgument(),
        i = null == n ? void 0 : n.deprecationReason;
      if (n && null != i) {
        const r = e.getDirective();
        if (null != r)
          e.reportError(
            new p(
              `Directive "@${r.name}" argument "${n.name}" is deprecated. ${i}`,
              { nodes: t }
            )
          );
        else {
          const r = e.getParentType(),
            s = e.getFieldDef();
          (null != r && null != s) || o(!1),
            e.reportError(
              new p(
                `Field "${r.name}.${s.name}" argument "${n.name}" is deprecated. ${i}`,
                { nodes: t }
              )
            );
        }
      }
    },
    ObjectField(t) {
      const n = St(e.getParentInputType());
      if (rt(n)) {
        const i = n.getFields()[t.name.value],
          r = null == i ? void 0 : i.deprecationReason;
        null != r &&
          e.reportError(
            new p(`The input field ${n.name}.${i.name} is deprecated. ${r}`, {
              nodes: t,
            })
          );
      }
    },
    EnumValue(t) {
      const n = e.getEnumValue(),
        i = null == n ? void 0 : n.deprecationReason;
      if (n && null != i) {
        const r = St(e.getInputType());
        null != r || o(!1),
          e.reportError(
            new p(`The enum value "${r.name}.${n.name}" is deprecated. ${i}`, {
              nodes: t,
            })
          );
      }
    },
  };
}
function po(e) {
  return {
    Field(t) {
      const n = St(e.getType());
      n &&
        Fn(n) &&
        e.reportError(
          new p(
            `GraphQL introspection has been disabled, but the requested query contained the field "${t.name.value}".`,
            { nodes: t }
          )
        );
    },
  };
}
function fo(e) {
  const t = {
      descriptions: !0,
      specifiedByUrl: !1,
      directiveIsRepeatable: !1,
      schemaDescription: !1,
      inputValueDeprecation: !1,
      ...e,
    },
    n = t.descriptions ? "description" : "",
    i = t.specifiedByUrl ? "specifiedByURL" : "",
    r = t.directiveIsRepeatable ? "isRepeatable" : "";
  function o(e) {
    return t.inputValueDeprecation ? e : "";
  }
  return `\n    query IntrospectionQuery {\n      __schema {\n        ${
    t.schemaDescription ? n : ""
  }\n        queryType { name }\n        mutationType { name }\n        subscriptionType { name }\n        types {\n          ...FullType\n        }\n        directives {\n          name\n          ${n}\n          ${r}\n          locations\n          args${o(
    "(includeDeprecated: true)"
  )} {\n            ...InputValue\n          }\n        }\n      }\n    }\n\n    fragment FullType on __Type {\n      kind\n      name\n      ${n}\n      ${i}\n      fields(includeDeprecated: true) {\n        name\n        ${n}\n        args${o(
    "(includeDeprecated: true)"
  )} {\n          ...InputValue\n        }\n        type {\n          ...TypeRef\n        }\n        isDeprecated\n        deprecationReason\n      }\n      inputFields${o(
    "(includeDeprecated: true)"
  )} {\n        ...InputValue\n      }\n      interfaces {\n        ...TypeRef\n      }\n      enumValues(includeDeprecated: true) {\n        name\n        ${n}\n        isDeprecated\n        deprecationReason\n      }\n      possibleTypes {\n        ...TypeRef\n      }\n    }\n\n    fragment InputValue on __InputValue {\n      name\n      ${n}\n      type { ...TypeRef }\n      defaultValue\n      ${o(
    "isDeprecated"
  )}\n      ${o(
    "deprecationReason"
  )}\n    }\n\n    fragment TypeRef on __Type {\n      kind\n      name\n      ofType {\n        kind\n        name\n        ofType {\n          kind\n          name\n          ofType {\n            kind\n            name\n            ofType {\n              kind\n              name\n              ofType {\n                kind\n                name\n                ofType {\n                  kind\n                  name\n                  ofType {\n                    kind\n                    name\n                  }\n                }\n              }\n            }\n          }\n        }\n      }\n    }\n  `;
}
function ho(e, t) {
  let n = null;
  for (const r of e.definitions) {
    var i;
    if (r.kind === _.OPERATION_DEFINITION)
      if (null == t) {
        if (n) return null;
        n = r;
      } else if (
        (null === (i = r.name) || void 0 === i ? void 0 : i.value) === t
      )
        return r;
  }
  return n;
}
function mo(e, t) {
  if ("query" === t.operation) {
    const n = e.getQueryType();
    if (!n)
      throw new p("Schema does not define the required query root type.", {
        nodes: t,
      });
    return n;
  }
  if ("mutation" === t.operation) {
    const n = e.getMutationType();
    if (!n)
      throw new p("Schema is not configured for mutations.", { nodes: t });
    return n;
  }
  if ("subscription" === t.operation) {
    const n = e.getSubscriptionType();
    if (!n)
      throw new p("Schema is not configured for subscriptions.", { nodes: t });
    return n;
  }
  throw new p("Can only have query, mutation and subscription operations.", {
    nodes: t,
  });
}
function yo(e, t) {
  const n = Gr({
    schema: e,
    document: ae(
      fo({
        specifiedByUrl: !0,
        directiveIsRepeatable: !0,
        schemaDescription: !0,
        inputValueDeprecation: !0,
        ...t,
      })
    ),
  });
  return (!n.errors && n.data) || o(!1), n.data;
}
function Eo(e, t) {
  (r(e) && r(e.__schema)) ||
    n(
      !1,
      `Invalid or incomplete introspection result. Ensure that you are passing "data" property of introspection response and no "errors" was returned alongside: ${ne(
        e
      )}.`
    );
  const i = e.__schema,
    o = ve(
      i.types,
      (e) => e.name,
      (e) =>
        (function (e) {
          if (null != e && null != e.name && null != e.kind)
            switch (e.kind) {
              case Sn.SCALAR:
                return new xt({
                  name: (i = e).name,
                  description: i.description,
                  specifiedByURL: i.specifiedByURL,
                });
              case Sn.OBJECT:
                return new kt({
                  name: (n = e).name,
                  description: n.description,
                  interfaces: () => h(n),
                  fields: () => m(n),
                });
              case Sn.INTERFACE:
                return new Pt({
                  name: (t = e).name,
                  description: t.description,
                  interfaces: () => h(t),
                  fields: () => m(t),
                });
              case Sn.UNION:
                return (function (e) {
                  if (!e.possibleTypes) {
                    const t = ne(e);
                    throw new Error(
                      `Introspection result missing possibleTypes: ${t}.`
                    );
                  }
                  return new Bt({
                    name: e.name,
                    description: e.description,
                    types: () => e.possibleTypes.map(d),
                  });
                })(e);
              case Sn.ENUM:
                return (function (e) {
                  if (!e.enumValues) {
                    const t = ne(e);
                    throw new Error(
                      `Introspection result missing enumValues: ${t}.`
                    );
                  }
                  return new Yt({
                    name: e.name,
                    description: e.description,
                    values: ve(
                      e.enumValues,
                      (e) => e.name,
                      (e) => ({
                        description: e.description,
                        deprecationReason: e.deprecationReason,
                      })
                    ),
                  });
                })(e);
              case Sn.INPUT_OBJECT:
                return (function (e) {
                  if (!e.inputFields) {
                    const t = ne(e);
                    throw new Error(
                      `Introspection result missing inputFields: ${t}.`
                    );
                  }
                  return new Jt({
                    name: e.name,
                    description: e.description,
                    fields: () => E(e.inputFields),
                  });
                })(e);
            }
          var t;
          var n;
          var i;
          const r = ne(e);
          throw new Error(
            `Invalid or incomplete introspection result. Ensure that a full introspection query is used in order to build a client schema: ${r}.`
          );
        })(e)
    );
  for (const e of [...sn, ...Ln]) o[e.name] && (o[e.name] = e);
  const s = i.queryType ? d(i.queryType) : null,
    a = i.mutationType ? d(i.mutationType) : null,
    c = i.subscriptionType ? d(i.subscriptionType) : null,
    u = i.directives
      ? i.directives.map(function (e) {
          if (!e.args) {
            const t = ne(e);
            throw new Error(
              `Introspection result missing directive args: ${t}.`
            );
          }
          if (!e.locations) {
            const t = ne(e);
            throw new Error(
              `Introspection result missing directive locations: ${t}.`
            );
          }
          return new pn({
            name: e.name,
            description: e.description,
            isRepeatable: e.isRepeatable,
            locations: e.locations.slice(),
            args: E(e.args),
          });
        })
      : [];
  return new Un({
    description: i.description,
    query: s,
    mutation: a,
    subscription: c,
    types: Object.values(o),
    directives: u,
    assumeValid: null == t ? void 0 : t.assumeValid,
  });
  function l(e) {
    if (e.kind === Sn.LIST) {
      const t = e.ofType;
      if (!t)
        throw new Error("Decorated type deeper than introspection query.");
      return new Nt(l(t));
    }
    if (e.kind === Sn.NON_NULL) {
      const t = e.ofType;
      if (!t)
        throw new Error("Decorated type deeper than introspection query.");
      const n = l(t);
      return new It(Ot(n));
    }
    return p(e);
  }
  function p(e) {
    const t = e.name;
    if (!t) throw new Error(`Unknown type reference: ${ne(e)}.`);
    const n = o[t];
    if (!n)
      throw new Error(
        `Invalid or incomplete schema, unknown type: ${t}. Ensure that a full introspection query is used in order to build a client schema.`
      );
    return n;
  }
  function d(e) {
    return He(p(e));
  }
  function f(e) {
    return Ze(p(e));
  }
  function h(e) {
    if (null === e.interfaces && e.kind === Sn.INTERFACE) return [];
    if (!e.interfaces) {
      const t = ne(e);
      throw new Error(`Introspection result missing interfaces: ${t}.`);
    }
    return e.interfaces.map(f);
  }
  function m(e) {
    if (!e.fields)
      throw new Error(`Introspection result missing fields: ${ne(e)}.`);
    return ve(e.fields, (e) => e.name, y);
  }
  function y(e) {
    const t = l(e.type);
    if (!dt(t)) {
      const e = ne(t);
      throw new Error(
        `Introspection must provide output type for fields, but received: ${e}.`
      );
    }
    if (!e.args) {
      const t = ne(e);
      throw new Error(`Introspection result missing field args: ${t}.`);
    }
    return {
      description: e.description,
      deprecationReason: e.deprecationReason,
      type: t,
      args: E(e.args),
    };
  }
  function E(e) {
    return ve(e, (e) => e.name, v);
  }
  function v(e) {
    const t = l(e.type);
    if (!lt(t)) {
      const e = ne(t);
      throw new Error(
        `Introspection must provide input type for arguments, but received: ${e}.`
      );
    }
    const n = null != e.defaultValue ? nr(ce(e.defaultValue), t) : void 0;
    return {
      description: e.description,
      type: t,
      defaultValue: n,
      deprecationReason: e.deprecationReason,
    };
  }
}
function vo(e, t, i) {
  Vn(e),
    (null != t && t.kind === _.DOCUMENT) ||
      n(!1, "Must provide valid Document AST."),
    !0 !== (null == i ? void 0 : i.assumeValid) &&
      !0 !== (null == i ? void 0 : i.assumeValidSDL) &&
      (function (e, t) {
        const n = Ur(e, t);
        if (0 !== n.length)
          throw new Error(n.map((e) => e.message).join("\n\n"));
      })(t, e);
  const r = e.toConfig(),
    o = To(r, t, i);
  return r === o ? e : new Un(o);
}
function To(e, t, n) {
  var i, r, s, a;
  const c = [],
    u = Object.create(null),
    l = [];
  let p;
  const d = [];
  for (const e of t.definitions)
    if (e.kind === _.SCHEMA_DEFINITION) p = e;
    else if (e.kind === _.SCHEMA_EXTENSION) d.push(e);
    else if (di(e)) c.push(e);
    else if (hi(e)) {
      const t = e.name.value,
        n = u[t];
      u[t] = n ? n.concat([e]) : [e];
    } else e.kind === _.DIRECTIVE_DEFINITION && l.push(e);
  if (
    0 === Object.keys(u).length &&
    0 === c.length &&
    0 === l.length &&
    0 === d.length &&
    null == p
  )
    return e;
  const f = Object.create(null);
  for (const t of e.types) f[t.name] = v(t);
  for (const e of c) {
    var h;
    const t = e.name.value;
    f[t] = null !== (h = No[t]) && void 0 !== h ? h : $(e);
  }
  const m = {
    query: e.query && E(e.query),
    mutation: e.mutation && E(e.mutation),
    subscription: e.subscription && E(e.subscription),
    ...(p && I([p])),
    ...I(d),
  };
  return {
    description:
      null === (i = p) ||
      void 0 === i ||
      null === (r = i.description) ||
      void 0 === r
        ? void 0
        : r.value,
    ...m,
    types: Object.values(f),
    directives: [
      ...e.directives.map(function (e) {
        const t = e.toConfig();
        return new pn({ ...t, args: Te(t.args, N) });
      }),
      ...l.map(function (e) {
        var t;
        return new pn({
          name: e.name.value,
          description:
            null === (t = e.description) || void 0 === t ? void 0 : t.value,
          locations: e.locations.map(({ value: e }) => e),
          isRepeatable: e.repeatable,
          args: D(e.arguments),
          astNode: e,
        });
      }),
    ],
    extensions: Object.create(null),
    astNode: null !== (s = p) && void 0 !== s ? s : e.astNode,
    extensionASTNodes: e.extensionASTNodes.concat(d),
    assumeValid:
      null !== (a = null == n ? void 0 : n.assumeValid) && void 0 !== a && a,
  };
  function y(e) {
    return st(e) ? new Nt(y(e.ofType)) : ct(e) ? new It(y(e.ofType)) : E(e);
  }
  function E(e) {
    return f[e.name];
  }
  function v(e) {
    return Fn(e) || an(e)
      ? e
      : Ke(e)
      ? (function (e) {
          var t;
          const n = e.toConfig(),
            i = null !== (t = u[n.name]) && void 0 !== t ? t : [];
          let r = n.specifiedByURL;
          for (const e of i) {
            var o;
            r = null !== (o = go(e)) && void 0 !== o ? o : r;
          }
          return new xt({
            ...n,
            specifiedByURL: r,
            extensionASTNodes: n.extensionASTNodes.concat(i),
          });
        })(e)
      : ze(e)
      ? (function (e) {
          var t;
          const n = e.toConfig(),
            i = null !== (t = u[n.name]) && void 0 !== t ? t : [];
          return new kt({
            ...n,
            interfaces: () => [...e.getInterfaces().map(E), ...S(i)],
            fields: () => ({ ...Te(n.fields, T), ...O(i) }),
            extensionASTNodes: n.extensionASTNodes.concat(i),
          });
        })(e)
      : We(e)
      ? (function (e) {
          var t;
          const n = e.toConfig(),
            i = null !== (t = u[n.name]) && void 0 !== t ? t : [];
          return new Pt({
            ...n,
            interfaces: () => [...e.getInterfaces().map(E), ...S(i)],
            fields: () => ({ ...Te(n.fields, T), ...O(i) }),
            extensionASTNodes: n.extensionASTNodes.concat(i),
          });
        })(e)
      : et(e)
      ? (function (e) {
          var t;
          const n = e.toConfig(),
            i = null !== (t = u[n.name]) && void 0 !== t ? t : [];
          return new Bt({
            ...n,
            types: () => [...e.getTypes().map(E), ...R(i)],
            extensionASTNodes: n.extensionASTNodes.concat(i),
          });
        })(e)
      : nt(e)
      ? (function (e) {
          var t;
          const n = e.toConfig(),
            i = null !== (t = u[e.name]) && void 0 !== t ? t : [];
          return new Yt({
            ...n,
            values: { ...n.values, ...w(i) },
            extensionASTNodes: n.extensionASTNodes.concat(i),
          });
        })(e)
      : rt(e)
      ? (function (e) {
          var t;
          const n = e.toConfig(),
            i = null !== (t = u[n.name]) && void 0 !== t ? t : [];
          return new Jt({
            ...n,
            fields: () => ({
              ...Te(n.fields, (e) => ({ ...e, type: y(e.type) })),
              ...A(i),
            }),
            extensionASTNodes: n.extensionASTNodes.concat(i),
          });
        })(e)
      : void o(!1, "Unexpected type: " + ne(e));
  }
  function T(e) {
    return { ...e, type: y(e.type), args: e.args && Te(e.args, N) };
  }
  function N(e) {
    return { ...e, type: y(e.type) };
  }
  function I(e) {
    const t = {};
    for (const i of e) {
      var n;
      const e = null !== (n = i.operationTypes) && void 0 !== n ? n : [];
      for (const n of e) t[n.operation] = g(n.type);
    }
    return t;
  }
  function g(e) {
    var t;
    const n = e.name.value,
      i = null !== (t = No[n]) && void 0 !== t ? t : f[n];
    if (void 0 === i) throw new Error(`Unknown type: "${n}".`);
    return i;
  }
  function b(e) {
    return e.kind === _.LIST_TYPE
      ? new Nt(b(e.type))
      : e.kind === _.NON_NULL_TYPE
      ? new It(b(e.type))
      : g(e);
  }
  function O(e) {
    const t = Object.create(null);
    for (const r of e) {
      var n;
      const e = null !== (n = r.fields) && void 0 !== n ? n : [];
      for (const n of e) {
        var i;
        t[n.name.value] = {
          type: b(n.type),
          description:
            null === (i = n.description) || void 0 === i ? void 0 : i.value,
          args: D(n.arguments),
          deprecationReason: Io(n),
          astNode: n,
        };
      }
    }
    return t;
  }
  function D(e) {
    const t = null != e ? e : [],
      n = Object.create(null);
    for (const e of t) {
      var i;
      const t = b(e.type);
      n[e.name.value] = {
        type: t,
        description:
          null === (i = e.description) || void 0 === i ? void 0 : i.value,
        defaultValue: nr(e.defaultValue, t),
        deprecationReason: Io(e),
        astNode: e,
      };
    }
    return n;
  }
  function A(e) {
    const t = Object.create(null);
    for (const r of e) {
      var n;
      const e = null !== (n = r.fields) && void 0 !== n ? n : [];
      for (const n of e) {
        var i;
        const e = b(n.type);
        t[n.name.value] = {
          type: e,
          description:
            null === (i = n.description) || void 0 === i ? void 0 : i.value,
          defaultValue: nr(n.defaultValue, e),
          deprecationReason: Io(n),
          astNode: n,
        };
      }
    }
    return t;
  }
  function w(e) {
    const t = Object.create(null);
    for (const r of e) {
      var n;
      const e = null !== (n = r.values) && void 0 !== n ? n : [];
      for (const n of e) {
        var i;
        t[n.name.value] = {
          description:
            null === (i = n.description) || void 0 === i ? void 0 : i.value,
          deprecationReason: Io(n),
          astNode: n,
        };
      }
    }
    return t;
  }
  function S(e) {
    return e.flatMap((e) => {
      var t, n;
      return null !==
        (t = null === (n = e.interfaces) || void 0 === n ? void 0 : n.map(g)) &&
        void 0 !== t
        ? t
        : [];
    });
  }
  function R(e) {
    return e.flatMap((e) => {
      var t, n;
      return null !==
        (t = null === (n = e.types) || void 0 === n ? void 0 : n.map(g)) &&
        void 0 !== t
        ? t
        : [];
    });
  }
  function $(e) {
    var t;
    const n = e.name.value,
      i = null !== (t = u[n]) && void 0 !== t ? t : [];
    switch (e.kind) {
      case _.OBJECT_TYPE_DEFINITION: {
        var r;
        const t = [e, ...i];
        return new kt({
          name: n,
          description:
            null === (r = e.description) || void 0 === r ? void 0 : r.value,
          interfaces: () => S(t),
          fields: () => O(t),
          astNode: e,
          extensionASTNodes: i,
        });
      }
      case _.INTERFACE_TYPE_DEFINITION: {
        var o;
        const t = [e, ...i];
        return new Pt({
          name: n,
          description:
            null === (o = e.description) || void 0 === o ? void 0 : o.value,
          interfaces: () => S(t),
          fields: () => O(t),
          astNode: e,
          extensionASTNodes: i,
        });
      }
      case _.ENUM_TYPE_DEFINITION: {
        var s;
        const t = [e, ...i];
        return new Yt({
          name: n,
          description:
            null === (s = e.description) || void 0 === s ? void 0 : s.value,
          values: w(t),
          astNode: e,
          extensionASTNodes: i,
        });
      }
      case _.UNION_TYPE_DEFINITION: {
        var a;
        const t = [e, ...i];
        return new Bt({
          name: n,
          description:
            null === (a = e.description) || void 0 === a ? void 0 : a.value,
          types: () => R(t),
          astNode: e,
          extensionASTNodes: i,
        });
      }
      case _.SCALAR_TYPE_DEFINITION:
        var c;
        return new xt({
          name: n,
          description:
            null === (c = e.description) || void 0 === c ? void 0 : c.value,
          specifiedByURL: go(e),
          astNode: e,
          extensionASTNodes: i,
        });
      case _.INPUT_OBJECT_TYPE_DEFINITION: {
        var l;
        const t = [e, ...i];
        return new Jt({
          name: n,
          description:
            null === (l = e.description) || void 0 === l ? void 0 : l.value,
          fields: () => A(t),
          astNode: e,
          extensionASTNodes: i,
        });
      }
    }
  }
}
const No = Ee([...sn, ...Ln], (e) => e.name);
function Io(e) {
  const t = sr(mn, e);
  return null == t ? void 0 : t.reason;
}
function go(e) {
  const t = sr(yn, e);
  return null == t ? void 0 : t.url;
}
function _o(e, t) {
  (null != e && e.kind === _.DOCUMENT) ||
    n(!1, "Must provide valid Document AST."),
    !0 !== (null == t ? void 0 : t.assumeValid) &&
      !0 !== (null == t ? void 0 : t.assumeValidSDL) &&
      (function (e) {
        const t = Ur(e);
        if (0 !== t.length)
          throw new Error(t.map((e) => e.message).join("\n\n"));
      })(e);
  const i = To(
    {
      description: void 0,
      types: [],
      directives: [],
      extensions: Object.create(null),
      extensionASTNodes: [],
      assumeValid: !1,
    },
    e,
    t
  );
  if (null == i.astNode)
    for (const e of i.types)
      switch (e.name) {
        case "Query":
          i.query = e;
          break;
        case "Mutation":
          i.mutation = e;
          break;
        case "Subscription":
          i.subscription = e;
      }
  const r = [
    ...i.directives,
    ...En.filter((e) => i.directives.every((t) => t.name !== e.name)),
  ];
  return new Un({ ...i, directives: r });
}
function bo(e, t) {
  return _o(
    ae(e, {
      noLocation: null == t ? void 0 : t.noLocation,
      allowLegacyFragmentVariables:
        null == t ? void 0 : t.allowLegacyFragmentVariables,
    }),
    {
      assumeValidSDL: null == t ? void 0 : t.assumeValidSDL,
      assumeValid: null == t ? void 0 : t.assumeValid,
    }
  );
}
function Oo(e) {
  const t = e.toConfig(),
    n = ve(
      Ao(t.types),
      (e) => e.name,
      function (e) {
        if (Ke(e) || Fn(e)) return e;
        if (ze(e)) {
          const t = e.toConfig();
          return new kt({
            ...t,
            interfaces: () => u(t.interfaces),
            fields: () => c(t.fields),
          });
        }
        if (We(e)) {
          const t = e.toConfig();
          return new Pt({
            ...t,
            interfaces: () => u(t.interfaces),
            fields: () => c(t.fields),
          });
        }
        if (et(e)) {
          const t = e.toConfig();
          return new Bt({ ...t, types: () => u(t.types) });
        }
        if (nt(e)) {
          const t = e.toConfig();
          return new Yt({ ...t, values: Do(t.values, (e) => e) });
        }
        if (rt(e)) {
          const t = e.toConfig();
          return new Jt({
            ...t,
            fields: () => Do(t.fields, (e) => ({ ...e, type: i(e.type) })),
          });
        }
        o(!1, "Unexpected type: " + ne(e));
      }
    );
  return new Un({
    ...t,
    types: Object.values(n),
    directives: Ao(t.directives).map(function (e) {
      const t = e.toConfig();
      return new pn({
        ...t,
        locations: wo(t.locations, (e) => e),
        args: a(t.args),
      });
    }),
    query: s(t.query),
    mutation: s(t.mutation),
    subscription: s(t.subscription),
  });
  function i(e) {
    return st(e) ? new Nt(i(e.ofType)) : ct(e) ? new It(i(e.ofType)) : r(e);
  }
  function r(e) {
    return n[e.name];
  }
  function s(e) {
    return e && r(e);
  }
  function a(e) {
    return Do(e, (e) => ({ ...e, type: i(e.type) }));
  }
  function c(e) {
    return Do(e, (e) => ({ ...e, type: i(e.type), args: e.args && a(e.args) }));
  }
  function u(e) {
    return Ao(e).map(r);
  }
}
function Do(e, t) {
  const n = Object.create(null);
  for (const i of Object.keys(e).sort(Ne)) n[i] = t(e[i]);
  return n;
}
function Ao(e) {
  return wo(e, (e) => e.name);
}
function wo(e, t) {
  return e.slice().sort((e, n) => Ne(t(e), t(n)));
}
function So(e) {
  return xo(e, (e) => !vn(e), $o);
}
function Ro(e) {
  return xo(e, vn, Fn);
}
function $o(e) {
  return !an(e) && !Fn(e);
}
function xo(e, t, n) {
  const i = e.getDirectives().filter(t),
    r = Object.values(e.getTypeMap()).filter(n);
  return [
    ko(e),
    ...i.map((e) =>
      (function (e) {
        return (
          Po(e) +
          "directive @" +
          e.name +
          Uo(e.args) +
          (e.isRepeatable ? " repeatable" : "") +
          " on " +
          e.locations.join(" | ")
        );
      })(e)
    ),
    ...r.map((e) => Lo(e)),
  ]
    .filter(Boolean)
    .join("\n\n");
}
function ko(e) {
  if (
    null == e.description &&
    (function (e) {
      const t = e.getQueryType();
      if (t && "Query" !== t.name) return !1;
      const n = e.getMutationType();
      if (n && "Mutation" !== n.name) return !1;
      const i = e.getSubscriptionType();
      if (i && "Subscription" !== i.name) return !1;
      return !0;
    })(e)
  )
    return;
  const t = [],
    n = e.getQueryType();
  n && t.push(`  query: ${n.name}`);
  const i = e.getMutationType();
  i && t.push(`  mutation: ${i.name}`);
  const r = e.getSubscriptionType();
  return (
    r && t.push(`  subscription: ${r.name}`),
    Po(e) + `schema {\n${t.join("\n")}\n}`
  );
}
function Lo(e) {
  return Ke(e)
    ? (function (e) {
        return (
          Po(e) +
          `scalar ${e.name}` +
          (function (e) {
            if (null == e.specifiedByURL) return "";
            return ` @specifiedBy(url: ${Ce({
              kind: _.STRING,
              value: e.specifiedByURL,
            })})`;
          })(e)
        );
      })(e)
    : ze(e)
    ? (function (e) {
        return Po(e) + `type ${e.name}` + Fo(e) + Co(e);
      })(e)
    : We(e)
    ? (function (e) {
        return Po(e) + `interface ${e.name}` + Fo(e) + Co(e);
      })(e)
    : et(e)
    ? (function (e) {
        const t = e.getTypes(),
          n = t.length ? " = " + t.join(" | ") : "";
        return Po(e) + "union " + e.name + n;
      })(e)
    : nt(e)
    ? (function (e) {
        const t = e
          .getValues()
          .map(
            (e, t) => Po(e, "  ", !t) + "  " + e.name + jo(e.deprecationReason)
          );
        return Po(e) + `enum ${e.name}` + Vo(t);
      })(e)
    : rt(e)
    ? (function (e) {
        const t = Object.values(e.getFields()).map(
          (e, t) => Po(e, "  ", !t) + "  " + Mo(e)
        );
        return Po(e) + `input ${e.name}` + Vo(t);
      })(e)
    : void o(!1, "Unexpected type: " + ne(e));
}
function Fo(e) {
  const t = e.getInterfaces();
  return t.length ? " implements " + t.map((e) => e.name).join(" & ") : "";
}
function Co(e) {
  return Vo(
    Object.values(e.getFields()).map(
      (e, t) =>
        Po(e, "  ", !t) +
        "  " +
        e.name +
        Uo(e.args, "  ") +
        ": " +
        String(e.type) +
        jo(e.deprecationReason)
    )
  );
}
function Vo(e) {
  return 0 !== e.length ? " {\n" + e.join("\n") + "\n}" : "";
}
function Uo(e, t = "") {
  return 0 === e.length
    ? ""
    : e.every((e) => !e.description)
    ? "(" + e.map(Mo).join(", ") + ")"
    : "(\n" +
      e.map((e, n) => Po(e, "  " + t, !n) + "  " + t + Mo(e)).join("\n") +
      "\n" +
      t +
      ")";
}
function Mo(e) {
  const t = Nn(e.defaultValue, e.type);
  let n = e.name + ": " + String(e.type);
  return t && (n += ` = ${Ce(t)}`), n + jo(e.deprecationReason);
}
function jo(e) {
  if (null == e) return "";
  if (e !== hn) {
    return ` @deprecated(reason: ${Ce({ kind: _.STRING, value: e })})`;
  }
  return " @deprecated";
}
function Po(e, t = "", n = !0) {
  const { description: i } = e;
  if (null == i) return "";
  return (
    (t && !n ? "\n" + t : t) +
    Ce({ kind: _.STRING, value: i, block: x(i) }).replace(/\n/g, "\n" + t) +
    "\n"
  );
}
function Bo(e) {
  const t = [];
  for (const n of e) t.push(...n.definitions);
  return { kind: _.DOCUMENT, definitions: t };
}
function Go(e) {
  const t = [],
    n = Object.create(null);
  for (const i of e.definitions)
    switch (i.kind) {
      case _.OPERATION_DEFINITION:
        t.push(i);
        break;
      case _.FRAGMENT_DEFINITION:
        n[i.name.value] = Qo(i.selectionSet);
    }
  const i = Object.create(null);
  for (const r of t) {
    const t = new Set();
    for (const e of Qo(r.selectionSet)) Yo(t, n, e);
    i[r.name ? r.name.value : ""] = {
      kind: _.DOCUMENT,
      definitions: e.definitions.filter(
        (e) =>
          e === r || (e.kind === _.FRAGMENT_DEFINITION && t.has(e.name.value))
      ),
    };
  }
  return i;
}
function Yo(e, t, n) {
  if (!e.has(n)) {
    e.add(n);
    const i = t[n];
    if (void 0 !== i) for (const n of i) Yo(e, t, n);
  }
}
function Qo(e) {
  const t = [];
  return (
    xe(e, {
      FragmentSpread(e) {
        t.push(e.name.value);
      },
    }),
    t
  );
}
function Jo(e) {
  const t = se(e) ? e : new oe(e),
    n = t.body,
    i = new L(t);
  let r = "",
    o = !1;
  for (; i.advance().kind !== b.EOF; ) {
    const e = i.token,
      t = e.kind,
      s = !F(e.kind);
    o && (s || e.kind === b.SPREAD) && (r += " ");
    const a = n.slice(e.start, e.end);
    t === b.BLOCK_STRING ? (r += k(e.value, { minimize: !0 })) : (r += a),
      (o = s);
  }
  return r;
}
function qo(e) {
  const t = Ko(e);
  if (t) throw t;
  return e;
}
function Ko(e) {
  if (
    ("string" == typeof e || n(!1, "Expected name to be a string."),
    e.startsWith("__"))
  )
    return new p(
      `Name "${e}" must not begin with "__", which is reserved by GraphQL introspection.`
    );
  try {
    Ye(e);
  } catch (e) {
    return e;
  }
}
var Xo, zo;
function Ho(e, t) {
  return Zo(e, t).filter((e) => e.type in Xo);
}
function Wo(e, t) {
  return Zo(e, t).filter((e) => e.type in zo);
}
function Zo(e, t) {
  return [...ts(e, t), ...es(e, t)];
}
function es(e, t) {
  const n = [],
    i = ds(e.getDirectives(), t.getDirectives());
  for (const e of i.removed)
    n.push({
      type: Xo.DIRECTIVE_REMOVED,
      description: `${e.name} was removed.`,
    });
  for (const [e, t] of i.persisted) {
    const i = ds(e.args, t.args);
    for (const t of i.added)
      jt(t) &&
        n.push({
          type: Xo.REQUIRED_DIRECTIVE_ARG_ADDED,
          description: `A required arg ${t.name} on directive ${e.name} was added.`,
        });
    for (const t of i.removed)
      n.push({
        type: Xo.DIRECTIVE_ARG_REMOVED,
        description: `${t.name} was removed from ${e.name}.`,
      });
    e.isRepeatable &&
      !t.isRepeatable &&
      n.push({
        type: Xo.DIRECTIVE_REPEATABLE_REMOVED,
        description: `Repeatable flag was removed from ${e.name}.`,
      });
    for (const i of e.locations)
      t.locations.includes(i) ||
        n.push({
          type: Xo.DIRECTIVE_LOCATION_REMOVED,
          description: `${i} was removed from ${e.name}.`,
        });
  }
  return n;
}
function ts(e, t) {
  const n = [],
    i = ds(Object.values(e.getTypeMap()), Object.values(t.getTypeMap()));
  for (const e of i.removed)
    n.push({
      type: Xo.TYPE_REMOVED,
      description: an(e)
        ? `Standard scalar ${e.name} was removed because it is not referenced anymore.`
        : `${e.name} was removed.`,
    });
  for (const [e, t] of i.persisted)
    nt(e) && nt(t)
      ? n.push(...rs(e, t))
      : et(e) && et(t)
      ? n.push(...is(e, t))
      : rt(e) && rt(t)
      ? n.push(...ns(e, t))
      : (ze(e) && ze(t)) || (We(e) && We(t))
      ? n.push(...ss(e, t), ...os(e, t))
      : e.constructor !== t.constructor &&
        n.push({
          type: Xo.TYPE_CHANGED_KIND,
          description: `${e.name} changed from ${ls(e)} to ${ls(t)}.`,
        });
  return n;
}
function ns(e, t) {
  const n = [],
    i = ds(Object.values(e.getFields()), Object.values(t.getFields()));
  for (const t of i.added)
    Kt(t)
      ? n.push({
          type: Xo.REQUIRED_INPUT_FIELD_ADDED,
          description: `A required field ${t.name} on input type ${e.name} was added.`,
        })
      : n.push({
          type: zo.OPTIONAL_INPUT_FIELD_ADDED,
          description: `An optional field ${t.name} on input type ${e.name} was added.`,
        });
  for (const t of i.removed)
    n.push({
      type: Xo.FIELD_REMOVED,
      description: `${e.name}.${t.name} was removed.`,
    });
  for (const [t, r] of i.persisted) {
    us(t.type, r.type) ||
      n.push({
        type: Xo.FIELD_CHANGED_KIND,
        description: `${e.name}.${t.name} changed type from ${String(
          t.type
        )} to ${String(r.type)}.`,
      });
  }
  return n;
}
function is(e, t) {
  const n = [],
    i = ds(e.getTypes(), t.getTypes());
  for (const t of i.added)
    n.push({
      type: zo.TYPE_ADDED_TO_UNION,
      description: `${t.name} was added to union type ${e.name}.`,
    });
  for (const t of i.removed)
    n.push({
      type: Xo.TYPE_REMOVED_FROM_UNION,
      description: `${t.name} was removed from union type ${e.name}.`,
    });
  return n;
}
function rs(e, t) {
  const n = [],
    i = ds(e.getValues(), t.getValues());
  for (const t of i.added)
    n.push({
      type: zo.VALUE_ADDED_TO_ENUM,
      description: `${t.name} was added to enum type ${e.name}.`,
    });
  for (const t of i.removed)
    n.push({
      type: Xo.VALUE_REMOVED_FROM_ENUM,
      description: `${t.name} was removed from enum type ${e.name}.`,
    });
  return n;
}
function os(e, t) {
  const n = [],
    i = ds(e.getInterfaces(), t.getInterfaces());
  for (const t of i.added)
    n.push({
      type: zo.IMPLEMENTED_INTERFACE_ADDED,
      description: `${t.name} added to interfaces implemented by ${e.name}.`,
    });
  for (const t of i.removed)
    n.push({
      type: Xo.IMPLEMENTED_INTERFACE_REMOVED,
      description: `${e.name} no longer implements interface ${t.name}.`,
    });
  return n;
}
function ss(e, t) {
  const n = [],
    i = ds(Object.values(e.getFields()), Object.values(t.getFields()));
  for (const t of i.removed)
    n.push({
      type: Xo.FIELD_REMOVED,
      description: `${e.name}.${t.name} was removed.`,
    });
  for (const [t, r] of i.persisted) {
    n.push(...as(e, t, r));
    cs(t.type, r.type) ||
      n.push({
        type: Xo.FIELD_CHANGED_KIND,
        description: `${e.name}.${t.name} changed type from ${String(
          t.type
        )} to ${String(r.type)}.`,
      });
  }
  return n;
}
function as(e, t, n) {
  const i = [],
    r = ds(t.args, n.args);
  for (const n of r.removed)
    i.push({
      type: Xo.ARG_REMOVED,
      description: `${e.name}.${t.name} arg ${n.name} was removed.`,
    });
  for (const [n, o] of r.persisted) {
    if (us(n.type, o.type)) {
      if (void 0 !== n.defaultValue)
        if (void 0 === o.defaultValue)
          i.push({
            type: zo.ARG_DEFAULT_VALUE_CHANGE,
            description: `${e.name}.${t.name} arg ${n.name} defaultValue was removed.`,
          });
        else {
          const r = ps(n.defaultValue, n.type),
            s = ps(o.defaultValue, o.type);
          r !== s &&
            i.push({
              type: zo.ARG_DEFAULT_VALUE_CHANGE,
              description: `${e.name}.${t.name} arg ${n.name} has changed defaultValue from ${r} to ${s}.`,
            });
        }
    } else
      i.push({
        type: Xo.ARG_CHANGED_KIND,
        description: `${e.name}.${t.name} arg ${
          n.name
        } has changed type from ${String(n.type)} to ${String(o.type)}.`,
      });
  }
  for (const n of r.added)
    jt(n)
      ? i.push({
          type: Xo.REQUIRED_ARG_ADDED,
          description: `A required arg ${n.name} on ${e.name}.${t.name} was added.`,
        })
      : i.push({
          type: zo.OPTIONAL_ARG_ADDED,
          description: `An optional arg ${n.name} on ${e.name}.${t.name} was added.`,
        });
  return i;
}
function cs(e, t) {
  return st(e)
    ? (st(t) && cs(e.ofType, t.ofType)) || (ct(t) && cs(e, t.ofType))
    : ct(e)
    ? ct(t) && cs(e.ofType, t.ofType)
    : (At(t) && e.name === t.name) || (ct(t) && cs(e, t.ofType));
}
function us(e, t) {
  return st(e)
    ? st(t) && us(e.ofType, t.ofType)
    : ct(e)
    ? (ct(t) && us(e.ofType, t.ofType)) || (!ct(t) && us(e.ofType, t))
    : At(t) && e.name === t.name;
}
function ls(e) {
  return Ke(e)
    ? "a Scalar type"
    : ze(e)
    ? "an Object type"
    : We(e)
    ? "an Interface type"
    : et(e)
    ? "a Union type"
    : nt(e)
    ? "an Enum type"
    : rt(e)
    ? "an Input type"
    : void o(!1, "Unexpected type: " + ne(e));
}
function ps(e, t) {
  const n = Nn(e, t);
  return null != n || o(!1), Ce(Ri(n));
}
function ds(e, t) {
  const n = [],
    i = [],
    r = [],
    o = Ee(e, ({ name: e }) => e),
    s = Ee(t, ({ name: e }) => e);
  for (const t of e) {
    const e = s[t.name];
    void 0 === e ? i.push(t) : r.push([t, e]);
  }
  for (const e of t) void 0 === o[e.name] && n.push(e);
  return { added: n, persisted: r, removed: i };
}
!(function (e) {
  (e.TYPE_REMOVED = "TYPE_REMOVED"),
    (e.TYPE_CHANGED_KIND = "TYPE_CHANGED_KIND"),
    (e.TYPE_REMOVED_FROM_UNION = "TYPE_REMOVED_FROM_UNION"),
    (e.VALUE_REMOVED_FROM_ENUM = "VALUE_REMOVED_FROM_ENUM"),
    (e.REQUIRED_INPUT_FIELD_ADDED = "REQUIRED_INPUT_FIELD_ADDED"),
    (e.IMPLEMENTED_INTERFACE_REMOVED = "IMPLEMENTED_INTERFACE_REMOVED"),
    (e.FIELD_REMOVED = "FIELD_REMOVED"),
    (e.FIELD_CHANGED_KIND = "FIELD_CHANGED_KIND"),
    (e.REQUIRED_ARG_ADDED = "REQUIRED_ARG_ADDED"),
    (e.ARG_REMOVED = "ARG_REMOVED"),
    (e.ARG_CHANGED_KIND = "ARG_CHANGED_KIND"),
    (e.DIRECTIVE_REMOVED = "DIRECTIVE_REMOVED"),
    (e.DIRECTIVE_ARG_REMOVED = "DIRECTIVE_ARG_REMOVED"),
    (e.REQUIRED_DIRECTIVE_ARG_ADDED = "REQUIRED_DIRECTIVE_ARG_ADDED"),
    (e.DIRECTIVE_REPEATABLE_REMOVED = "DIRECTIVE_REPEATABLE_REMOVED"),
    (e.DIRECTIVE_LOCATION_REMOVED = "DIRECTIVE_LOCATION_REMOVED");
})(Xo || (Xo = {})),
  (function (e) {
    (e.VALUE_ADDED_TO_ENUM = "VALUE_ADDED_TO_ENUM"),
      (e.TYPE_ADDED_TO_UNION = "TYPE_ADDED_TO_UNION"),
      (e.OPTIONAL_INPUT_FIELD_ADDED = "OPTIONAL_INPUT_FIELD_ADDED"),
      (e.OPTIONAL_ARG_ADDED = "OPTIONAL_ARG_ADDED"),
      (e.IMPLEMENTED_INTERFACE_ADDED = "IMPLEMENTED_INTERFACE_ADDED"),
      (e.ARG_DEFAULT_VALUE_CHANGE = "ARG_DEFAULT_VALUE_CHANGE");
  })(zo || (zo = {}));
export {
  $e as BREAK,
  Xo as BreakingChangeType,
  hn as DEFAULT_DEPRECATION_REASON,
  zo as DangerousChangeType,
  g as DirectiveLocation,
  mi as ExecutableDefinitionsRule,
  yi as FieldsOnCorrectTypeRule,
  Ei as FragmentsOnCompositeTypesRule,
  Wt as GRAPHQL_MAX_INT,
  Zt as GRAPHQL_MIN_INT,
  rn as GraphQLBoolean,
  mn as GraphQLDeprecatedDirective,
  pn as GraphQLDirective,
  Yt as GraphQLEnumType,
  p as GraphQLError,
  tn as GraphQLFloat,
  on as GraphQLID,
  dn as GraphQLIncludeDirective,
  Jt as GraphQLInputObjectType,
  en as GraphQLInt,
  Pt as GraphQLInterfaceType,
  Nt as GraphQLList,
  It as GraphQLNonNull,
  kt as GraphQLObjectType,
  xt as GraphQLScalarType,
  Un as GraphQLSchema,
  fn as GraphQLSkipDirective,
  yn as GraphQLSpecifiedByDirective,
  nn as GraphQLString,
  Bt as GraphQLUnionType,
  _ as Kind,
  vi as KnownArgumentNamesRule,
  Ni as KnownDirectivesRule,
  Ii as KnownFragmentNamesRule,
  gi as KnownTypeNamesRule,
  L as Lexer,
  y as Location,
  bi as LoneAnonymousOperationRule,
  Oi as LoneSchemaDefinitionRule,
  lo as NoDeprecatedCustomRule,
  Di as NoFragmentCyclesRule,
  po as NoSchemaIntrospectionCustomRule,
  Ai as NoUndefinedVariablesRule,
  wi as NoUnusedFragmentsRule,
  Si as NoUnusedVariablesRule,
  I as OperationTypeNode,
  xi as OverlappingFieldsCanBeMergedRule,
  Gi as PossibleFragmentSpreadsRule,
  Yi as PossibleTypeExtensionsRule,
  Ji as ProvidedRequiredArgumentsRule,
  Xi as ScalarLeafsRule,
  $n as SchemaMetaFieldDef,
  dr as SingleFieldSubscriptionsRule,
  oe as Source,
  E as Token,
  b as TokenKind,
  ni as TypeInfo,
  Sn as TypeKind,
  xn as TypeMetaFieldDef,
  kn as TypeNameMetaFieldDef,
  hr as UniqueArgumentDefinitionNamesRule,
  mr as UniqueArgumentNamesRule,
  yr as UniqueDirectiveNamesRule,
  Er as UniqueDirectivesPerLocationRule,
  vr as UniqueEnumValueNamesRule,
  Tr as UniqueFieldDefinitionNamesRule,
  Ir as UniqueFragmentNamesRule,
  gr as UniqueInputFieldNamesRule,
  _r as UniqueOperationNamesRule,
  br as UniqueOperationTypesRule,
  Or as UniqueTypeNamesRule,
  Dr as UniqueVariableNamesRule,
  Cr as ValidationContext,
  Ar as ValuesOfCorrectTypeRule,
  Sr as VariablesAreInputTypesRule,
  Rr as VariablesInAllowedPositionRule,
  _n as __Directive,
  bn as __DirectiveLocation,
  wn as __EnumValue,
  Dn as __Field,
  An as __InputValue,
  gn as __Schema,
  On as __Type,
  Rn as __TypeKind,
  Tt as assertAbstractType,
  Et as assertCompositeType,
  ln as assertDirective,
  it as assertEnumType,
  Qe as assertEnumValueName,
  ot as assertInputObjectType,
  pt as assertInputType,
  Ze as assertInterfaceType,
  mt as assertLeafType,
  at as assertListType,
  Ye as assertName,
  wt as assertNamedType,
  ut as assertNonNullType,
  Ot as assertNullableType,
  He as assertObjectType,
  ft as assertOutputType,
  Xe as assertScalarType,
  Vn as assertSchema,
  qe as assertType,
  tt as assertUnionType,
  qo as assertValidName,
  Pn as assertValidSchema,
  _t as assertWrappingType,
  Nn as astFromValue,
  _o as buildASTSchema,
  Eo as buildClientSchema,
  bo as buildSchema,
  Zi as coerceInputValue,
  Bo as concatAST,
  uo as createSourceEventStream,
  no as defaultFieldResolver,
  to as defaultTypeResolver,
  Ht as doTypesOverlap,
  Br as execute,
  Gr as executeSync,
  vo as extendSchema,
  Ho as findBreakingChanges,
  Wo as findDangerousChanges,
  h as formatError,
  or as getArgumentValues,
  sr as getDirectiveValues,
  Le as getEnterLeaveForKind,
  fo as getIntrospectionQuery,
  a as getLocation,
  St as getNamedType,
  Dt as getNullableType,
  ho as getOperationAST,
  mo as getOperationRootType,
  rr as getVariableValues,
  Fe as getVisitFn,
  ro as graphql,
  oo as graphqlSync,
  yo as introspectionFromSchema,
  Ln as introspectionTypes,
  vt as isAbstractType,
  yt as isCompositeType,
  ui as isConstValueNode,
  oi as isDefinitionNode,
  un as isDirective,
  nt as isEnumType,
  Xt as isEqualType,
  si as isExecutableDefinitionNode,
  rt as isInputObjectType,
  lt as isInputType,
  We as isInterfaceType,
  Fn as isIntrospectionType,
  ht as isLeafType,
  st as isListType,
  At as isNamedType,
  ct as isNonNullType,
  bt as isNullableType,
  ze as isObjectType,
  dt as isOutputType,
  jt as isRequiredArgument,
  Kt as isRequiredInputField,
  Ke as isScalarType,
  Cn as isSchema,
  ai as isSelectionNode,
  vn as isSpecifiedDirective,
  an as isSpecifiedScalarType,
  Je as isType,
  di as isTypeDefinitionNode,
  hi as isTypeExtensionNode,
  li as isTypeNode,
  zt as isTypeSubTypeOf,
  pi as isTypeSystemDefinitionNode,
  fi as isTypeSystemExtensionNode,
  et as isUnionType,
  Ko as isValidNameError,
  ci as isValueNode,
  gt as isWrappingType,
  Oo as lexicographicSortSchema,
  jr as locatedError,
  ae as parse,
  ue as parseConstValue,
  le as parseType,
  ce as parseValue,
  Ce as print,
  f as printError,
  Ro as printIntrospectionSchema,
  c as printLocation,
  So as printSchema,
  u as printSourceLocation,
  Lo as printType,
  $t as resolveObjMapThunk,
  Rt as resolveReadonlyArrayThunk,
  Wi as responsePathAsArray,
  Go as separateOperations,
  En as specifiedDirectives,
  xr as specifiedRules,
  sn as specifiedScalarTypes,
  Jo as stripIgnoredCharacters,
  co as subscribe,
  m as syntaxError,
  ti as typeFromAST,
  Vr as validate,
  jn as validateSchema,
  nr as valueFromAST,
  Ge as valueFromASTUntyped,
  e as version,
  t as versionInfo,
  xe as visit,
  ke as visitInParallel,
  ri as visitWithTypeInfo,
};
export default null;
//# sourceMappingURL=/sm/648e21f1d3c0ffd2e0716a9060534b829eef72fc19aa0bf308f915593e9c7d37.map
