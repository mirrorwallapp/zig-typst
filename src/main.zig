const std = @import("std");
const partInt = std.fmt.parseInt;

const tokenizer = @import("tokenizer.zig");

pub fn main() !void {
    var debugAllocator = std.heap.DebugAllocator(.{
        .stack_trace_frames = 16,
    }).init;
    defer _ = debugAllocator.deinit();

    const gpa = debugAllocator.allocator();
    const args = try parseArgs();
    try run(gpa, args);
}

pub fn run(allocator: std.mem.Allocator, args: Args) !void {
    const path = args.path;

    // compiler
    {
        const src = try std.fs.cwd().readFileAllocOptions(
            allocator,
            path,
            std.math.maxInt(usize),
            null,
            std.mem.Alignment.fromByteUnits(8),
            0,
        );
        defer allocator.free(src);

        var tok = tokenizer.Tokenizer.init(src);

        if (args.mode == .tokenize) {
            while (tok.next()) |token| {
                std.debug.print("{}: {s}\n", .{
                    token.tag,
                    src[token.loc.start..token.loc.end],
                });

                switch (token.tag) {
                    .invalid => return error.LexerError,
                    .eof => break,
                    else => {},
                }
            }

            return;
        }
    }
}

const Args = struct {
    path: []const u8,
    mode: Mode,
};

const Mode = enum {
    tokenize,
    parse,
    compile,
    codegen,
};

fn parseArgs() !Args {
    // zig build run -- lex assets/intro.typ
    var args = std.process.args();
    _ = args.skip();

    var path: []const u8 = "";
    var mode: Mode = .compile;

    var index: u8 = 0;
    while (args.next()) |arg| {
        if (index > 1) {
            return error.InvalidArgument;
        } else if (index == 0) {
            mode = std.meta.stringToEnum(Mode, arg[0..]) orelse
                return error.UnrecognizedFlag;
        } else {
            path = arg;
        }
        index += 1;
    }

    return .{ .path = path, .mode = mode };
}
