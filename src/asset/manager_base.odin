package asset

init_manager :: #force_inline proc()
{
	g_am = new(Asset_Manager)
}

uninit_manager :: #force_inline proc()
{
	free(g_am)
}

@(private)
g_am: ^Asset_Manager

@(private)
Asset_Manager :: struct
{
	textures: [Texture_ID]Texture,
	fonts: [Font_ID]Font,
	sounds: [Sound_ID]Sound,
	musics: [Music_ID]Music,
	shaders: [Shader_ID]Shader,
}
