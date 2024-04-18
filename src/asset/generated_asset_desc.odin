package asset

EMBED_ASSETS :: #config(DIST_BUILD, false)

Texture_ID :: enum
{
	NONE,
	ROCKET,
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

@(private)
texture_asset_descs: [Texture_ID]Asset_Desc = {
	.NONE = {},
	.ROCKET = { path = "data/image/rocket.png", data = #load("data/image/rocket.png") when EMBED_ASSETS else nil },
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

