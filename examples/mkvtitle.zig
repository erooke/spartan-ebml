//! An example program which reads out the title of an mkv file
const std = @import("std");
const ebml = @import("sebml");
const ids = ebml.ids;

fn id(comptime bytes: []const u8) comptime u64 {
    return ebml.VInt.parse(bytes).data;
}

const mkv_segment = id("\x18\x53\x80\x67");
const mkv_info = id("\x15\x49\xA9\x66");
const mkv_title = id("\x7B\xA9");

pub fn main() !void {
    const args = std.os.argv;
    var filename = std.mem.span(args[1]);
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    const stat = try file.stat();
    var element = try ebml.Element.read(file, 0);
    while (true) {
        switch (element.id) {
            mkv_segment, mkv_info => {
                element = try element.child(file);
                continue;
            },
            mkv_title => {
                var title = try element.get_slice(std.testing.allocator, file);
                defer std.testing.allocator.free(title);
                std.debug.print("Title: {}\n", .{title});
                return;
            },
            else => {},
        }
        if (element.offset + element.data_size > stat.size) break;
        element = try element.next(file);
    }
    std.log.info("No title found", .{});
}
