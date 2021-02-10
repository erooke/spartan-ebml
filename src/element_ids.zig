//! This module provides the constants for elements which are present in all
//! EBML documents. Refer to sections 11.2 and 11.3 for what those are and
//! what they mean.
const VInt = @import("vint.zig");

/// Given a byte string compute the underlying id number
fn id(comptime bytes: []const u8) comptime u64 {
    return VInt.parse(bytes).data;
}

pub const ebml = id("\x1A\x45\xDF\xA3");
pub const ebml_version = id("\x42\x86");
pub const ebml_read_version = id("\x42\xF7");
pub const ebml_max_id_length = id("\x42\xF2");
pub const ebml_max_size_length = id("\x42\xF3");
pub const doc_type = id("\x42\x82");
pub const doc_type_version = id("\x42\x87");
pub const doc_type_read_version = id("\x42\x85");
pub const doc_type_extension = id("\x42\x81");
pub const doc_type_extension_name = id("\x42\x83");
pub const doc_type_extension_version = id("\x42\x84");
pub const crc_32 = id("\xBF");
pub const ebml_void = id("\xEC");
