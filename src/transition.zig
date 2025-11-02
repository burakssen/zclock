const std = @import("std");

pub const TransitionState = enum {
    idle,
    transitioning,
};

pub const Transition = struct {
    state: TransitionState,
    progress: f32, // 0.0 to 1.0
    duration: f32, // Duration in seconds
    current_view_index: usize,
    next_view_index: usize,

    pub fn init(duration: f32) Transition {
        return .{
            .state = .idle,
            .progress = 0.0,
            .duration = duration,
            .current_view_index = 0,
            .next_view_index = 0,
        };
    }

    pub fn startTransition(self: *Transition, from: usize, to: usize) void {
        if (self.state != .idle) return;

        self.current_view_index = from;
        self.next_view_index = to;
        self.state = .transitioning;
        self.progress = 0.0;
    }

    pub fn update(self: *Transition, delta: f32) void {
        if (self.state == .idle) return;

        self.progress += delta / self.duration;

        if (self.progress >= 1.0) {
            self.progress = 1.0;
            self.state = .idle;
            self.current_view_index = self.next_view_index;
        }
    }

    pub fn isTransitioning(self: Transition) bool {
        return self.state == .transitioning;
    }

    pub fn getCurrentViewIndex(self: Transition) usize {
        return self.current_view_index;
    }

    pub fn getNextViewIndex(self: Transition) usize {
        return self.next_view_index;
    }

    // Ease-in-out function (cubic easing)
    // Provides smooth acceleration at start and deceleration at end
    fn easeInOutCubic(t: f32) f32 {
        if (t < 0.5) {
            return 4.0 * t * t * t;
        } else {
            const f = (2.0 * t) - 2.0;
            return 0.5 * f * f * f + 1.0;
        }
    }

    // Returns offset for the current view (slides left, off screen)
    pub fn getCurrentViewOffset(self: Transition, screen_width: f32) f32 {
        if (self.state == .idle) return 0.0;
        const eased = easeInOutCubic(self.progress);
        return -screen_width * eased;
    }

    // Returns offset for the next view (slides in from right)
    pub fn getNextViewOffset(self: Transition, screen_width: f32) f32 {
        if (self.state == .idle) return screen_width;
        const eased = easeInOutCubic(self.progress);
        return screen_width * (1.0 - eased);
    }
};
