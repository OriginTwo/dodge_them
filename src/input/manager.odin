package input_manager

import "core:math/linalg"

import rl "vendor:raylib"

init_manager :: proc()
{
	g_im.action_key_binds = DEFAULT_ACTION_KEYBIND
}

uninit_manager :: proc()
{
}

set_action_key_bind :: proc(action: Action, key: rl.KeyboardKey)
{
	g_im.action_key_binds[action] = key
}

update :: proc()
{
	for key, action in g_im.action_key_binds
	{
		g_im.prev_action_down[action] = g_im.action_down[action]
		g_im.action_down[action] = rl.IsKeyDown(key)
	}
}

is_action_pressed :: #force_inline proc(action: Action) -> bool
{
	return g_im.action_down[action] && !g_im.prev_action_down[action]
}

is_action_released :: #force_inline proc(action: Action) -> bool
{
	return !g_im.action_down[action] && g_im.prev_action_down[action]
}

is_action_down :: #force_inline proc(action: Action) -> bool
{
	return g_im.action_down[action]
}

is_action_up :: #force_inline proc(action: Action) -> bool
{
	return !g_im.action_down[action]
}

@(private)
g_im: Input_Manager

@(private)
Input_Manager :: struct
{
	action_key_binds: [Action]rl.KeyboardKey,
	action_down: [Action]bool,
	prev_action_down: [Action]bool,
}
