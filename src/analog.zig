const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
    @cInclude("rlgl.h");
});

const Analog = @This();

pos: rl.Vector2,
radius: f32,
hour: Hand = .{},
minute: Hand = .{},
ease_speed: f32 = 10.0,

const Hand = struct {
    angle: f32 = 0,
    target: f32 = 0,

    fn update(self: *Hand, dt: f32, speed: f32) void {
        self.angle += (self.target - self.angle) * speed * dt;
    }
};

pub fn setAngles(self: *Analog, hour_deg: f32, minute_deg: f32) void {
    self.hour.target = hour_deg * rl.DEG2RAD;
    self.minute.target = minute_deg * rl.DEG2RAD;
}

pub fn update(self: *Analog, dt: f32) void {
    self.hour.update(dt, self.ease_speed);
    self.minute.update(dt, self.ease_speed);
}

pub fn draw(self: Analog) void {

    // Inner subtle ring
    rl.DrawRing(self.pos, self.radius * 0.95, self.radius, 0, 360, 60, rl.Fade(rl.Color{ .r = 220, .g = 225, .b = 235, .a = 255 }, 0.15));
    const length = self.radius * 0.9;
    const thickness = self.radius / 5;
    self.drawHand(self.hour.angle, length, thickness, rl.Color{ .r = 247, .g = 164, .b = 30, .a = 255 });
    self.drawHand(self.minute.angle, length, thickness, rl.Color{ .r = 247, .g = 164, .b = 30, .a = 255 });
}

fn drawHand(self: Analog, angle: f32, length: f32, thickness: f32, color: rl.Color) void {
    const offset = thickness / 2;
    const cos_val = rl.cosf(angle - rl.PI / 2);
    const sin_val = rl.sinf(angle - rl.PI / 2);

    const start = rl.Vector2{
        .x = self.pos.x - offset * cos_val,
        .y = self.pos.y - offset * sin_val,
    };
    const end = rl.Vector2{
        .x = self.pos.x + length * cos_val,
        .y = self.pos.y + length * sin_val,
    };

    rl.DrawLineEx(start, end, thickness, color);
}
