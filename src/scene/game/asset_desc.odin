package game_scene

import "src:asset"

REQUIRED_TEXTURES :: []asset.Texture_ID{
	.ROCKET,
	.SMALL_ASTEROID,
	.BIG_ASTEROID,
	.TASK_DEVICE,
	.TASK_TOGGLE_BUTTON,
}

// TODO: font
// TODO: sound
// TODO: music

REQUIRED_SHADERS :: []asset.Shader_ID{
	.OUTLINE,
	.RECOLOR,
}
