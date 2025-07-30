const std = @import("std");

pub fn testingsomestuff() !void {
    return error.oopsi;
}

test "testingsomestuff" {
    try std.testing.expectError(error.opsi, testingsomestuff());
}
