const std = @import("std");
const zap = @import("zap");
const WebSockets = zap.WebSockets;

const Context = struct {
    channel: []const u8,
    // we need to hold on to them and just re-use them for every incoming
    // connection
    subscribeArgs: WebsocketHandler.SubscribeArgs,
    settings: WebsocketHandler.WebSocketSettings,
};

const Event = struct {
    id: []const u8,
    created_at: u32,
    sig: []const u8,
    pubkey: []const u8,
    kind: u32,
    tags: [][][]const u8,
    content: []const u8,
};

const EventPayload = struct {
    *[5:0]u8,
    Event,
};

const ContextList = std.ArrayList(*Context);

const ContextManager = struct {
    allocator: std.mem.Allocator,
    channel: []const u8,
    lock: std.Thread.Mutex = .{},
    contexts: ContextList = undefined,

    const Self = @This();

    pub fn init(
        allocator: std.mem.Allocator,
        channelName: []const u8,
    ) Self {
        return .{
            .allocator = allocator,
            .channel = channelName,
            .contexts = ContextList.init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.contexts.deinit();
    }

    pub fn newContext(self: *Self) !*Context {
        self.lock.lock();
        defer self.lock.unlock();

        var ctx = try self.allocator.create(Context);
        ctx.* = .{
            .channel = self.channel,
            // used in subscribe()
            .subscribeArgs = .{
                .channel = self.channel,
                .force_text = true,
                .context = ctx,
            },
            // used in upgrade()
            .settings = .{
                .on_open = on_open_websocket,
                .on_close = on_close_websocket,
                .on_message = handle_websocket_message,
                .context = ctx,
            },
        };
        try self.contexts.append(ctx);
        return ctx;
    }
};

//
// Websocket Callbacks
//
fn on_open_websocket(context: ?*Context, handle: WebSockets.WsHandle) void {
    if (context) |ctx| {
        _ = WebsocketHandler.subscribe(handle, &ctx.subscribeArgs) catch |err| {
            std.log.err("Error opening websocket: {any}", .{err});
            return;
        };
    }
}

fn on_close_websocket(context: ?*Context, uuid: isize) void {
    _ = uuid;
    _ = context;
}

fn handle_websocket_message(
    context: ?*Context,
    _: WebSockets.WsHandle,
    message: []const u8,
    _: bool,
) void {
    if (context) |ctx| {
        var arena = std.heap.ArenaAllocator.init(GlobalContextManager.allocator);
        defer arena.deinit();
        const arena_alloc = arena.allocator();
        const maybe_payload: ?std.json.Parsed(EventPayload) =
            std.json.parseFromSlice(EventPayload, arena_alloc, message, .{}) catch null;

        if (maybe_payload) |e| {
            if (std.mem.eql(u8, e.value[0], "EVENT")) {
                var jsonbuf = arena_alloc.alloc(u8, 128) catch @panic("error");
                const json = std.fmt.bufPrint(jsonbuf, "[\"OK\",\"{s}\",true,\"\"]", .{e.value[1].id}) catch @panic("error");
                WebsocketHandler.publish(
                    .{ .channel = ctx.channel, .message = json },
                );
            }
        }
    }
}

//
// HTTP stuff
//
fn on_request(_: zap.SimpleRequest) void {}

fn on_upgrade(r: zap.SimpleRequest, target_protocol: []const u8) void {
    // make sure we're talking the right protocol
    if (!std.mem.eql(u8, target_protocol, "websocket")) {
        std.log.warn("received illegal protocol: {s}", .{target_protocol});
        r.setStatus(.bad_request);
        r.sendBody("400 - BAD REQUEST") catch unreachable;
        return;
    }
    var context = GlobalContextManager.newContext() catch |err| {
        std.log.err("Error creating context: {any}", .{err});
        return;
    };

    WebsocketHandler.upgrade(r.h, &context.settings) catch |err| {
        std.log.err("Error in websocketUpgrade(): {any}", .{err});
        return;
    };
    std.log.info("connection upgrade OK", .{});
}

// global variables, yeah!
var GlobalContextManager: ContextManager = undefined;

const WebsocketHandler = WebSockets.Handler(Context);

// here we go
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
    }){};
    var allocator = gpa.allocator();

    GlobalContextManager = ContextManager.init(allocator, "global");
    defer GlobalContextManager.deinit();

    // setup listener
    var listener = zap.SimpleHttpListener.init(
        .{
            .port = 8080,
            .on_request = on_request,
            .on_upgrade = on_upgrade,
            .max_clients = 100,
            .max_body_size = 1 * 1024,
            .log = false,
        },
    );
    try listener.listen();
    std.log.info("", .{});
    std.log.info("Connect to websocket on ws://localhost:8080.", .{});
    std.log.info("Terminate with CTRL+C", .{});

    zap.start(.{
        .threads = 2,
        .workers = 2,
    });
}
