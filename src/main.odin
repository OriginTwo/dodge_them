package main

import "core:log"
import "core:mem"
import "core:math"
import "core:math/linalg"

import rl "vendor:raylib"

import "src:config"
import "src:input"
import "src:asset"
import "src:scene_manager"
import "src:scene/game"
import "src:scene/test"

main :: proc()
{
	when ODIN_DEBUG
	{
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		defer mem.tracking_allocator_destroy(&track)
		context.allocator = mem.tracking_allocator(&track)

		defer
		{
			for _, leak in track.allocation_map
			{
				log.warnf("%v leaked %m", leak.location, leak.size)
			}

			for bad_free in track.bad_free_array
			{
				log.warnf("%v allocation %p was freed badly\n", bad_free.location, bad_free.memory)
			}
		}

		context.logger = log.create_console_logger(.Info, { .Level, .Terminal_Color, .Short_File_Path, .Line, .Procedure })
		defer log.destroy_console_logger(context.logger)
		rl.SetTraceLogLevel(.INFO)
	}
	else
	{
		rl.SetTraceLogLevel(.NONE)
	}

	rl.SetConfigFlags({ .WINDOW_RESIZABLE, .VSYNC_HINT })
	rl.InitWindow(config.DISPLAY_WIDTH, config.DISPLAY_HEIGHT, "Dodge Them!")
	defer rl.CloseWindow()

	rl.SetExitKey(.KEY_NULL)

	input.init_manager()
	defer input.uninit_manager()

	asset.init_manager()
	defer asset.uninit_manager()

	scene_manager.init()
	defer scene_manager.uninit()

	scene_manager.register_scene(.GAME, game.Data, game.init, game.uninit, game.update, game.render)
	scene_manager.register_scene(.TEST, test.Data, update = test.update, render = test.render)

	scene_manager.change_scene(.GAME)

	curr_time := rl.GetTime()
	accumulator := 0.0

	for !rl.WindowShouldClose()
	{
		new_time := rl.GetTime()
		frame_time := new_time - curr_time
		curr_time = new_time
		accumulator += frame_time

		for accumulator >= config.SECONDS_PER_TICK
		{
			input.update()
			scene_manager.update_scene(config.SECONDS_PER_TICK)
			accumulator -= config.SECONDS_PER_TICK
		}

		alpha := accumulator*config.TICKS_PER_SECOND
		scene_manager.render_scene(f32(alpha))
		scene_manager.update_internal()

		free_all(context.temp_allocator)
	}
}
