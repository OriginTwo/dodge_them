package asset

import "core:log"
import "core:fmt"

import rl "vendor:raylib"

when !#config(DIST_BUILD, false)
{
	load_texture :: proc{
		load_texture_single,
		load_texture_multi,
	}

	load_texture_single :: proc(id: Texture_ID)
	{
		tex := rl.LoadTexture(fmt.ctprintf("%s", texture_asset_descs[id].path))
		g_am.textures[id] = tex
	}

	load_texture_multi :: proc(ids: ..Texture_ID)
	{
		for id in ids
		{
			tex := rl.LoadTexture(fmt.ctprintf("%s", texture_asset_descs[id].path))
			g_am.textures[id] = tex
		}
	}

	unload_texture :: proc{
		unload_texture_single,
		unload_texture_multi,
	}

	unload_texture_single :: proc(id: Texture_ID)
	{
		tex := g_am.textures[id]
		rl.UnloadTexture(tex)
	}

	unload_texture_multi :: proc(ids: ..Texture_ID)
	{
		for id in ids
		{
			tex := g_am.textures[id]
			rl.UnloadTexture(tex)
		}
	}

	check_texture :: #force_inline proc(id: Texture_ID) -> bool
	{
		return rl.IsTextureReady(g_am.textures[id])
	}

	get_texture :: proc(id: Texture_ID) -> Texture
	{
		if !check_texture(id)
		{
			log.warnf("Texture '%s' is not loaded", id)
			return {}
		}

		return g_am.textures[id]
	}

	// TODO: font
	// TODO: sound
	// TODO: music

	load_shader :: proc{
		load_shader_single,
		load_shader_multi,
	}

	load_shader_single :: proc(id: Shader_ID)
	{
		shader := rl.LoadShader(nil, fmt.ctprintf("%s", shader_asset_descs[id].path))
		g_am.shaders[id] = shader
	}

	load_shader_multi :: proc(ids: ..Shader_ID)
	{
		for id in ids
		{
			shader := rl.LoadShader(nil, fmt.ctprintf("%s", shader_asset_descs[id].path))
			g_am.shaders[id] = shader
		}
	}

	unload_shader :: proc{
		unload_shader_single,
		unload_shader_multi,
	}

	unload_shader_single :: proc(id: Shader_ID)
	{
		shader := g_am.shaders[id]
		rl.UnloadShader(shader)
	}

	unload_shader_multi :: proc(ids: ..Shader_ID)
	{
		for id in ids
		{
			shader := g_am.shaders[id]
			rl.UnloadShader(shader)
		}
	}

	check_shader :: #force_inline proc(id: Shader_ID) -> bool
	{
		return rl.IsShaderReady(g_am.shaders[id])
	}

	get_shader :: proc(id: Shader_ID) -> Shader
	{
		if !check_shader(id)
		{
			log.warnf("Shader '%s' is not loaded", id)
			return {}
		}

		return g_am.shaders[id]
	}
}
