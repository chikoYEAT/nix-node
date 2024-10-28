const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "nix-node",
        .root_source_file = .{ .cwd_relative = "src/main.zig" }, // Changed from .path to .cwd_relative
        .target = target,
        .optimize = optimize,
    });

    const react_cmd = b.addSystemCommand(&.{
        "nix-shell",
        "-p",
        "nodejs",
        "--pure",
        "--run",
        "npx create-react-app",
    });

    const svelte_cmd = b.addSystemCommand(&.{
        "nix-shell",
        "-p",
        "nodejs",
        "--pure",
        "--run",
        "npx create-vite@latest",
    });

    const react_step = b.step("react", "Create new React project");
    if (b.args) |args| {
        react_cmd.addArgs(args);
    }
    react_step.dependOn(&react_cmd.step);

    const svelte_step = b.step("svelte", "Create new Svelte project");
    if (b.args) |args| {
        svelte_cmd.addArgs(args);
    }
    svelte_step.dependOn(&svelte_cmd.step);

    const dev_cmd = b.addSystemCommand(&.{
        "nix-shell",
        "-p",
        "nodejs",
        "zig",
        "--pure",
    });
    const dev_step = b.step("dev", "Setup development environment");
    dev_step.dependOn(&dev_cmd.step);

    const pkg_cmd = b.addSystemCommand(&.{
        "nix-env",
        "-iA",
        "nixpkgs.nodejs",
    });
    const pkg_step = b.step("pkg", "Install Node.js using Nix");
    pkg_step.dependOn(&pkg_cmd.step);

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
