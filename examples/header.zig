//! An example program which reads out the EBML header information
const std = @import("std");
const ebml = @import("sebml");
const ids = ebml.ids;

pub fn main() !void {
    const args = std.os.argv;
    var filename = std.mem.span(args[1]);
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    var element = try ebml.Element.read(file, 0);
    while (true) {
        switch (element.id) {
            ids.ebml, ids.doc_type_extension => {
                element = try element.child(file);
                continue;
            },
            ids.ebml_version => std.log.info("EBML Version: {}", .{element.get(u8, null, file)}),
            ids.ebml_read_version => std.log.info("EBML Read Version: {}", .{element.get(u8, null, file)}),
            ids.ebml_max_id_length => std.log.info("EBML Max ID Length: {}", .{element.get(u8, null, file)}),
            ids.ebml_max_size_length => std.log.info("EBML Max Size Length: {}", .{element.get(u8, null, file)}),
            ids.doc_type => {
                var doctype = try element.get_slice(std.testing.allocator, file);
                defer std.testing.allocator.free(doctype);
                std.log.info("Doc Type: {}", .{doctype});
            },
            ids.doc_type_version => std.log.info("Doc Type Version: {}", .{element.get(u8, null, file)}),
            ids.doc_type_read_version => std.log.info("Doc Type Read Version: {}", .{element.get(u8, null, file)}),
            ids.doc_type_extension_name => {
                var name = try element.get_slice(std.testing.allocator, file);
                defer std.testing.allocator.free(name);
                std.log.info("Doc Type Extension Name: {}", .{name});
            },
            ids.doc_type_extension_version => std.log.info("Doc Type Extension Version: {}", .{element.get(u8, null, file)}),
            else => break,
        }
        element = try element.next(file);
    }
}
