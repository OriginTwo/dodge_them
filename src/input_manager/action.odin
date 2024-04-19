package input_manager

import rl "vendor:raylib"

Action :: enum
{
	MOVE_LEFT,
	MOVE_RIGHT,
	MOVE_BOOST,

	INTERACT,

	UI_LEFT,
	UI_RIGHT,
	UI_UP,
	UI_DOWN,

	DEBUG_CHANGE_SCENE,
}

DEFAULT_ACTION_KEYBIND : [Action]rl.KeyboardKey : {
	.MOVE_LEFT  = .A,
	.MOVE_RIGHT = .D,
	.MOVE_BOOST = .SPACE,

	.INTERACT = .E,

	.UI_LEFT  = .LEFT,
	.UI_RIGHT = .RIGHT,
	.UI_UP    = .UP,
	.UI_DOWN  = .DOWN,

	.DEBUG_CHANGE_SCENE = .ENTER,
}
