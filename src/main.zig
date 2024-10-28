const std = @import("std");
const fs = std.fs;
const process = std.process;
const json = std.json;

const NixNodeCommand = enum {
    install,
    create,
};

const Framework = enum {
    react,
    svelte,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = try process.argsWithAllocator(allocator);
    defer args.deinit();

    _ = args.skip();

    const command = args.next() orelse {
        try std.io.getStdErr().writer().writeAll("Usage: nix-node <command> [options]\n");
        return;
    };

    if (std.mem.eql(u8, command, "install")) {
        try handleInstall(allocator, &args);
    } else if (std.mem.eql(u8, command, "create")) {
        try handleCreate(allocator, &args);
    } else {
        try std.io.getStdErr().writer().writeAll("Unknown command\n");
        return;
    }
}

fn handleInstall(allocator: std.mem.Allocator, args: *process.ArgIterator) !void {
    const package_name = args.next() orelse {
        try std.io.getStdErr().writer().writeAll("Package name required\n");
        return;
    };

    var package_nix = try fs.cwd().createFile("package.nix", .{});
    defer package_nix.close();

    const nix_content = try std.fmt.allocPrint(allocator,
        \\{ pkgs ? import <nixpkgs> {} }:
        \\
        \\pkgs.stdenv.mkDerivation {
        \\  name = "node-project";
        \\  buildInputs = with pkgs; [
        \\    nodejs
        \\    {s}
        \\  ];
        \\}
    , .{package_name});
    defer allocator.free(nix_content);

    try package_nix.writeAll(nix_content);
}

fn handleCreate(allocator: std.mem.Allocator, args: *process.ArgIterator) !void {
    const framework = args.next() orelse {
        try std.io.getStdErr().writer().writeAll("Framework type required (react/svelte)\n");
        return;
    };

    const app_name = args.next() orelse {
        try std.io.getStdErr().writer().writeAll("App name required\n");
        return;
    };

    try fs.cwd().makePath(app_name);
    try fs.cwd().makePath(try std.fmt.allocPrint(allocator, "{s}/src", .{app_name}));

    if (std.mem.eql(u8, framework, "react")) {
        try createReactTemplate(allocator, app_name);
    } else if (std.mem.eql(u8, framework, "svelte")) {
        try createSvelteTemplate(allocator, app_name);
    }
}

fn createReactTemplate(allocator: std.mem.Allocator, app_name: []const u8) !void {
    const package_nix_content =
        \\{ pkgs ? import <nixpkgs> {} }:
        \\
        \\pkgs.stdenv.mkDerivation {
        \\  name = "react-app";
        \\  buildInputs = with pkgs; [
        \\    nodejs
        \\    react
        \\    webpack
        \\  ];
        \\  
        \\  shellHook = ''
        \\    export PATH="$PWD/node_modules/.bin:$PATH"
        \\  '';
        \\}
    ;

    var package_nix = try fs.cwd().createFile(try std.fmt.allocPrint(allocator, "{s}/package.nix", .{app_name}), .{});
    defer package_nix.close();
    try package_nix.writeAll(package_nix_content);

    const build_zig_content =
        \\const std = @import("std");
        \\
        \\pub fn build(b: *std.Build) void {
        \\    const target = b.standardTargetOptions(.{});
        \\    const optimize = b.standardOptimizeOption(.{});
        \\
        \\    const exe = b.addExecutable(.{
        \\        .name = "nix-node",
        \\        .root_source_file = .{ .path = "src/main.zig" },
        \\        .target = target,
        \\        .optimize = optimize,
        \\    });
        \\
        \\    b.installArtifact(exe);
        \\}
    ;

    var build_zig = try fs.cwd().createFile(try std.fmt.allocPrint(allocator, "{s}/build.zig", .{app_name}), .{});
    defer build_zig.close();
    try build_zig.writeAll(build_zig_content);
}

fn createSvelteTemplate(allocator: std.mem.Allocator, app_name: []const u8) !void {
    const package_nix_content =
        \\{ pkgs ? import <nixpkgs> {} }:
        \\
        \\pkgs.stdenv.mkDerivation {
        \\  name = "svelte-app";
        \\  buildInputs = with pkgs; [
        \\    nodejs
        \\    svelte
        \\    rollup
        \\  ];
        \\  
        \\  shellHook = ''
        \\    export PATH="$PWD/node_modules/.bin:$PATH"
        \\  '';
        \\}
    ;

    var package_nix = try fs.cwd().createFile(try std.fmt.allocPrint(allocator, "{s}/package.nix", .{app_name}), .{});
    defer package_nix.close();
    try package_nix.writeAll(package_nix_content);
    const build_zig_content =
        \\const std = @import("std");
        \\
        \\pub fn build(b: *std.Build) void {
        \\    const target = b.standardTargetOptions(.{});
        \\    const optimize = b.standardOptimizeOption(.{});
        \\
        \\    const exe = b.addExecutable(.{
        \\        .name = "nix-node",
        \\        .root_source_file = .{ .path = "src/main.zig" },
        \\        .target = target,
        \\        .optimize = optimize,
        \\    });
        \\
        \\    b.installArtifact(exe);
        \\}
    ;

    var build_zig = try fs.cwd().createFile(try std.fmt.allocPrint(allocator, "{s}/build.zig", .{app_name}), .{});
    defer build_zig.close();
    try build_zig.writeAll(build_zig_content);
}
