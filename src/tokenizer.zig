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
        invalid,
        eof,
        err,
        shebang,
        line_comment,
        block_comment,
        markup,
        text,
        space,
        linebreak,
        parabreak,
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
        equation,

        math,
        math_text,
        math_ident,
        math_shorthand,
        math_alignpoint,
        math_call,
        math_args,
        math_delim,
        math_attach,
        math_frac,
        math_root,
        math_primes,

        hash,
        l_brace,
        r_brace,
        l_bracket,
        r_bracket,
        l_paren,
        r_paren,
        comma,
        semicolon,
        colon,
        star,
        underscore,
        dollar,
        plus,
        minus,
        slash,
        caret,
        dot,
        equal,
        equal_equal,
        bang_equal,
        angle_bracket_left,
        angle_bracket_left_equal,
        angle_bracket_right,
        angle_bracket_right_equal,
        plus_equal,
        minus_euqal,
        asterisk_equal,
        slash_equal,
        dot_dot,
        equal_angle_bracket_left,
        root,
        bang,

        op_not,
        op_and,
        op_or,

        none,
        auto,

        keyword_let,
        keyword_set,
        keyword_show,
        keyword_context,
        keyword_if,
        keyword_else,
        keyword_for,
        keyword_in,
        keyword_while,
        keyword_break,
        keyword_continue,
        keyword_return,
        keyword_import,
        keyword_include,
        keyword_as,

        code,
        identifier,
        boolean,
        int,
        float,
        numeric,
        str,
        code_block,
        content_block,
        parenthesized,
        array,
        dict,
        named,
        keyed,
        unary,
        binary,
        field_access,
        func_call,
        args,
        spread,
        closure,
        params,
        let_binding,
        set_rule,
        show_rule,
        contextual,
        conditional,
        while_loop,
        for_loop,
        import_module,
        import_items,
        import_item_path,
        rename_import_item,
        module_include,
        loop_break,
        loop_continue,
        func_return,
        destructuring,
        destruct_assignment,
    };

    pub fn lexme(tag: Tag) ?[]const u8 {
        return switch (tag) {
            .invalid,
            => null,

            .identifier => "identifier",
            .eof => "end of stream",
            .err => "error",
            .shebang => "#!",
            .line_comment => "// comment ",
            .block_comment => "/* block comment */",
            .markup => "markup",
            .text => "text",
            .space => "space",
            .linebreak => "line break",
            .parabreak => "pragraph break",
            .escape => "escape",
            .shorthand => "shorthand",
            .smartquote => "smart quote",
            .strong => "strong",
            .empasized => "emphasized",
            .raw => "raw block",
            .raw_lang => "raw lang tag",
            .raw_trimmed => "raw trimmed",
            .raw_delim => "raw delimiter",
            .link => "link",
            .label => "label",
            .ref => "reference",
            .ref_marker => "reference marker",
            .heading => "heading",
            .heading_marker => "heading marker",
            .list_item => "list item",
            .list_marker => "list marker",
            .enum_item => "enum item",
            .enum_marker => "enum marker",
            .term_item => "term item",
            .term_marker => "term marker",
            .equation => "equation",
            .math => "math",
            .math_text => "math text",
            .math_ident => "math identifier",
            .math_shorthand => "math shorthand",
            .math_alignpoint => "math align point",
            .math_call => "math function call",
            .math_args => "math function arguments",
            .math_delim => "math delimited",
            .math_attach => "math attachments",
            .math_frac => "math fraction",
            .math_root => "math root",
            .math_primes => "math primes",
            .hash => "hash",
            .l_brace => "{",
            .r_brace => "}",
            .l_bracket => "[",
            .r_bracket => "]",
            .l_paren => "(",
            .r_paren => ")",
            .comma => ",",
            .semicolon => ";",
            .colon => ":",
            .star => "*",
            .underscore => "_",
            .dollar => "$",
            .plus => "+",
            .minus => "-",
            .slash => "/",
            .caret => "^",
            .period => ".",
            .equal => "=",
            .equal_equal => "==",
            .bang_equal => "!=",
            .angle_bracket_left => "<",
            .angle_bracket_left_equal => "<=",
            .angle_bracket_right => ">",
            .angle_bracket_right_equal => ">=",
            .plus_equal => "+=",
            .minus_euqal => "-=",
            .asterisk_equal => "*=",
            .slash_equal => "/=",
            .dot_dot => "..",
            .equal_angle_bracket_left => "=<",
            .root => "root",
            .bang => "!",
            .op_not => "not operator",
            .op_and => "and operator",
            .op_or => "or operator",
            .none => "none",
            .auto => "auto",
            .keyword_let => "let",
            .keyword_set => "set",
            .keyword_show => "show",
            .keyword_context => "context",
            .keyword_if => "if",
            .keyword_else => "else",
            .keyword_for => "for",
            .keyword_in => "in",
            .keyword_while => "while",
            .keyword_break => "break",
            .keyword_continue => "continue",
            .keyword_return => "return",
            .keyword_import => "import",
            .keyword_include => "include",
            .keyword_as => "as",
        };
    }
};

pub const Tokenizer = struct {
    buffer: [:0]const u8,
    index: usize,

    pub fn dump(self: *Tokenizer, token: *const Token) void {
        std.debug.print("[info]: {s} \"{s}\"\n", .{ @tagName(token.tag), self.buffer[token.loc.start..token.loc.end] });
    }

    pub fn init(buffer: [:0]const u8) Tokenizer {
        // skip the UTF-8 BOF if present.
        return .{
            .buffer = buffer,
            .index = if (std.mem.startsWith(u8, buffer, "\xEF\xBB\xBF")) 3 else 0,
        };
    }

    pub const State = enum {
        start,
        invalid,
    };

    pub fn next(self: *Tokenizer) ?Token {
        var result: Token = .{
            .tag = undefined,
            .loc = .{
                .start = self.index,
                .end = undefined,
            },
        };
        state: switch (State.start) {
            .start => switch (self.buffer[self.index]) {
                0 => {
                    if (self.index == self.buffer.len) {
                        return .{
                            .tag = .eof,
                            .loc = .{
                                .start = self.index,
                                .end = self.index,
                            },
                        };
                    } else {
                        continue :state .invalid;
                    }
                },
                ' ', '\n', '\t', '\r' => {
                    self.index += 1;
                    result.loc.start = self.index;
                    continue :state .start;
                },
                else => continue :state .invalid,
            },
            .invalid => {
                std.debug.print("[error]: lexer at invalid state\n", .{});
            },
        }
        result.loc.end = self.index;
        return result;
    }
};
