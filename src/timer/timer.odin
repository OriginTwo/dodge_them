package timer

is_timeout :: proc "contextless" (t: f32) -> bool
{
	return current_time >= t
}

set_timer :: proc "contextless" (t: ^f32, second: f32)
{
	t^ = current_time + second
}

tick :: proc "contextless" (dt: f32)
{
	current_time += dt
}

now :: #force_inline proc "contextless" () -> f32
{
	return current_time
}

@(private)
current_time: f32
