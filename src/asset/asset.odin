package asset

import rl "vendor:raylib"

Texture  :: rl.Texture
Font     :: rl.Font
Sound    :: rl.Sound
Music    :: rl.Music
Shader   :: rl.Shader

Asset_Desc :: struct
{
	path: string,
	data: []u8,
}
