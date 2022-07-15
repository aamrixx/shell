const std = @import("std");

pub fn main() !u8 {
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();
    try stdout.print("welcome to amsh (amrix's shell)\n", .{});
    try shellLoop(stdin, stdout);

    return 0; // We either crash or we are fine.
}

fn shellLoop(stdin: std.fs.File.Reader, stdout: std.fs.File.Writer) !void {
    while (true) {
        const max_input = 1024;
        const max_args = 10;
        const max_arg_size = 255;

        try stdout.print("~> ", .{});

        var input_buffer: [max_input]u8 = undefined;
        var input_str = (try stdin.readUntilDelimiterOrEof(input_buffer[0..], '\n')) orelse {
            try stdout.print("\n", .{});
            return;
        };

        if (input_str.len == 0) continue;

        var args: [max_args][max_arg_size:0]u8 = undefined;
        var args_ptrs: [max_args:null]?[*:0]u8 = undefined;

        var tokens = std.mem.tokenize(u8, input_str, " ");

        var i: usize = 0;
        while (tokens.next()) |tok| {
            std.mem.copy(u8, &args[i], tok);
            args[i][tok.len] = 0;
            args_ptrs[i] = &args[i];
            i += 1;
        }
        args_ptrs[i] = null;

        const fork_pid = try std.os.fork();

        if (fork_pid == 0) {
            const env = [_:null]?[*:0]u8{null};
            const result = std.os.execvpeZ(args_ptrs[0].?, &args_ptrs, &env);

            try stdout.print("ERROR: {}\n", .{result});
            return;
        } else {
            const wait_result = std.os.waitpid(fork_pid, 0);
 
            if (wait_result.status != 0) {
                try stdout.print("Command returned {}.\n", .{wait_result.status});
            }
        }
    }
}