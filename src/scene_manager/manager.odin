package scene_manager

import "core:log"
import "core:mem"

init :: proc()
{
	g_sm = new(Scene_Manager)
}

uninit :: proc()
{
	if g_sm.current_scene.uninit != nil
	{
		g_sm.current_scene.uninit(g_sm.current_scene.data)
	}
	free(g_sm.current_scene.data)

	delete(g_sm.active_scenes)
	free(g_sm)
}

register_scene :: proc(
	id: Scene_ID,
	$data_type: typeid,
	init: proc(rawptr) = nil,
	uninit: proc(rawptr) = nil,
	update: proc(rawptr, f32) = nil,
	render: proc(rawptr, f32) = nil)
{
	g_sm.registered_scenes[id] = {
		is_registered = true,
		init = init,
		uninit = uninit,
		update = update,
		render = render,
		data_size = size_of(data_type),
	}
}

change_scene :: proc(id: Scene_ID)
{
	g_sm.new_scene_id = id
}

update_scene :: proc(dt: f32)
{
	if g_sm.current_scene.update != nil
	{
		g_sm.current_scene.update(g_sm.current_scene.data, dt)
	}
}

render_scene :: proc(alpha: f32)
{
	if g_sm.current_scene.render != nil
	{
		g_sm.current_scene.render(g_sm.current_scene.data, alpha)
	}
}

update_internal :: proc()
{
	if g_sm.new_scene_id != .NONE
	{
		scene := g_sm.registered_scenes[g_sm.new_scene_id]
		if !scene.is_registered
		{
			log.warnf("Scene ID '%s' is not registered", g_sm.new_scene_id)
			return
		}

		if g_sm.current_scene.uninit != nil
		{
			g_sm.current_scene.uninit(g_sm.current_scene.data)
		}
		free(g_sm.current_scene.data)

		g_sm.current_scene = scene
		g_sm.current_scene.data, _ = mem.alloc(g_sm.current_scene.data_size)

		if g_sm.current_scene.init != nil
		{
			g_sm.current_scene.init(g_sm.current_scene.data)
		}

		g_sm.new_scene_id = .NONE
	}
}

@(private)
g_sm: ^Scene_Manager

@(private)
Scene_Manager :: struct
{
	registered_scenes: [Scene_ID]Scene,
	active_scenes: [dynamic]Scene,
	current_scene: Scene,

	new_scene_id: Scene_ID,
}
