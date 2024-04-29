package game_scene

import "src:asset"

REQUIRED_TEXTURES :: []asset.Texture_ID{
	.ROCKET,
	.TASK_DEVICE,
	.SMALL_ASTEROID,
	.BIG_ASTEROID,
}

// TODO: font
// TODO: sound
// TODO: music

REQUIRED_SHADERS :: []asset.Shader_ID{
	.OUTLINE,
	.RECOLOR,
}
