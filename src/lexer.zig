const std = @import("std");

const mem = std.mem;
const testing = std.testing;
const expect = testing.expect;
const pageAllocator = std.heap.page_allocator;

pub const Token = struct {
    tag: Tag,
    loc: Loc,

    pub const Loc = struct {
        start: usize,
        end: usize,
    };

    pub const Tag = enum {
        eof,
        err,
        shebang,
        line_comment,
        block_comment,
        markup,
        text,
        space,
        linebreak,
        paragrah_break,
        escape,
        shorthand,
        smartquote,
        strong,
        empasized,
        raw,
        raw_lang,
        raw_delim,
        raw_trimmed,
        link,
        label,
        ref,
        ref_marker,
        heading,
        heading_marker,
        list_item,
        list_marker,
        enum_item,
        enum_marker,
        term_item,
        term_marker,
        eq,

        math,
        math_text,
        math_ident,
        math_shorthand,
        math_alignpoint,
        math_call,
        math_args,
        math_delim,
        math_attach,
        math_primes,
        math_frac,
        math_root,

        hash,
        l_brace,
        r_brace,
        l_bracket,
        r_bracket,
        l_paren,
        r_paren,
        comma,
        colon,
        semicolon,
        star,
        underscore,
        dollar,
        plus,
        minus,
        slash,
        caret,
        dot,
    };
};
