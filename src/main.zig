const std = @import("std");
const rl = @import("raylib");
const math = std.math;

const WINDOW_HEIGHT: f32 = 1000;
const WINDOW_WIDTH: f32 = 1000;
const WINDOW_BG_COLOR = rl.Color{ .r = 100, .g = 20, .b = 20, .a = 255 };
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


    rl.drawRectangleRec(rl.Rectangle{ .x = 0, .y = 0, .width = WINDOW_WIDTH, .height = WINDOW_HEIGHT }, WINDOW_BG_COLOR);
    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        // rl.clearBackground(WINDOW_BG_COLOR);

        ARENA.render();
        for (0..players.len) |i| {
            players[i].update();
            //players[i].renderPoint();
            players[i].renderPath();
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
    thickness: f32 = 5,
    thicknessMult: f32 = 1,
    speedMult: f32 = 1,
    dirAngle: f32 = 0,
    dirAngleMult: f32 = 1,
    dirCoords: rl.Vector2 = .{ .x = 0, .y = 0 },
    currPosition: rl.Vector2 = .{ .x = 400, .y = 300 },
    prevPosition: rl.Vector2 = .{ .x = 400, .y = 300 },
    leftKey: rl.KeyboardKey,
    rightKey: rl.KeyboardKey,
    color: rl.Color = .blue,

    pub fn init(position: rl.Vector2, leftKeyASCII: c_int, rightKeyASCII: c_int, color: rl.Color) Player {
        const leftKey: rl.KeyboardKey = @enumFromInt(leftKeyASCII);
        const rightKey: rl.KeyboardKey = @enumFromInt(rightKeyASCII);
        return Player{ .currPosition = position, .prevPosition = position, .leftKey = leftKey, .rightKey = rightKey, .color = color };
    }

    pub fn update(self: *Player) void {
        if (!self.alive) {
            return;
        }
        self.updatePosition();
        self.checkArenaCollision();
    }

    pub fn renderPath(self: *Player) void {
        rl.drawLineEx(self.prevPosition, self.currPosition, 2.0 * (self.thickness - 1), self.color);
    }

    pub fn renderPoint(self: *Player) void {
        const scaledRadius = SCALED_UNIT * self.thickness;
        rl.drawCircle(@intFromFloat(self.currPosition.x), @intFromFloat(self.currPosition.y), scaledRadius, self.color);
    }

    fn checkArenaCollision(self: *Player) void {
        const playerLeft = self.currPosition.x - self.thickness;
        const playerRight = self.currPosition.x + self.thickness;
        const playerTop = self.currPosition.y - self.thickness;
        const playerBottom = self.currPosition.y + self.thickness;
        const arenaPos = ARENA.position;
        if (playerLeft < arenaPos.x or playerRight > arenaPos.x + ARENA.width) {
            self.alive = false;
        }
        if (playerTop < arenaPos.y or playerBottom > arenaPos.y + ARENA.width) {
            self.alive = false;
        }
    }

    fn updatePosition(self: *Player) void {
        if (rl.isKeyDown(self.leftKey)) {
            self.dirAngle -= FIXED_TURN * self.dirAngleMult;
        }
        if (rl.isKeyDown(self.rightKey)) {
            self.dirAngle += FIXED_TURN * self.dirAngleMult;
        }
        const nDirCoordsX = FIXED_SPEED * SCALED_UNIT * self.thickness * math.cos(self.dirAngle) * self.speedMult;
        const nDirCoordsY = FIXED_SPEED * SCALED_UNIT * self.thickness * math.sin(self.dirAngle) * self.speedMult;
        self.dirCoords = .{ .x = nDirCoordsX, .y = nDirCoordsY };

        const nPosX = self.currPosition.x + self.dirCoords.x;
        const nPosY = self.currPosition.y + self.dirCoords.y;
        self.prevPosition = self.currPosition;
        self.currPosition = .{ .x = nPosX, .y = nPosY };

        const image = rl.loadImageFromScreen() catch return;
        defer image.unload();
        const bgColor = image.getColor(@intFromFloat(nPosX), @intFromFloat(nPosY));
        std.debug.print("{} {} {} \n", .{ bgColor.r, bgColor.g, bgColor.b });
        const isBlack = bgColor.r == 0 and bgColor.g == 0 and bgColor.b == 0; 
        if (!isBlack) {
            self.alive = false;
        }
    }
};
