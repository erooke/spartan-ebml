const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const lib = b.addStaticLibrary("sebml", "src/main.zig");
    lib.setBuildMode(mode);
    lib.install();

    var main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);

    const example_step = b.step("examples", "Build examples");

    const examples = [_][]const u8{
        "header",
        "mkvtitle",
    };

    inline for (examples) |name| {
        const example = b.addExecutable(name, "examples/" ++ name ++ ".zig");
        example.addPackagePath("sebml", "src/main.zig");
        example.setBuildMode(mode);
        example.install();
        example_step.dependOn(&example.step);
    }
}
