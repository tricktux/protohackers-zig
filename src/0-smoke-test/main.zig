const std = @import("std");
const builtin = @import("builtin");
const utils = @import("utils");
const log = utils.logger;
const debug = std.log.debug;

// Constants
const name: []const u8 = "0.0.0.0";
const port = 18888;
const buff_size = 4096;

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

    // Initialize allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    // Create server
    var server: std.net.Server = undefined;
    defer server.deinit();
    {
        const addrlist = try std.net.getAddressList(allocator, name, port);
        defer addrlist.deinit();
        debug("Got Addresses: '{s}'!!!", .{addrlist.canon_name.?});

        for (addrlist.addrs) |addr| {
            debug("\tTrying to listen...", .{});
            // Not intuitive but `listen` calls `socket, bind, and listen`
            server = addr.listen(.{}) catch continue;
            debug("\tGot one!", .{});
            break;
        }
    }
    const cpus = try std.Thread.getCpuCount();
    var tp: std.Thread.Pool = undefined;
    try tp.init(.{ .allocator = allocator, .n_jobs = @as(u32, @intCast(cpus)) });
    defer tp.deinit();

    debug("ThreadPool initialized with {} capacity", .{cpus});
    debug("We are listeninig baby!!!...", .{});
    while (true) {
        debug("waiting for a new connection...", .{});
        const connection = try server.accept();
        debug("got new connection!!!", .{});
        try tp.spawn(handle_connection, .{connection});
    }
}

fn handle_connection(connection: std.net.Server.Connection) void {
    var read_buff: [buff_size]u8 = undefined;
    var write_buff: [buff_size]u8 = undefined;
    const stream = connection.stream;
    defer stream.close();

    // Initialize Reader and Writer
    var reader = stream.reader(&read_buff);
    const sri = reader.interface();
    var writer = stream.writer(&write_buff);
    var swi = &writer.interface;

    while (true) {
        debug("\twaiting for some data...", .{});
        const line = sri.takeDelimiter('\n') catch |err| switch (err) {
            error.ReadFailed => {
                debug("\tERROR: error reading failed... closing this connection", .{});
                return;
            },
            error.StreamTooLong => {
                // Please allocate more buffer space
                debug("\tERROR: delimiter not found within buf capacity... closing this connection", .{});
                return;
            }
        };

        if (line == null) {
            debug("\tConnection closed by client.", .{});
            return;
        }
        debug("\tGot: {s}", .{line.?});

        // Send the data back
        swi.writeAll(line.?) catch |err| {
            debug("\tERROR: error writeAll function {}... closing this connection", .{err});
            return;
        };
        swi.flush() catch |err| {
            debug("\tERROR: error flushing data {}... closing this connection", .{err});
            return;
        };
    }
}
