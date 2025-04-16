const std = @import("std");
const rl = @import("raylib");
const math = std.math;

const WINDOW_HEIGHT: f32 = 1000;
const WINDOW_WIDTH: f32 = 1000;
const WINDOW_BG_COLOR = rl.Color{ .r = 20, .g = 20, .b = 20, .a = 255 };
const ARENA_SIZE: f32 = 800;

const TARGET_FPS: f32 = 60;
const SCALED_UNIT: f32 = ARENA_SIZE / 1000;
const FIXED_TURN: f32 = math.pi * 2 / TARGET_FPS / 2; // 1/2 360-degree-turn per second on any framerate
const FIXED_SPEED: f32 = SCALED_UNIT * 30 / TARGET_FPS;

const ARENA = Arena{};

pub fn main() !void {
    rl.initWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "zig-fever");
    defer rl.closeWindow();

    rl.setTargetFPS(TARGET_FPS);

    var players = [_]Player{ Player.init(.{ .x = 100, .y = 100 }, 68, 70, .red), Player.init(.{ .x = 50, .y = 300 }, 74, 75, .blue) };

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(WINDOW_BG_COLOR);

        ARENA.render();
        for (0..players.len) |i| {
            players[i].update();
            players[i].renderPath();
            players[i].renderPoint();
        }
    }
}

const Arena = struct {
    width: f32 = ARENA_SIZE,
    height: f32 = ARENA_SIZE,
    position: rl.Vector2 = .{ .x = 10, .y = 10 },

    pub fn render(self: Arena) void {
        const x = @as(i32, @intFromFloat(self.position.x));
        const y = @as(i32, @intFromFloat(self.position.y));
        const width = @as(i32, @intFromFloat(self.width));
        const height = @as(i32, @intFromFloat(self.height));
        rl.drawRectangleLines(x, y, width, height, .white);
    }
};

const Player = struct {
    alive: bool = true,
    radius: f32 = 5,
    radiusMult: f32 = 1,
    speedMult: f32 = 1,
    dirAngle: f32 = 0,
    dirAngleMult: f32 = 1,
    dirCoords: rl.Vector2 = .{ .x = 0, .y = 0 },
    currPosition: rl.Vector2 = .{ .x = 400, .y = 300 },
    leftKey: rl.KeyboardKey,
    rightKey: rl.KeyboardKey,
    color: rl.Color = .blue,
    path: std.ArrayList(rl.Vector2) = std.ArrayList(rl.Vector2).init(std.heap.page_allocator),

    pub fn init(position: rl.Vector2, leftKeyASCII: c_int, rightKeyASCII: c_int, color: rl.Color) Player {
        const leftKey: rl.KeyboardKey = @enumFromInt(leftKeyASCII);
        const rightKey: rl.KeyboardKey = @enumFromInt(rightKeyASCII);

        var player = Player{ .currPosition = position, .leftKey = leftKey, .rightKey = rightKey, .color = color };
        player.path.append(position) catch std.debug.print("Could not append starting position to player", .{});
        return player;
    }

    pub fn update(self: *Player) void {
        if (!self.alive) {
            return;
        }
        self.updatePosition();
        self.checkArenaCollision();
    }

    pub fn renderPath(self: *Player) void {
        var pathToDraw = self.path.clone() catch return;
        pathToDraw.append(self.currPosition) catch return;
        rl.drawSplineLinear(pathToDraw.items, 2.0 * (self.radius - 1), self.color);
    }

    pub fn renderPoint(self: *Player) void {
        const scaledRadius = SCALED_UNIT * self.radius;
        rl.drawCircle(@intFromFloat(self.currPosition.x), @intFromFloat(self.currPosition.y), scaledRadius, .white);
    }

    fn checkArenaCollision(self: *Player) void {
        const playerLeft = self.currPosition.x - self.radius;
        const playerRight = self.currPosition.x + self.radius;
        const playerTop = self.currPosition.y - self.radius;
        const playerBottom = self.currPosition.y + self.radius;
        const arenaPos = ARENA.position;

        if (playerLeft < arenaPos.x or playerRight > arenaPos.x + ARENA.width) {
            self.alive = false;
        }

        if (playerTop < arenaPos.y or playerBottom > arenaPos.y + ARENA.width) {
            self.alive = false;
        }
    }

    fn updatePosition(self: *Player) void {
        var turned = false;
        if (rl.isKeyDown(self.leftKey)) {
            self.dirAngle -= FIXED_TURN * self.dirAngleMult;
            turned = true;
        }
        if (rl.isKeyDown(self.rightKey)) {
            self.dirAngle += FIXED_TURN * self.dirAngleMult;
            turned = true;
        }
        const nDirCoordsX = FIXED_SPEED * SCALED_UNIT * self.radius * math.cos(self.dirAngle) * self.speedMult;
        const nDirCoordsY = FIXED_SPEED * SCALED_UNIT * self.radius * math.sin(self.dirAngle) * self.speedMult;
        self.dirCoords = .{ .x = nDirCoordsX, .y = nDirCoordsY };

        const nPosX = self.currPosition.x + self.dirCoords.x;
        const nPosY = self.currPosition.y + self.dirCoords.y;
        self.currPosition = .{ .x = nPosX, .y = nPosY };

        if (turned) {
            self.path.append(self.currPosition) catch return;
            std.debug.print("{}\n", .{ self.path.items.len});
        }
    }
};
