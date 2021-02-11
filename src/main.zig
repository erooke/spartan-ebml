const std = @import("std");
const builtin = @import("builtin");
const testing = std.testing;

pub const VInt = @import("vint.zig");

const Allocator = std.mem.Allocator;
const File = std.fs.File;

pub const ids = @import("element_ids.zig");

/// Records the ID, location, and width of an EBML element in a file.
pub const Element = struct {
    id: u64,
    data_size: u64,
    offset: u64,

    /// Attempts to read an element from the file at the specified offset.
    pub fn read(file: File, offset: u64) !Element {
        var buffer: [32]u8 = undefined;
        _ = try file.pread(&buffer, offset);
        const element_id = VInt.parse(&buffer);
        const element_size = VInt.parse(buffer[element_id.width..]);
        return Element{
            .id = element_id.data,
            .data_size = element_size.data,
            .offset = offset + element_id.width + element_size.width,
        };
    }

    /// Returns the element next to this one in the file. Note this means
    /// literally located next to it in the encoding. In particular this can
    /// cause you change levels in the encoded tree.
    pub fn next(self: *const Element, file: File) !Element {
        return Element.read(file, self.offset + self.data_size);
    }

    /// Descend into the tree contained in this element. Caller is expected to
    /// know that this is a master element, weird things will happen if it is
    /// not.
    pub fn child(self: *const Element, file: File) !Element {
        return Element.read(file, self.offset);
    }

    /// Read the bytes defining the payload of the EBML element. Caller owns
    /// the data. Errors if it fails to read the whole payload.
    pub fn get_slice(self: *const Element, allocator: *Allocator, file: File) ![]u8 {
        if (self.data_size == 0) return "";
        var buffer = try allocator.alloc(u8, self.data_size);
        errdefer allocator.free(buffer);
        const bytes_read = try file.pread(buffer, self.offset);
        if (bytes_read != self.data_size) return error.EOF;
        return buffer;
    }

    /// Parse the payload to a known Zig type. For 0 length elements the default
    /// is returned if defined else the predefined global default is used. See
    /// section 7 of the spec for more details.
    pub fn get(self: *const Element, comptime T: type, default: ?T, file: File) !T {
        switch (@typeInfo(T)) {
            .Int => |i| {
                if (self.data_size == 0) return default orelse 0;
                comptime const len = try std.math.divCeil(usize, i.bits, 8);
                comptime if (len > 8) @compileError(@typeName(T) ++ " not supported. EBML only supports up to 64 bit ints");
                var buffer: [len]u8 = [1]u8{0} ** len;
                if (self.data_size > 8) return error.WrongSize;
                const bytes_read = try file.pread(buffer[len - self.data_size ..], self.offset);
                if (bytes_read != self.data_size) return error.EOF;
                return std.mem.readInt(T, &buffer, .Big);
            },
            .Float => {
                // TODO I assume the floats just line up with memory
                // representation. This has worked but may not be globally
                // correct.
                if (T != f32 and T != f64) @compileError(@typeName(T) ++ " not supported. EBML only supports 32 and 64 bit floats");
                switch (self.data_size) {
                    0 => return default orelse 0,
                    4 => {
                        var buffer: [4]u8 = undefined;
                        const bytes_read = try file.pread(&buffer, self.offset);
                        if (bytes_read != 4) return error.EOF;
                        if (builtin.endian != .Big) std.mem.reverse(u8, &buffer);
                        const short = std.mem.bytesToValue(f32, &buffer);
                        return @floatCast(T, short);
                    },
                    8 => {
                        var buffer: [8]u8 = undefined;
                        const bytes_read = try file.pread(&buffer, self.offset);
                        if (bytes_read != 8) return error.EOF;
                        if (builtin.endian != .Big) std.mem.reverse(u8, &buffer);
                        const short = std.mem.bytesToValue(f64, &buffer);
                        return @floatCast(T, short);
                    },
                    else => return error.WrongSize,
                }
            },
            .Pointer => |p| {
                comptime if (p.size != .Slice) @compileError(@typeName(T) ++ " not supported. EBML only encodes ints, floats, and byte arrays");
                @compileError("See get_slice to read the underlying bytes");
            },
            else => @compileError(@typeName(T) ++ " not supported. EBML only encodes ints, floats, and byte arrays"),
        }
    }
};
