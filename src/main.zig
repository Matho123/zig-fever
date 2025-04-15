const std = @import("std");
const rl = @import("raylib");
const math = std.math;

const WINDOW_HEIGHT: f32 = 1000;
const WINDOW_WIDTH: f32 = 1000;
const WINDOW_BG_COLOR = rl.Color{ .r = 20, .g = 20, .b = 20, .a = 255 };
const ARENA_SIZE: f32 = 1000;

const TARGET_FPS: f32 = 60;
const SCALED_UNIT: f32 = ARENA_SIZE / 1000;
const FIXED_TURN: f32 = math.pi * 2 / TARGET_FPS / 2; // 1/2 360-degree-turn per second on any framerate
const FIXED_SPEED: f32 = SCALED_UNIT * 30 / TARGET_FPS;
 
pub fn main() !void {
    rl.initWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "zig-fever");
    defer rl.closeWindow();

    rl.setTargetFPS(TARGET_FPS);

    var players = [_]Player{ Player.init(.{ .x = 100, .y = 100 }, 68, 70), Player.init(.{ .x = 50, .y = 300 }, 74, 75) };

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(WINDOW_BG_COLOR);

        for (0..players.len) |i| {
            players[i].update();
            players[i].render();
        }
    }
}

const Player = struct {
    thickness: f32 = 5,
    thicknessMult: f32 = 1,
    speedMult: f32 = 1,
    dirAngle: f32 = 0,
    dirAngleMult: f32 = 1,
    dirCoords: rl.Vector2 = .{ .x = 0, .y = 0 },
    position: rl.Vector2 = .{ .x = 400, .y = 300 },
    leftKey: rl.KeyboardKey,
    rightKey: rl.KeyboardKey,

    pub fn init(position: rl.Vector2, leftKeyASCII: c_int, rightKeyASCII: c_int) Player {
        const leftKey: rl.KeyboardKey = @enumFromInt(leftKeyASCII);
        const rightKey: rl.KeyboardKey = @enumFromInt(rightKeyASCII);
        return Player{ .position = position, .leftKey = leftKey, .rightKey = rightKey };
    }

    pub fn update(self: *Player) void {
        self.updatePosition();
    }

    pub fn render(self: *Player) void {
        const scaledRadius = SCALED_UNIT * self.thickness;
        rl.drawCircle(@intFromFloat(self.position.x), @intFromFloat(self.position.y), scaledRadius, .white);
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

        const nPosX = self.position.x + self.dirCoords.x;
        const nPosY = self.position.y + self.dirCoords.y;
        self.position = .{ .x = nPosX, .y = nPosY };
    }
};
