#define MAX_DEAD_PARTICLES 32

typedef struct particle_t
{
	vec2_t position;
	vec2_t velocity;
	float life_time;
	float angle;
} particle_t;

struct game_state_t
{
	audio_t *audio;
	uint32_t collect_sfx;
	uint32_t explode_sfx;

	vec2_t player_pos;
	vec2_t player_vel;
	int32_t player_score;

	bool32_t player_is_dead;
	float dead_animation_time_left;
	particle_t dead_particles[MAX_DEAD_PARTICLES];
	particle_t dead_smokes[MAX_DEAD_PARTICLES];

	rect_t black_dot;

	rect_t *red_dots;
	int32_t red_dot_count;
	int32_t red_dot_capacity;

	float score_transition;
};


static void game_over(game_state_t *state)
{
	audio_play_source(state->audio, state->explode_sfx, 0);

	// Update and write save data to file
	save_data[SAVE_DATA_HIGHSCORE] = MAX(save_data[SAVE_DATA_HIGHSCORE], (uint32_t)state->player_score);
	FILE *file = fopen("data.bin", "w");
	fwrite(save_data, sizeof(uint32_t), SAVE_DATA_COUNT, file);
	fclose(file);

	state->player_is_dead = 1;
	state->dead_animation_time_left = 2.f; // in seconds

	// Spawn particles
	for (int32_t i = 0; i < MAX_DEAD_PARTICLES; ++i)
	{
		state->dead_particles[i] = (particle_t){
			.position = VEC2(random_int(state->player_pos.x+0.5f, state->player_pos.x+0.5f + PLAYER_SIZE-6),
							 random_int(state->player_pos.y+0.5f, state->player_pos.y+0.5f + PLAYER_SIZE-6)),
			.velocity = VEC2(random_int(-600, 600), random_int(-600, 600)),
			.life_time = 1.8f, // in seconds
			.angle = random_float(-PI/2.f, PI/2.f)
		};

		if (state->dead_particles[i].velocity.x > -40.f &&
			state->dead_particles[i].velocity.x <  40.f)
		{
			state->dead_particles[i].velocity.x = 80.f;
		}

		if (state->dead_particles[i].velocity.y > -40.f &&
			state->dead_particles[i].velocity.y <  40.f)
		{
			state->dead_particles[i].velocity.y = 80.f;
		}
	}

	// Spawn smoke particles
	for (int32_t i = 0; i < MAX_DEAD_PARTICLES; ++i)
	{
		state->dead_smokes[i] = (particle_t){
			.position = VEC2(random_int(state->player_pos.x+0.5f, state->player_pos.x+0.5f + PLAYER_SIZE-6),
							 random_int(state->player_pos.y+0.5f, state->player_pos.y+0.5f + PLAYER_SIZE-6)),
			.velocity = VEC2(random_int(-300, 300), random_int(-300, 300)),
			.life_time = 2.f, // in seconds
			.angle = random_float(-PI/2.f, PI/2.f)
		};

		if (state->dead_particles[i].velocity.x > -40.f &&
			state->dead_particles[i].velocity.x <  40.f)
		{
			state->dead_particles[i].velocity.x = 80.f;
		}

		if (state->dead_particles[i].velocity.y > -40.f &&
			state->dead_particles[i].velocity.y <  40.f)
		{
			state->dead_particles[i].velocity.y = 80.f;
		}
	}
}

static void game_state_init(game_state_t *state)
{
	srand(time(0));

	state->collect_sfx = audio_load_source(state->audio, "res/collect.wav", 0.75f);
	state->explode_sfx = audio_load_source(state->audio, "res/explode.wav", 0.75f);

	state->player_pos = VEC2(window.width/2 - PLAYER_SIZE/2, window.height/2 - PLAYER_SIZE/2);
	state->player_vel = VEC2(0, 0);
	state->player_score = 0;

	state->player_is_dead = 0;
	state->dead_animation_time_left = 0.f;

	state->black_dot = RECT(random_int(0, window.width-DOT_SIZE), random_int(0, window.height-DOT_SIZE), DOT_SIZE, DOT_SIZE);

	state->score_transition = 0.f;
	state->red_dot_count = 0;
	state->red_dot_capacity = 2;
	state->red_dots = malloc(sizeof(rect_t) * state->red_dot_capacity);
}

static void game_state_destroy(game_state_t *state)
{
	free(state->red_dots);
}

static state_type game_state_update(game_state_t *state, renderer_t *renderer, font_t *font)
{
	state_type result = STATE_GAME;

	// Render the game
	renderer_begin(renderer);

	if (!state->player_is_dead)
	{
		// Update player x velocity
		if (key_is_held(GLFW_KEY_RIGHT) || key_is_held(GLFW_KEY_D))
		{
			state->player_vel.x += 1125.f*window.frame_delta;
		}
		if (key_is_held(GLFW_KEY_LEFT) || key_is_held(GLFW_KEY_A))
		{
			state->player_vel.x -= 1125.f*window.frame_delta;
		}

		state->player_vel.x = CLAMP(state->player_vel.x, -180.f, 180.f);

		// Update player y velocity
		state->player_vel.y += 562.5f*window.frame_delta;
		if (key_is_pressed(GLFW_KEY_SPACE))
		{
			state->player_vel.y -= 180.f;
			save_data[SAVE_DATA_JUMP_COUNT]++;
		}

		// Update player position
		state->player_pos.x += state->player_vel.x*window.frame_delta;
		state->player_pos.y += state->player_vel.y*window.frame_delta;

		// Check for collision between player and black dot
		bool32_t score_just_increased = 0;
		if (rect_collide(RECT(state->player_pos.x, state->player_pos.y, PLAYER_SIZE, PLAYER_SIZE),
						 state->black_dot))
		{
			audio_play_source(state->audio, state->collect_sfx, 0);
			state->black_dot = RECT(random_int(0, window.width-DOT_SIZE), random_int(0, window.height-DOT_SIZE), DOT_SIZE, DOT_SIZE);
			state->player_score++;
			score_just_increased = 1;
		}

		// Add red dot if necessary
		if (state->player_score > state->red_dot_count)
		{
			if (++state->red_dot_count > state->red_dot_capacity)
			{
				state->red_dot_capacity *= 2;
				state->red_dots = realloc(state->red_dots, state->red_dot_capacity * sizeof(rect_t));
			}

			state->red_dots[state->red_dot_count-1] = RECT(random_int(0, window.width-DOT_SIZE), random_int(0, window.height-DOT_SIZE), DOT_SIZE, DOT_SIZE);
		}

		// Check for collision between player and red dots
		for (int32_t i = 0; i < state->red_dot_count; ++i)
		{
			if (rect_collide(RECT(state->player_pos.x, state->player_pos.y, PLAYER_SIZE, PLAYER_SIZE),
							 state->red_dots[i]))
			{
				game_over(state);
			}
		}

		// Check if the center of the player is outside of the screen
		{
			vec2_t player_center = { state->player_pos.x + PLAYER_SIZE/2.f, state->player_pos.y + PLAYER_SIZE/2.f };
			if (player_center.x < 0.f ||
				player_center.x > (float)window.width ||
				player_center.y < 0.f ||
				player_center.y > (float)window.height)
			{
				game_over(state);
			}
		}

		// Score text transition
		if (score_just_increased)
		{
			state->score_transition = 1.f;
		}
		state->score_transition -= 0.1f;
		state->score_transition = CLAMP(state->score_transition, 0.f, 1.f);

		// Render score
		{
			char player_score_str[64] = {0};
			snprintf(player_score_str, 64, "%i", state->player_score);
			renderer_push_text(renderer,
							   font,
							   IVEC2(window.width/2, window.height/2),
							   player_score_str,
							   COLOR(200, 200, 200, 175),
							   1.f + state->score_transition*0.5f,
							   RENDERER_TEXT_ALIGN_CENTER);
		}

		// Render red dots
		for (int32_t i = 0; i < state->red_dot_count; ++i)
		{
			renderer_push_filled_rect(renderer, state->red_dots[i], COLOR(224, 72, 38, 255));
		}

		// Render collectible dot
		renderer_push_filled_rect(renderer, state->black_dot, COLOR(200, 200, 200, 255));

		// Render player
		renderer_push_filled_rect(renderer, RECT(state->player_pos.x, state->player_pos.y, PLAYER_SIZE, PLAYER_SIZE), COLOR(200, 200, 200, 255));
	}
	else
	{
		state->dead_animation_time_left -= window.frame_delta;
		if (state->dead_animation_time_left <= 0.f)
		{
			result = STATE_GAME_OVER;
		}

		// Render score
		{
			char player_score_str[64] = {0};
			snprintf(player_score_str, 64, "%i", state->player_score);
			renderer_push_text(renderer,
							   font,
							   IVEC2(window.width/2, window.height/2),
							   player_score_str,
							   COLOR(200, 200, 200, 175),
							   1.f + state->score_transition*0.5f,
							   RENDERER_TEXT_ALIGN_CENTER);
		}

		// Render red dots
		for (int32_t i = 0; i < state->red_dot_count; ++i)
		{
			renderer_push_filled_rect(renderer, state->red_dots[i], COLOR(224, 72, 38, 255));
		}

		// Render colltible dot
		renderer_push_filled_rect(renderer, state->black_dot, COLOR(200, 200, 200, 255));

		// Render dead particle
		for (int32_t i = 0; i < MAX_DEAD_PARTICLES; ++i)
		{
			particle_t *particle = state->dead_particles + i;

			particle->position.x += particle->velocity.x*window.frame_delta;
			particle->position.y += particle->velocity.y*window.frame_delta;
			particle->life_time -= window.frame_delta;
			particle->angle += 0.1f;

			renderer_push_rotated_filled_rect(renderer,
											  RECT(particle->position.x,
												   particle->position.y,
												   particle->life_time*6.f + 0.5f,
												   particle->life_time*6.f + 0.5f),
											  particle->angle,
											  COLOR(200, 127, 0, 255));
		}

		// Render dead smoke particles
		for (int32_t i = 0; i < MAX_DEAD_PARTICLES; ++i)
		{
			particle_t *particle = state->dead_smokes + i;

			particle->position.x += particle->velocity.x*window.frame_delta;
			particle->position.y += particle->velocity.y*window.frame_delta;
			particle->life_time -= window.frame_delta;
			particle->angle += 0.1f;

			renderer_push_rotated_filled_rect(renderer,
											  RECT(particle->position.x,
												   particle->position.y,
												   particle->life_time*12.f + 0.5f,
												   particle->life_time*12.f + 0.5f),
											  particle->angle,
											  COLOR(64, 64, 64, 255));
		}

	}

	renderer_end(renderer);

	return result;
}
