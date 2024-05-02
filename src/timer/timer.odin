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

@(private)
current_time: f32
