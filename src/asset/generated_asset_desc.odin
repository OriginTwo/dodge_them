package asset

EMBED_ASSETS :: #config(DIST_BUILD, false)

Texture_ID :: enum
{
	NONE,
	BIG_ASTEROID,
	ROCKET,
	SMALL_ASTEROID,
	TASK_DEVICE,
	TASK_TOGGLE_BUTTON,
}

Font_ID :: enum
{
	NONE,
}

Sound_ID :: enum
{
	NONE,
	COLLECT,
	EXPLODE,
}

Music_ID :: enum
{
	NONE,
}

Shader_ID :: enum
{
	NONE,
	OUTLINE,
	RECOLOR,
}

@(private)
texture_asset_descs: [Texture_ID]Asset_Desc = {
	.NONE = {},
	.BIG_ASTEROID = { path = "data/image/big_asteroid.png", data = #load("data/image/big_asteroid.png") when EMBED_ASSETS else nil },
	.ROCKET = { path = "data/image/rocket.png", data = #load("data/image/rocket.png") when EMBED_ASSETS else nil },
	.SMALL_ASTEROID = { path = "data/image/small_asteroid.png", data = #load("data/image/small_asteroid.png") when EMBED_ASSETS else nil },
	.TASK_DEVICE = { path = "data/image/task_device.png", data = #load("data/image/task_device.png") when EMBED_ASSETS else nil },
	.TASK_TOGGLE_BUTTON = { path = "data/image/task_toggle_button.png", data = #load("data/image/task_toggle_button.png") when EMBED_ASSETS else nil },
}

@(private)
font_asset_descs: [Font_ID]Asset_Desc = {
	.NONE = {},
}

@(private)
sound_asset_descs: [Sound_ID]Asset_Desc = {
	.NONE = {},
	.COLLECT = { path = "data/sound/collect.wav", data = #load("data/sound/collect.wav") when EMBED_ASSETS else nil },
	.EXPLODE = { path = "data/sound/explode.wav", data = #load("data/sound/explode.wav") when EMBED_ASSETS else nil },
}

@(private)
music_asset_descs: [Music_ID]Asset_Desc = {
	.NONE = {},
}

@(private)
shader_asset_descs: [Shader_ID]Asset_Desc = {
	.NONE = {},
	.OUTLINE = { path = "data/shader/outline.fs", data = #load("data/shader/outline.fs") when EMBED_ASSETS else nil },
	.RECOLOR = { path = "data/shader/recolor.fs", data = #load("data/shader/recolor.fs") when EMBED_ASSETS else nil },
}

