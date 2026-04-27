const std = @import("std");
const partInt = std.fmt.parseInt;

const tokenizer = @import("tokenizer.zig");

pub fn main(init: std.process.Init) !void {
    var debugAllocator = std.heap.DebugAllocator(.{
        .stack_trace_frames = 16,
    }).init;
    defer _ = debugAllocator.deinit();

    const gpa = debugAllocator.allocator();
    const args = try parseArgs(init.minimal);
    try run(gpa, args, init);
}

pub fn run(allocator: std.mem.Allocator, args: Args, init: std.process.Init) !void {
    const path = args.path;

    // compiler
    {
        const dir = std.Io.Dir.cwd();
        const buf = try std.Io.Dir.readFileAllocOptions(
            dir,
            init.io,
            path,
            allocator,
            .unlimited,
            std.mem.Alignment.fromByteUnits(8),
            0, // null terminated
        );
        defer allocator.free(buf);

        var tok = tokenizer.Tokenizer.init(buf);

        if (args.mode == .tokenize) {
            while (tok.next()) |token| {
                std.debug.print("{}: {s}\n", .{
                    token.tag,
                    buf[token.loc.start..token.loc.end],
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

fn parseArgs(init: std.process.Init.Minimal) !Args {
    // zig build run -- lex assets/intro.typ

    var buffer: [2000]u8 = undefined;
    var fba: std.heap.FixedBufferAllocator = .init(&buffer);
    const allocator = fba.allocator();
    var args = try init.args.iterateAllocator(allocator);
    defer args.deinit();
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
