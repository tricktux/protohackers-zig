const std = @import("std");
const builtin = @import("builtin");
const utils = @import("utils");
const log = utils.logger;

// Configure logging at the root level
pub const std_options: std.Options = .{
    .log_level = switch (builtin.mode) {
        .Debug => .debug,
        .ReleaseFast => .debug,
        else => .debug,
    },
    .logFn = log.customLogFn,
};

pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    try log.init();
    defer log.deinit();
    // std.debug.print("All your {s} are belong to us.\n", .{"codebase"});
    std.log.debug("All your {s} are belong to us.", .{"codebase"});
    std.log.debug("All your {s} are belong to us.", .{"codebase"});
    std.log.debug("All your {s} are belong to us.", .{"codebase"});
    std.log.debug("All your {s} are belong to us.", .{"codebase"});
    std.log.debug("All your {s} are belong to us.", .{"codebase"});
    std.log.debug("All your {s} are belong to us.", .{"codebase"});
    std.log.debug("All your {s} are belong to us.", .{"codebase"});
}

test "simple test" {
    const gpa = std.testing.allocator;
    var list: std.ArrayList(i32) = .empty;
    defer list.deinit(gpa); // Try commenting this out and see if zig detects the memory leak!
    try list.append(gpa, 42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "fuzz example" {
    const Context = struct {
        fn testOne(context: @This(), input: []const u8) anyerror!void {
            _ = context;
            // Try passing `--fuzz` to `zig build test` and see if it manages to fail this test case!
            try std.testing.expect(!std.mem.eql(u8, "canyoufindme", input));
        }
    };
    try std.testing.fuzz(Context{}, Context.testOne, .{});
}
