struct menu_state_t
{
	int8_t some_unnecessary_data_because_c_required_that_i_need_to_have_atleast_one_struct_member;
};


static void menu_state_init(menu_state_t *state)
{}

static void menu_state_destroy(menu_state_t *state)
{}

static state_type menu_state_update(menu_state_t *state, renderer_t *renderer, font_t *font)
{
	state_type result = STATE_MENU;

	if (key_is_pressed(GLFW_KEY_ESCAPE))
	{
		glfwSetWindowShouldClose(window.handle, 1);
	}

	if (key_is_pressed(GLFW_KEY_SPACE))
	{
		result = STATE_GAME;
	}

	renderer_begin(renderer);

	// Render player
	renderer_push_filled_rect(renderer, RECT(window.width/2 - PLAYER_SIZE/2, window.height/2 - PLAYER_SIZE/2, PLAYER_SIZE, PLAYER_SIZE), COLOR(200, 200, 200, 255));

	// Render highscore
	{
		char highscore_str[64] = {0};
		snprintf(highscore_str, 64, "Highscore: %u", save_data[SAVE_DATA_HIGHSCORE]);
		renderer_push_text(renderer,
						   font,
						   IVEC2(window.width/2, window.height/4 - font->line_height/2),
						   highscore_str,
						   COLOR(200, 200, 200, 255),
						   0.8f,
						   RENDERER_TEXT_ALIGN_CENTER);
	}

	// Render jump count
	{
		char jump_count_str[64] = {0};
		snprintf(jump_count_str, 64, "Jump count: %u", save_data[SAVE_DATA_JUMP_COUNT]);
		renderer_push_text(renderer,
						   font,
						   IVEC2(window.width/2, window.height/4 + font->line_height/2),
						   jump_count_str,
						   COLOR(200, 200, 200, 255),
						   0.8f,
						   RENDERER_TEXT_ALIGN_CENTER);
	}

	renderer_push_text(renderer,
					   font,
					   IVEC2(window.width/2, window.height/2 + window.height/4),
					   "Press SPACE to start.",
					   COLOR(200, 200, 200, 255),
					   0.5f,
					   RENDERER_TEXT_ALIGN_CENTER);

	renderer_push_text(renderer,
					   font,
					   IVEC2(window.width/2, window.height/2 + window.height/4 + font->line_height*0.9f),
					   "Press ESCAPE to quit.",
					   COLOR(200, 200, 200, 255),
					   0.5f,
					   RENDERER_TEXT_ALIGN_CENTER);

	// Render version number
	{
		char version_str[16] = {0};
		snprintf(version_str, 16, "v%i.%i.%i", VERSION_MAJOR, VERSION_FEATURE, VERSION_PATCH);
		renderer_push_text(renderer,
						   font,
						   IVEC2(0, window.height - font->line_height*0.2f),
						   version_str,
						   COLOR(200, 200, 200, 255),
						   0.2f,
						   0);
	}

	renderer_end(renderer);

	return result;
}
