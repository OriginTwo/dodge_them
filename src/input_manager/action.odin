package input_manager

import rl "vendor:raylib"

Action :: enum
{
	PLAYER_MOVE_LEFT,
	PLAYER_MOVE_RIGHT,
	PLAYER_BOOST,
	PLAYER_INTERACT,

	UI_LEFT,
	UI_RIGHT,
	UI_UP,
	UI_DOWN,
	UI_BACK,
	UI_INTERACT,

	DEBUG_CHANGE_SCENE,
}

DEFAULT_ACTION_KEYBIND : [Action]rl.KeyboardKey : {
	.PLAYER_MOVE_LEFT  = .A,
	.PLAYER_MOVE_RIGHT = .D,
	.PLAYER_BOOST      = .SPACE,
	.PLAYER_INTERACT   = .E,

	.UI_LEFT     = .LEFT,
	.UI_RIGHT    = .RIGHT,
	.UI_UP       = .UP,
	.UI_DOWN     = .DOWN,
	.UI_BACK     = .ESCAPE,
	.UI_INTERACT = .E,

	.DEBUG_CHANGE_SCENE = .ENTER,
}
