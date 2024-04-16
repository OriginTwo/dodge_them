package main

import "core:log"
import "core:mem"
import "core:math"
import "core:math/linalg"

import rl "vendor:raylib"

import "src:input_manager"
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
		rl.SetTraceLogLevel(.NONE)
	}
	else
	{
		rl.SetTraceLogLevel(.NONE)
	}

	rl.SetConfigFlags({ .WINDOW_RESIZABLE, .VSYNC_HINT })
	rl.InitWindow(1280, 720, "Dodge Them!")
	defer rl.CloseWindow()

	rl.SetExitKey(.ESCAPE)

	input_manager.init()
	defer input_manager.uninit()

	asset.init_manager()
	defer asset.uninit_manager()

	scene_manager.init()
	defer scene_manager.uninit()

	scene_manager.register_scene(.GAME, game.Data, game.init, game.uninit, game.update, game.render)
	scene_manager.register_scene(.TEST, test.Data, update = test.update, render = test.render)

	scene_manager.change_scene(.GAME)

	unprocessed_tick: f64

	for !rl.WindowShouldClose()
	{
		ticks_per_second := f64(rl.GetFPS())
		unprocessed_tick += f64(rl.GetFrameTime())*ticks_per_second

		for unprocessed_tick >= 1.0
		{
			unprocessed_tick -= 1.0
			scene_manager.update_scene(f32(1.0/ticks_per_second))
			input_manager.update()
		}

		scene_manager.render_scene()
		scene_manager.update_internal()

		free_all(context.temp_allocator)
	}
}
