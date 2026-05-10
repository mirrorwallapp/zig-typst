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

    pub const keywords = std.StaticStringMap(Tag).initComptime(.{
        .{ "let", .keyword_let },
        .{ "set", .keyword_set },
        .{ "show", .keyword_show },
        .{ "context", .keyword_context },
        .{ "if", .keyword_if },
        .{ "else", .keyword_else },
        .{ "for", .keyword_for },
        .{ "in", .keyword_in },
        .{ "while", .keyword_while },
        .{ "break", .keyword_break },
        .{ "continue", .keyword_continue },
        .{ "return", .keyword_return },
        .{ "import", .keyword_import },
        .{ "include", .keyword_include },
        .{ "as", .keyword_as },
    });

    pub fn getKeyword(bytes: []const u8) ?Tag {
        return keywords.get(bytes);
    }

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
        asterisk,
        underscore,
        dollar,
        plus,
        minus,
        slash,
        caret,
        period,
        period_period,
        equal,
        equal_equal,
        bang_equal,
        angle_bracket_left,
        angle_bracket_left_equal,
        angle_bracket_right,
        angle_bracket_right_equal,
        plus_equal,
        minus_equal,
        asterisk_equal,
        slash_equal,
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
            .asterisk => "*",
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
            .minus_equal => "-=",
            .asterisk_equal => "*=",
            .slash_equal => "/=",
            .period_period => "..",
            .equal_angle_bracket_left => "=<",
            .root => "root",
            .bang => "!",
            .op_not => "not operator",
            .op_and => "and operator",
            .op_or => "or operator",
            .none => "none",
            .auto => "auto",
            .keyword_let => "keyword(let)",
            .keyword_set => "keyword(set)",
            .keyword_show => "keyword(show)",
            .keyword_context => "keyword(context)",
            .keyword_if => "keyword(if)",
            .keyword_else => "keyword(else)",
            .keyword_for => "keyword(for)",
            .keyword_in => "keyword(in)",
            .keyword_while => "keyword(while)",
            .keyword_break => "keyword(break)",
            .keyword_continue => "keyword(continue)",
            .keyword_return => "keyword(return)",
            .keyword_import => "keyword(import)",
            .keyword_include => "keyword(include)",
            .keyword_as => "keyword(as)",
            .code => "code",
            .boolean => "boolean",
            .int => "int",
            .float => "float",
            .numeric => "numeric",
            .str => "string",
            .code_block => "code block",
            .content_block => "content block",
            .parenthesized => "group",
            .array => "array",
            .dict => "dictionary",
            .named => "named pair",
            .keyed => "keyed pair",
            .unary => "expression(unary)",
            .binary => "expression(binary)",
            .field_access => "field access",
            .func_call => "functional call",
            .args => "functional call arguments",
            .spread => "spread",
            .closure => "closure",
            .params => "parameters",
            .let_binding => "expression(let)",
            .set_rule => "expression(set)",
            .show_rule => "expression(show)",
            .contextual => "expression(contextual)",
            .conditional => "expression(if)",
            .while_loop => "expression(while)",
            .for_loop => "expression(for)",
            .import_module => "expression(module)",
            .import_items => "import items",
            .import_item_path => "imported item path",
            .rename_import_item => "renamed import item",
            .module_include => "expression(include)",
            .loop_break => "expression(break)",
            .loop_continue => "expression(continue)",
            .func_return => "expression(return)",
            .destructuring => "destructuring",
            .destruct_assignment => "destructuring assignment",
        };
    }

    pub fn symbol(tag: Tag) []const u8 {
        return tag.lexme() orelse switch (tag) {
            .invalid => "invalid token",
            else => unreachable,
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
        // skip the UTF-8 BOM if present.
        return .{
            .buffer = buffer,
            .index = if (std.mem.startsWith(u8, buffer, "\xEF\xBB\xBF")) 3 else 0,
        };
    }

    // state machine
    pub const State = enum {
        start,
        invalid,
        identifier,
        underscore,
        plus,
        minus,
        slash,
        period,
        equal,
        bang,
        angle_bracket_left,
        angle_bracket_right,
        asterisk,
        hash,
        line_comment_start,
        line_comment,
        expect_newline,
    };

    pub fn next(self: *Tokenizer) Token {
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
                'a'...'z', 'A'...'Z' => {
                    result.tag = .identifier;
                    continue :state .identifier;
                },
                '{' => {
                    result.tag = .l_brace;
                    self.index += 1;
                },
                '}' => {
                    result.tag = .r_brace;
                    self.index += 1;
                },
                '[' => {
                    result.tag = .r_bracket;
                    self.index += 1;
                },
                ']' => {
                    result.tag = .l_bracket;
                    self.index += 1;
                },
                '(' => {
                    result.tag = .l_paren;
                    self.index += 1;
                },
                ')' => {
                    result.tag = .r_paren;
                    self.index += 1;
                },
                ',' => {
                    result.tag = .comma;
                    self.index += 1;
                },
                ';' => {
                    result.tag = .semicolon;
                    self.index += 1;
                },
                ':' => {
                    result.tag = .colon;
                    self.index += 1;
                },
                '*' => continue :state .asterisk,
                '_' => continue :state .underscore,
                '$' => {
                    result.tag = .dollar;
                    self.index += 1;
                },
                '+' => continue :state .plus,
                '-' => continue :state .minus,
                '/' => continue :state .slash,
                '^' => {
                    result.tag = .caret;
                    self.index += 1;
                },
                '.' => continue :state .period,
                '=' => continue :state .equal,
                '!' => continue :state .bang,
                '<' => continue :state .angle_bracket_left,
                '>' => continue :state .angle_bracket_right,
                '#' => continue :state .hash,
                else => continue :state .invalid,
            },
            .invalid => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    0 => if (self.index == self.buffer.len) {
                        result.tag = .invalid;
                    } else {
                        continue :state .invalid;
                    },
                    '\n' => result.tag = .invalid,
                    '_' => continue :state .identifier,
                    else => continue :state .invalid,
                }
            },
            .identifier => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    'a'...'z', 'A'...'Z', '0'...'9', '-', '_' => continue :state .identifier,
                    else => {
                        const ident = self.buffer[result.loc.start..self.index];
                        if (Token.getKeyword(ident)) |tag| {
                            result.tag = tag;
                        } else {
                            result.tag = .identifier;
                        }
                    },
                }
            },
            .underscore => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    'a'...'z', 'A'...'Z', '0'...'9', '-', '_' => continue :state .identifier,
                    else => result.tag = .underscore,
                }
            },
            .plus => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '=' => {
                        result.tag = .plus_equal;
                        self.index += 1;
                    },
                    else => result.tag = .plus,
                }
            },
            .minus => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '=' => {
                        result.tag = .minus_equal;
                        self.index += 1;
                    },
                    else => result.tag = .minus,
                }
            },
            .slash => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '=' => {
                        result.tag = .slash_equal;
                        self.index += 1;
                    },
                    '/' => continue :state .line_comment_start,
                    else => result.tag = .slash,
                }
            },
            .period => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '.' => {
                        result.tag = .period_period;
                        self.index += 1;
                    },
                    else => result.tag = .period,
                }
            },
            .equal => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '=' => {
                        result.tag = .equal_equal;
                        self.index += 1;
                    },
                    else => result.tag = .equal,
                }
            },
            .bang => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '=' => {
                        result.tag = .bang_equal;
                        self.index += 1;
                    },
                    else => result.tag = .bang,
                }
            },
            .angle_bracket_left => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '=' => {
                        result.tag = .angle_bracket_left_equal;
                        self.index += 1;
                    },
                    else => result.tag = .angle_bracket_left,
                }
            },
            .angle_bracket_right => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '=' => {
                        result.tag = .angle_bracket_right_equal;
                        self.index += 1;
                    },
                    else => result.tag = .angle_bracket_right,
                }
            },
            .asterisk => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '=' => {
                        result.tag = .asterisk_equal;
                        self.index += 1;
                    },
                    else => result.tag = .asterisk,
                }
            },
            .hash => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '!' => {
                        result.tag = .shebang;
                        self.index += 1;
                    },
                    else => result.tag = .hash,
                }
            },
            .line_comment_start => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    0 => {
                        if (self.index != self.buffer.len) {
                            continue :state .invalid;
                        } else return .{
                            .tag = .eof,
                            .loc = .{
                                .start = self.index,
                                .end = self.index,
                            },
                        };
                    },
                    '\n' => {
                        std.debug.print("at line_comment_start - 0\n", .{});
                        self.index += 1;
                        result.loc.start = self.index;
                        continue :state .start;
                    },
                    '\r' => continue :state .expect_newline,
                    0x01...0x09, 0x0b...0x0c, 0x0e...0x1f, 0x7f => {
                        continue :state .invalid;
                    },
                    else => continue :state .line_comment,
                }
            },
            .line_comment => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    0 => {
                        if (self.index != self.buffer.len) {
                            continue :state .invalid;
                        } else return .{
                            .tag = .eof,
                            .loc = .{
                                .start = self.index,
                                .end = self.index,
                            },
                        };
                    },
                    '\n' => {
                        self.index += 1;
                        result.loc.start = self.index;
                        continue :state .start;
                    },
                    '\r' => continue :state .expect_newline,
                    0x01...0x09, 0x0b...0x0c, 0x0e...0x1f, 0x7f => {
                        continue :state .invalid;
                    },
                    else => continue :state .line_comment,
                }
            },
            .expect_newline => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    0 => {
                        if (self.index == self.buffer.len) {
                            result.tag = .invalid;
                        } else {
                            continue :state .invalid;
                        }
                    },
                    '\n' => {
                        self.index += 1;
                        result.loc.start = self.index;
                        continue :state .start;
                    },
                    else => continue :state .invalid,
                }
            },
        }
        result.loc.end = self.index;
        return result;
    }
};

test "keywords" {
    try testTokenize("let set while", &.{ .keyword_let, .keyword_set, .keyword_while });
}

test "utf-8 BOM is identified and skipped" {
    try testTokenize("\xEF\xBB\xBFa;\n", &.{ .identifier, .semicolon });
}

test "mult-character tokens" {
    try testTokenize(
        \\_a 
        \\+= 
        \\-= 
        \\/= 
        \\== 
        \\!=
        \\<=
        \\>=
        \\*=
        \\..
        \\#!
        \\/=
        \\#!
    , &.{
        .identifier,
        .plus_equal,
        .minus_equal,
        .slash_equal,
        .equal_equal,
        .bang_equal,
        .angle_bracket_left_equal,
        .angle_bracket_right_equal,
        .asterisk_equal,
        .period_period,
        .shebang,
        .slash_equal,
        .shebang,
    });
}

test "lang grammar" {
    try testTokenize(
        \\ident
        \\id_nt
        \\id3nt
        \\_ident
        \\_Id3Nt_
        \\let set while {}
        \\$
        \\ _a
        \\ _
        \\ +  
        \\ ^
        \\ *
        \\ !
        \\ #
        \\ /
    , &.{
        .identifier,
        .identifier,
        .identifier,
        .identifier,
        .identifier,
        .keyword_let,
        .keyword_set,
        .keyword_while,
        .l_brace,
        .r_brace,
        .dollar,
        .identifier,
        .underscore,
        .plus,
        .caret,
        .asterisk,
        .bang,
        .hash,
        .slash,
    });
}

fn testTokenize(source: [:0]const u8, expected_tags: []const Token.Tag) !void {
    var tokenizer = Tokenizer.init(source);
    for (expected_tags) |expected_tag| {
        const token = tokenizer.next();
        try std.testing.expectEqual(expected_tag, token.tag);
    }

    // last token is always eof
    const last_token = tokenizer.next();
    try std.testing.expectEqual(Token.Tag.eof, last_token.tag);
    try std.testing.expectEqual(source.len, last_token.loc.start);
    try std.testing.expectEqual(source.len, last_token.loc.end);
}
