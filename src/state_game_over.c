struct game_over_state_t
{
	int32_t score;
};


static void game_over_state_init(game_over_state_t *state, game_state_t *game)
{
	state->score = game->player_score;
}

static void game_over_state_destroy(game_over_state_t *state)
{}

static state_type game_over_state_update(game_over_state_t *state, renderer_t *renderer, font_t *font)
{
	state_type result = STATE_GAME_OVER;
	
	if (key_is_pressed(GLFW_KEY_SPACE))
	{
		result = STATE_GAME;
	}
	else if (key_is_pressed(GLFW_KEY_ESCAPE))
	{
		result = STATE_MENU;
	}
	
	renderer_begin(renderer);
	
	// Render score
	{
		char score_str[64] = {0};
		snprintf(score_str, 64, "%i", state->score);
		renderer_push_text(renderer,
						   font,
						   IVEC2(window.width/2, window.height/2),
						   score_str,
						   COLOR(200, 200, 200, 255),
						   1.2f,
						   RENDERER_TEXT_ALIGN_CENTER);
	}
	
	renderer_push_text(renderer,
					   font,
					   IVEC2(window.width/2, window.height/2 + window.height/4),
					   "Press SPACE to try again.",
					   COLOR(200, 200, 200, 255),
					   0.6f,
					   RENDERER_TEXT_ALIGN_CENTER);
	
	renderer_push_text(renderer,
					   font,
					   IVEC2(window.width/2, window.height/2 + window.height/4 + font->line_height*0.8f),
					   "Press ESCAPE to return to the main menu.",
					   COLOR(200, 200, 200, 255),
					   0.38f,
					   RENDERER_TEXT_ALIGN_CENTER);
	
	renderer_end(renderer);
	
	return result;
}