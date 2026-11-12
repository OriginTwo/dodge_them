typedef enum state_type
{
	STATE_MENU,
	STATE_GAME,
	STATE_GAME_OVER,
	STATE_COUNT
} state_type;

typedef struct menu_state_t menu_state_t;
typedef struct game_state_t game_state_t;
typedef struct game_over_state_t game_over_state_t;

#include "state_menu.c"
#include "state_game.c"
#include "state_game_over.c"

typedef struct state_t
{
	state_type type;
	union
	{
		menu_state_t menu_state;
		game_state_t game_state;
		game_over_state_t game_over_state;
	};
} state_t;

static bool32_t first_frame_of_current_state = 1;
static state_type state_update(state_t *states, state_type type, renderer_t *renderer, font_t *font)
{
	state_t *state = states + type;

	state_type result;
	switch (type)
	{
		case STATE_MENU:
		{
			if (first_frame_of_current_state)
			{
				menu_state_init(&state->menu_state);
				first_frame_of_current_state = 0;
			}
			result = menu_state_update(&state->menu_state, renderer, font);
			if (result != type)
			{
				menu_state_destroy(&state->menu_state);
				first_frame_of_current_state = 1;
			}
			break;
		}

		case STATE_GAME:
		{
			if (first_frame_of_current_state)
			{
				game_state_init(&state->game_state);
				first_frame_of_current_state = 0;
			}
			result = game_state_update(&state->game_state, renderer, font);
			if (result != type)
			{
				game_state_destroy(&state->game_state);
				first_frame_of_current_state = 1;
			}
			break;
		}

		case STATE_GAME_OVER:
		{
			if (first_frame_of_current_state)
			{
				game_over_state_init(&state->game_over_state, &states[STATE_GAME].game_state);
				first_frame_of_current_state = 0;
			}
			result = game_over_state_update(&state->game_over_state, renderer, font);
			if (result != type)
			{
				game_over_state_destroy(&state->game_over_state);
				first_frame_of_current_state = 1;
			}
			break;
		}

		default: break;
	}
	return result;
}
