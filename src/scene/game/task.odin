package game_scene

import "core:log"
import "core:math"
import "core:math/rand"
import "core:math/linalg"

import rl "vendor:raylib"

import "src:config"
import "src:input"
import "src:timer"
import "src:asset"

import rlu "src:raylib_util"

// TODO: add more task variations
// TODO: add more task variations
// TODO: add more task variations
// TODO: add more task variations
// TODO: add more task variations
// TODO: add more task variations
// TODO: add more task variations
// TODO: add more task variations
// TODO: add more task variations
// TODO: add more task variations
// TODO: add more task variations

on_task_completed :: proc()
{
	timer.set_timer(&this.task_complete_timer, 1)

	// TODO: play sfx, draw text, etc.
}

TASK_DEVICE_INTERACTION_RADIUS :: 30
Task_Device :: struct
{
	data: Task_Data,

	is_activated: bool,
	is_completed: bool,

	center: linalg.Vector2f32,
	prev_center: linalg.Vector2f32,
	/*
	lin_vel: linalg.Vector2f32,
	ang_vel: f32,
	rotation: f32,
	prev_rotation: f32,
	*/
}

Task_Type :: enum
{
	SWITCH,
	PUMP,
}

Task_Data :: union
{
	Switch_Task_Data,
	Pump_Task_Data,
}

SWITCH_TASK_ROW_COUNT :: 4   // TODO: make this variable, so that the difficulty of the task can be increased
SWITCH_TASK_COL_COUNT :: 2   // TODO: make this variable, so that the difficulty of the task can be increased
SWITCH_TASK_PADDING_X :: 20  // TODO: make this variable, so that the difficulty of the task can be increased
SWITCH_TASK_PADDING_Y :: 2   // TODO: make this variable, so that the difficulty of the task can be increased
Switch_Task_Data :: struct
{
	x_index: int,
	y_index: int,
	toggled: [SWITCH_TASK_ROW_COUNT*SWITCH_TASK_COL_COUNT]bool,
}

PUMP_TASK_PLAYER_EXTENT :: 0.1                // TODO: make this variable, so that the difficulty of the task can be increased
PUMP_TASK_TARGET_EXTENT :: 0.2                // TODO: make this variable, so that the difficulty of the task can be increased
PUMP_TASK_TARGET_VEL_MIN :: 0.05              // TODO: make this variable, so that the difficulty of the task can be increased
PUMP_TASK_TARGET_VEL_MAX :: 0.2               // TODO: make this variable, so that the difficulty of the task can be increased
PUMP_TASK_TARGET_VEL_CHANGE_TIMER_MIN :: 0.5  // TODO: make this variable, so that the difficulty of the task can be increased
PUMP_TASK_TARGET_VEL_CHANGE_TIMER_MAX :: 1.2  // TODO: make this variable, so that the difficulty of the task can be increased
Pump_Task_Data :: struct
{
	// TODO: interpolation
	progress: f32,
	target_vel_change_timer: f32,
	target_pos: f32,
	target_vel: f32,
	player_pos: f32,
	player_vel: f32,
}

init_task_data :: proc(device: ^Task_Device, type: Task_Type)
{
	switch type
	{
	case .SWITCH:
		device.data = Switch_Task_Data{}
		data := &device.data.(Switch_Task_Data)

		for y in 0..<SWITCH_TASK_ROW_COUNT
		{
			for x in 0..<SWITCH_TASK_COL_COUNT
			{
				if rand.float32() < 0.35
				{
					data.toggled[y*SWITCH_TASK_COL_COUNT + x] = true
				}
			}
		}

	case .PUMP:
		device.data = Pump_Task_Data{}
		data := &device.data.(Pump_Task_Data)
		data.target_pos = rand.float32_range(0, 1 - PUMP_TASK_TARGET_EXTENT)
		data.player_pos = 1 - PUMP_TASK_PLAYER_EXTENT
		timer.set_timer(&data.target_vel_change_timer, rand.float32_range(PUMP_TASK_TARGET_VEL_CHANGE_TIMER_MIN, PUMP_TASK_TARGET_VEL_CHANGE_TIMER_MAX))
	}
}

update_task :: proc(device: ^Task_Device, dt: f32)
{
	switch &data in device.data
	{
	case Switch_Task_Data:
		if input.is_action_pressed(.UI_DOWN) && data.y_index < SWITCH_TASK_ROW_COUNT - 1
		{
			data.y_index += 1
		}
		if input.is_action_pressed(.UI_UP) && data.y_index > 0
		{
			data.y_index -= 1
		}

		if input.is_action_pressed(.UI_RIGHT) && data.x_index < SWITCH_TASK_COL_COUNT - 1
		{
			data.x_index += 1
		}
		if input.is_action_pressed(.UI_LEFT) && data.x_index > 0
		{
			data.x_index -= 1
		}

		if input.is_action_pressed(.UI_INTERACT)
		{
			data.toggled[data.y_index*SWITCH_TASK_COL_COUNT + data.x_index] = !data.toggled[data.y_index*SWITCH_TASK_COL_COUNT + data.x_index]
		}

		if !device.is_completed && linalg.all(data.toggled)
		{
			device.is_completed = true
			on_task_completed()
		}

	case Pump_Task_Data:
		if data.player_pos < 1 - PUMP_TASK_PLAYER_EXTENT
		{
			data.player_vel += 0.01
		}
		if input.is_action_pressed(.UI_INTERACT)
		{
			data.player_vel -= 0.2
		}
		data.player_vel = clamp(data.player_vel, -0.4, 0.4)
		data.player_pos += data.player_vel*dt
		data.player_pos = clamp(data.player_pos, 0, 1 - PUMP_TASK_PLAYER_EXTENT)

		if timer.is_timeout(data.target_vel_change_timer)
		{
			timer.set_timer(&data.target_vel_change_timer, rand.float32_range(PUMP_TASK_TARGET_VEL_CHANGE_TIMER_MIN, PUMP_TASK_TARGET_VEL_CHANGE_TIMER_MAX))
			target_pos := math.remap(data.target_pos, 0, 1 - PUMP_TASK_TARGET_EXTENT, 0, 1)
			dist_to_top := abs(target_pos - 0) + 0.05
			dist_to_bot := abs(target_pos - 1) + 0.05
			up_count := int(dist_to_top*10)
			down_count := int(dist_to_bot*10)
			index := 0
			arr: [10]f32
			for i in 0..<up_count
			{
				arr[index] = -1
				index += 1
			}
			for i in 0..<down_count
			{
				arr[index] = 1
				index += 1
			}
			dir := rand.choice(arr[:])
			data.target_vel = dir*rand.float32_range(PUMP_TASK_TARGET_VEL_MIN, PUMP_TASK_TARGET_VEL_MAX)
		}

		data.target_pos += data.target_vel*dt
		data.target_pos = clamp(data.target_pos, 0, 1 - PUMP_TASK_TARGET_EXTENT)

		if (data.player_pos < data.target_pos + PUMP_TASK_TARGET_EXTENT &&
			data.player_pos + PUMP_TASK_PLAYER_EXTENT > data.target_pos)
		{
			data.progress += 0.15*dt
		}
		else
		{
			data.progress -= 0.1*dt
		}
		data.progress = clamp(data.progress, 0, 1)

		if !device.is_completed && data.progress == 1
		{
			device.is_completed = true
			on_task_completed()
		}
	}
}

render_task :: proc(device: ^Task_Device, alpha: f32)
{
	width := config.GAME_WIDTH/2
	height := config.GAME_HEIGHT*3/4
	x := (config.GAME_WIDTH - width)/2
	y := (config.GAME_HEIGHT - height)/2

	center_x := x + width/2
	center_y := y + height/2

	rl.DrawRectangle(i32(x), i32(y), i32(width), i32(height), { 44, 94, 59, 255 })

	rl.BeginScissorMode(i32(x), i32(y), i32(width), i32(height))

	switch &data in device.data
	{
	case Switch_Task_Data:
		tex := asset.get_texture(.TASK_TOGGLE_BUTTON)
		tex_size := linalg.Vector2f32{ f32(tex.width)*0.5, f32(tex.height) }
		origin := linalg.Vector2f32{ tex_size.x*0.5, tex_size.y*0.5 }

		for row in 0..<SWITCH_TASK_ROW_COUNT
		{
			for col in 0..<SWITCH_TASK_COL_COUNT
			{
				is_toggled := data.toggled[row*SWITCH_TASK_COL_COUNT + col]

				src := rl.Rectangle{ 0 if !is_toggled else tex_size.x, 0, tex_size.x, tex_size.y }
				dst := rl.Rectangle{
					f32(center_x) - (tex_size.x + SWITCH_TASK_PADDING_X)*(SWITCH_TASK_COL_COUNT*0.5 - (f32(col) + 0.5)),
					f32(center_y) - (tex_size.y + SWITCH_TASK_PADDING_Y)*(SWITCH_TASK_ROW_COUNT*0.5 - (f32(row) + 0.5)),
					tex_size.x, tex_size.y,
				}

				if data.x_index == col && data.y_index == row
				{
					rlu.draw_outlined_texture(tex, src, dst, origin, 0, rl.WHITE, { 198, 204, 84, 255 })
				}
				else
				{
					rl.DrawTexturePro(tex, src, dst, origin, 0, rl.WHITE)
				}
			}
		}

	case Pump_Task_Data:
		w := 24
		h := height/2
		rl.DrawRectangleLines(i32(center_x - w - 16) - 2, i32(center_y - h/2) - 2, i32(w) + 4, i32(h) + 4, { 96, 156, 78, 255 })
		rl.DrawRectangle(i32(center_x - w - 16), i32(center_y - h/2) + i32(f32(h)*data.target_pos), i32(w), i32(f32(h)*PUMP_TASK_TARGET_EXTENT), { 96, 156, 78, 255 })
		rl.DrawRectangle(i32(center_x - w - 16) + 2, i32(center_y - h/2) + i32(f32(h)*data.player_pos), i32(w) - 4, i32(f32(h)*PUMP_TASK_PLAYER_EXTENT), { 198, 204, 84, 255 })

		// progress bar
		rl.DrawRectangleLines(i32(center_x + 16) - 2, i32(center_y - h/2) - 2, i32(w) + 4, i32(h) + 4, { 96, 156, 78, 255 })
		rl.DrawRectangle(i32(center_x + 16), i32(center_y - h/2) + i32(math.ceil(f32(h)*(1 - data.progress))), i32(w), i32(f32(h)*data.progress), { 96, 156, 78, 255 })
	}

	rl.EndScissorMode()
}
