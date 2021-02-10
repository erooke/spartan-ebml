const std = @import("std");

test "Leading 0's" {
    const cases = [_]u8{
        0b10000011,
        0b01010000,
        0b00101000,
        0b00010010,
        0b00001100,
        0b00000110,
        0b00000011,
        0b00000001,
    };

    for (cases) |case, i| testing.expectEqual(leading_zeros(case), @intCast(u3, i));
}

/// Given a byte returns the number of leading zeros. Does not work on 0 due to
/// the u3 restriction. Which is necessary for the compiler to let us bitshift
/// later. Caller is expected to make sure 0 is not passed.
fn leading_zeros(byte: u8) u3 {
    if (byte >= 128) return 0;
    if (byte >= 64) return 1;
    if (byte >= 32) return 2;
    if (byte >= 16) return 3;
    if (byte >= 8) return 4;
    if (byte >= 4) return 5;
    if (byte >= 2) return 6;
    if (byte >= 1) return 7;
    unreachable;
}

/// Encodes a variable width int. Recording the width of the representation and
/// the data stored.
pub const VInt = struct {
    width: u4,
    data: u64,
};

test "Parsing variable width ints" {
    const test_case = struct {
        input: []const u8,
        output: VInt,
    };

    const cases = [_]test_case{
        .{
            .input = &[_]u8{
                0b10001011,
            },
            .output = .{
                .width = 1,
                .data = 11,
            },
        },
        .{
            .input = &[_]u8{
                0b01000001,
                0b00000010,
            },
            .output = .{
                .width = 2,
                .data = 258,
            },
        },
        .{
            .input = &[_]u8{
                0b00100000,
                0b00000000,
                0b00001011,
            },
            .output = .{
                .width = 3,
                .data = 11,
            },
        },
    };

    for (cases) |case| {
        std.testing.expectEqual(case.output, parse_vint(case.input));
    }
}

/// Given a slice of bytes, read a variable width int. Ignores any bytes past
/// the declared width.
pub fn parse(bytes: []const u8) VInt {
    // TODO: We assume VInts max at 8 bytes long.
    // This has yet to cause an issue, but I don't think its correct
    var buffer: [8]u8 = [1]u8{0} ** 8;
    const len: u3 = leading_zeros(bytes[0]);
    // offset needs to be a u3 to placate the compiler when we shift later
    const offset: u3 = 7 - len;
    const width: u4 = @as(u4, 1) + len;
    std.mem.copy(u8, buffer[offset..], bytes[0..width]);
    buffer[offset] &= ~@shlExact(@as(u8, 1), offset); // Removes the vint marker
    const data = std.mem.readInt(u64, &buffer, .Big);
    return .{ .data = data, .width = width };
}
