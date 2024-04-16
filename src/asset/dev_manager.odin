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
}
