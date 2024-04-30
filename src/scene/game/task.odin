package game_scene

import "core:log"
import "core:math"
import "core:math/rand"
import "core:math/linalg"

import rl "vendor:raylib"

import "src:config"
import "src:input_manager"

on_task_completed :: proc()
{
	this.player.state = .NORMAL

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
}

Task_Data :: union
{
	Switch_Task_Data,
}

SWITCH_TASK_ROW_COUNT :: 4
SWITCH_TASK_COL_COUNT :: 2
Switch_Task_Data :: struct
{
	x_index: int,
	y_index: int,
	toggled: [SWITCH_TASK_ROW_COUNT*SWITCH_TASK_COL_COUNT]bool,
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
	}
}

update_task :: proc(device: ^Task_Device, dt: f32)
{
	switch &data in device.data
	{
	case Switch_Task_Data:
		if input_manager.is_action_pressed(.UI_DOWN) && data.y_index < SWITCH_TASK_ROW_COUNT - 1
		{
			data.y_index += 1
		}
		if input_manager.is_action_pressed(.UI_UP) && data.y_index > 0
		{
			data.y_index -= 1
		}

		if input_manager.is_action_pressed(.UI_RIGHT) && data.x_index < SWITCH_TASK_COL_COUNT - 1
		{
			data.x_index += 1
		}
		if input_manager.is_action_pressed(.UI_LEFT) && data.x_index > 0
		{
			data.x_index -= 1
		}

		if input_manager.is_action_pressed(.UI_INTERACT)
		{
			data.toggled[data.y_index*SWITCH_TASK_COL_COUNT + data.x_index] = !data.toggled[data.y_index*SWITCH_TASK_COL_COUNT + data.x_index]
		}

		if !device.is_completed && linalg.all(data.toggled)
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

	rl.DrawRectangle(i32(x), i32(y), i32(width), i32(height), rl.DARKGRAY)

	rl.BeginScissorMode(i32(x), i32(y), i32(width), i32(height))

	switch &data in device.data
	{
	case Switch_Task_Data:
		for row in 0..<SWITCH_TASK_ROW_COUNT
		{
			for col in 0..<SWITCH_TASK_COL_COUNT
			{
				color := rl.GREEN if data.toggled[row*SWITCH_TASK_COL_COUNT + col] else rl.RED
				if data.x_index == col && data.y_index == row
				{
					color = rl.ColorTint(color, rl.GRAY)
				}

				rl.DrawCircle(
					i32(center_x + (col*2 - 1)*30),
					i32(center_y - (SWITCH_TASK_ROW_COUNT*24)/2 + 24*row) + 8,
					8, color)
			}
		}
	}

	rl.EndScissorMode()
}
