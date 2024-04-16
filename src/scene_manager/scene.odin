package scene_manager

Scene :: struct
{
	is_registered: bool,

	init: proc(rawptr),
	uninit: proc(rawptr),
	update: proc(rawptr, f32),
	render: proc(rawptr),

	data_size: int,
	data: rawptr,
}
