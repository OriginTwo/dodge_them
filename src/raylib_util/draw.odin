package raylib_util

import rl "vendor:raylib"

import "src:asset"

draw_outlined_texture :: proc(
	tex: rl.Texture2D,
	src, dst: rl.Rectangle,
	origin: rl.Vector2,
	rotation: f32,
	tint: rl.Color,
	outline_color := rl.WHITE,
	outline_size: f32 = 1)
{
	outline_color := rl.ColorNormalize(outline_color)
	outline_size := outline_size
	outline_shader := asset.get_shader(.OUTLINE)
	rl.BeginShaderMode(outline_shader)
	rl.SetShaderValue(outline_shader, rl.GetShaderLocation(outline_shader, "outlineColor"), &outline_color, .VEC4)
	rl.SetShaderValue(outline_shader, rl.GetShaderLocation(outline_shader, "outlineSize"), &outline_size, .FLOAT)
	rl.DrawTexturePro(tex, src, dst, origin, rotation, tint)
	rl.EndShaderMode()
}

draw_recolored_texture :: proc(
	tex: rl.Texture2D,
	src, dst: rl.Rectangle,
	origin: rl.Vector2,
	rotation: f32,
	color: rl.Color)
{
	recolor_shader := asset.get_shader(.RECOLOR)
	rl.BeginShaderMode(recolor_shader)
	rl.DrawTexturePro(tex, src, dst, origin, rotation, color)
	rl.EndShaderMode()
}
