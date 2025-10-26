const Layout = @This();

radius: f32,
digit_width: f32,
digit_height: f32,
start_y: f32,
digit_positions: [6]f32,
colon_draw_x1: f32,
colon_draw_x2: f32,
colon_y: f32,

/// Calculates all screen positions based on window dimensions.
pub fn init(screen_width: i32, screen_height: i32) Layout {
    const digit_cols: f32 = 4.0;
    const digit_rows: f32 = 6.0;
    const margin: f32 = 40.0;
    const available_width = @as(f32, @floatFromInt(screen_width)) - margin * 2.0;
    const available_height = @as(f32, @floatFromInt(screen_height)) - margin * 2.0;

    const gap_between_digits: f32 = 0.5;
    // Simplified from 5.0 * gap + 2.0 * gap
    const total_gaps = 7.0 * gap_between_digits;
    const total_cols = digit_cols * 6.0 + total_gaps;

    const radius_from_width = available_width / (total_cols * 2.0);
    const radius_from_height = available_height / (digit_rows * 2.0);
    const radius = @min(radius_from_width, radius_from_height);

    const digit_width = digit_cols * (radius * 2.0);
    const digit_height = digit_rows * (radius * 2.0);
    const gap_width = gap_between_digits * (radius * 2.0);
    const gap_width_colon = gap_width * 3.0; // The wide gap for colons

    // Total width based on actual drawing logic
    const total_width = digit_width * 6.0 + gap_width * 3.0 + gap_width_colon * 2.0;
    const visual_center_offset = gap_width; // From original
    const start_x = (@as(f32, @floatFromInt(screen_width)) - total_width) / 2.0 + visual_center_offset;
    const start_y = (@as(f32, @floatFromInt(screen_height)) - digit_height) / 2.0;

    // Pre-calculate X position for each digit in a loop
    var digit_positions: [6]f32 = undefined;
    var x_pos = start_x;
    const gaps = [_]f32{ gap_width, gap_width_colon, gap_width, gap_width_colon, gap_width };

    digit_positions[0] = x_pos;
    for (&gaps, 1..) |gap, i| {
        x_pos += digit_width + gap;
        digit_positions[i] = x_pos;
    }

    // Pre-calculate colon positions (logic preserved from original)
    const colon_y = start_y + digit_height / 4.0;
    const colon1_base_x = start_x + digit_width * 2.0 + gap_width * 2.0;
    const colon2_base_x = colon1_base_x + digit_width + gap_width * 12.0;

    return .{
        .radius = radius,
        .digit_width = digit_width,
        .digit_height = digit_height,
        .start_y = start_y,
        .digit_positions = digit_positions,
        .colon_y = colon_y,
        .colon_draw_x1 = colon1_base_x - gap_width + radius / 2.0,
        .colon_draw_x2 = colon2_base_x - gap_width + radius / 2.0,
    };
}
