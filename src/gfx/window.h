#define GLAD_GL_IMPLEMENTATION
#include <glad/glad.h>
#include <glfw/glfw3.h>

typedef struct window_t
{
	GLFWwindow *handle;
	int32_t width;
	int32_t height;
	
	float frame_delta;
	double last_time;
	
	int32_t mouse_x;
	int32_t mouse_y;
	int32_t last_mouse_x;
	int32_t last_mouse_y;
	int32_t mouse_scroll_x;
	int32_t mouse_scroll_y;
	
	bool8_t button_down[GLFW_MOUSE_BUTTON_LAST];
	bool8_t button_last[GLFW_MOUSE_BUTTON_LAST];
	bool8_t key_down[GLFW_KEY_LAST];
	bool8_t key_last[GLFW_KEY_LAST];
	
	void (*init)();
	void (*destroy)();
	void (*update)();
} window_t;