static window_t window = {0};

static void _glfw_cursor_pos_callback(GLFWwindow *_window,
									  double pos_x,
									  double pos_y)
{
	window.mouse_x = (int32_t)pos_x;
	window.mouse_y = (int32_t)pos_y;
}

static void _glfw_scroll_callback(GLFWwindow *_window,
								  double offset_x,
								  double offset_y)
{
	window.mouse_scroll_x = (int32_t)offset_x;
	window.mouse_scroll_y = (int32_t)offset_y;
}

static void _glfw_mouse_button_callback(GLFWwindow *_window,
										int32_t button,
										int32_t action,
										int32_t mods)
{
	if (button >= 0)
	{
		window.button_down[button] = action;
	}
}

static void _glfw_key_callback(GLFWwindow *_window,
							   int32_t key,
							   int32_t scancode,
							   int32_t action,
							   int32_t mods)
{
	if (key >= 0)
	{
		window.key_down[key] = action;
	}
}

static void window_create(int32_t width,
						  int32_t height,
						  const char *title,
						  void (*init)(),
						  void (*destroy)(),
						  void (*update)())
{
	window.width = width;
	window.height = height;
	window.init = init;
	window.destroy = destroy;
	window.update = update;
	
	if (!glfwInit())
	{
		ASSERT_MSG(0, "GLFW initialization failed");
	}
	
	glfwWindowHint(GLFW_RESIZABLE, GLFW_FALSE);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
	glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);
	window.handle = glfwCreateWindow(window.width, window.height, title, 0, 0);
	
	if (!window.handle)
	{
		glfwTerminate();
		ASSERT_MSG(0, "Window creation failed");
	}
	
	glfwMakeContextCurrent(window.handle);
	glfwSwapInterval(1);
	
	glfwSetCursorPosCallback(window.handle, _glfw_cursor_pos_callback);
	glfwSetScrollCallback(window.handle, _glfw_scroll_callback);
	glfwSetMouseButtonCallback(window.handle, _glfw_mouse_button_callback);
	glfwSetKeyCallback(window.handle, _glfw_key_callback);
	
	if (!gladLoadGL(glfwGetProcAddress))
	{
		glfwTerminate();
		ASSERT_MSG(0, "GLAD failed to load OpenGL function pointers");
	}
}

static void window_run()
{
	window.init();
	window.last_time = glfwGetTime();
	
#if defined(BUILD_DEBUG) && defined(DEBUG_PRINT_FPS)
	uint32_t frames = 0;
	double last_time = glfwGetTime();
#endif
	
	while (!glfwWindowShouldClose(window.handle))
	{
		double now = glfwGetTime();
		window.frame_delta = (float)(now - window.last_time);
		window.last_time = now;
		
		window.update();
#if defined(BUILD_DEBUG) && defined(DEBUG_PRINT_FPS)
		frames++;
#endif
		
		window.last_mouse_x = window.mouse_x;
		window.last_mouse_y = window.mouse_y;
		
		for (int32_t i = 0; i < GLFW_KEY_LAST; ++i)
		{
			window.key_last[i] = window.key_down[i];
		}
		for (int32_t i = 0; i < GLFW_MOUSE_BUTTON_LAST; ++i)
		{
			window.button_last[i] = window.button_down[i];
		}
		
#if defined(BUILD_DEBUG) && defined(DEBUG_PRINT_FPS)
		if (glfwGetTime() - last_time >= 1.0)
		{
			printf("%u fps\n", frames);
			last_time = glfwGetTime();
			frames = 0;
		}
#endif
		
		glfwSwapBuffers(window.handle);
		glfwPollEvents();
	}
	
	window.destroy();
	glfwTerminate();
}

static bool32_t key_is_pressed(int32_t key)
{
	return window.key_down[key] && !window.key_last[key];
}

static bool32_t key_is_released(int32_t key)
{
	return !window.key_down[key] && window.key_last[key];
}

static bool32_t key_is_held(int32_t key)
{
	return window.key_down[key] && window.key_last[key];
}

static bool32_t mouse_is_pressed(int32_t button)
{
	return window.button_down[button] && !window.button_last[button];
}

static bool32_t mouse_is_released(int32_t button)
{
	return !window.button_down[button] && window.button_last[button];
}

static bool32_t mouse_is_held(int32_t button)
{
	return window.button_down[button] && window.button_last[button];
}