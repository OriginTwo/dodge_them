package input_manager

import rl "vendor:raylib"

Action :: enum
{
	MOVE_LEFT,
	MOVE_RIGHT,
	MOVE_FLY,

	DEBUG_CHANGE_SCENE,
}

DEFAULT_ACTION_KEYBIND : [Action]rl.KeyboardKey : {
	.MOVE_LEFT = .A,
	.MOVE_RIGHT = .D,
	.MOVE_FLY = .SPACE,

	.DEBUG_CHANGE_SCENE = .ENTER,
}
