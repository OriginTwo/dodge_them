const char *filled_rect_v =
"#version 330 core\n"
"layout (location = 0) in vec2 v_position;\n"
"layout (location = 1) in vec4 v_color;\n"
"\n"
"uniform mat4 u_projection;\n"
"\n"
"out vec4 f_color;\n"
"\n"
"void main()\n"
"{\n"
"	gl_Position = u_projection * vec4(v_position, 0, 1);\n"
"	f_color = v_color;\n"
"}";

const char *filled_rect_f =
"#version 330 core\n"
"out vec4 o_color;\n"
"\n"
"in vec4 f_color;\n"
"\n"
"void main()\n"
"{\n"
"	o_color = f_color;\n"
"}";


const char *texture_v =
"#version 330 core\n"
"layout (location = 0) in vec2 v_position;\n"
"layout (location = 1) in vec2 v_uv;\n"
"layout (location = 2) in vec4 v_color;\n"
"\n"
"uniform mat4 u_projection;\n"
"\n"
"out vec2 f_uv;\n"
"out vec4 f_color;\n"
"\n"
"void main()\n"
"{\n"
"	gl_Position = u_projection * vec4(v_position, 0, 1);\n"
"	f_uv = v_uv;\n"
"	f_color = v_color;\n"
"}";

const char *texture_f =
"#version 330 core\n"
"out vec4 o_color;\n"
"\n"
"uniform sampler2D u_texture;\n"
"\n"
"in vec2 f_uv;\n"
"in vec4 f_color;\n"
"\n"
"void main()\n"
"{\n"
"	o_color = texture(u_texture, f_uv) * f_color;\n"
"}";