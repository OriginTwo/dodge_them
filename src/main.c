#define VERSION_MAJOR 1
#define VERSION_FEATURE 0
#define VERSION_PATCH 1

#define PLAYER_SIZE 48
#define DOT_SIZE 12


#include <time.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#include "utils/defines.h"
#include "utils/types.h"
#include "utils/utils.h"
#include "utils/maths.h"



enum
{
	SAVE_DATA_HIGHSCORE,
	SAVE_DATA_JUMP_COUNT,
	SAVE_DATA_COUNT
};
static uint32_t save_data[SAVE_DATA_COUNT] = {0};



#include "gfx/window.h"
#include "gfx/renderer.h"
#include "audio.h"

#include "gfx/window.c"
#include "gfx/renderer.c"
#include "audio.c"

#include "state.h"


static renderer_t renderer = {0};
static font_t font = {0};
static audio_t audio = {0};

static state_type current_state = STATE_MENU;
static state_t states[STATE_COUNT] = {0};


static void init()
{
	renderer_create(&renderer);
	font_load(&font, "res/press_start_2p.png", "res/press_start_2p.fnt");
	audio_create(&audio);

	states[STATE_GAME].game_state.audio = &audio;

	// If the save file exist, read from it
	FILE *file = fopen("data.bin", "rb");
	if (file)
	{
		fread(save_data, sizeof(uint32_t), SAVE_DATA_COUNT, file);
		fclose(file);
	}
}


static void destroy()
{
	renderer_destroy(&renderer);
	font_destroy(&font);
	audio_destroy(&audio);
}


static int32_t active_button = 0;

static void update()
{
	glClear(GL_COLOR_BUFFER_BIT);
	glClearColor(0.15f, 0.15f, 0.15f, 1.f);
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

	current_state = state_update(states, current_state, &renderer, &font);
}

int main(void)
{
	window_create(1280, 720,
				  "Dodge Them!",
				  init, destroy, update);

	{
		GLFWimage icons[2];
		icons[0].pixels = stbi_load("res/icon.png", &icons[0].width, &icons[0].height, 0, STBI_rgb_alpha);
		icons[1].pixels = stbi_load("res/icon_small.png", &icons[1].width, &icons[1].height, 0, STBI_rgb_alpha);
		glfwSetWindowIcon(window.handle, 2, icons);
		stbi_image_free(icons[0].pixels);
		stbi_image_free(icons[1].pixels);
	}

	window_run();
	return 0;
}
