static GLuint shader_compile(const char *source, GLenum type)
{
	GLuint handle = glCreateShader(type);

	glShaderSource(handle, 1, &source, 0);
	glCompileShader(handle);

	GLint compiled = 0;
	glGetShaderiv(handle, GL_COMPILE_STATUS, &compiled);
	if (!compiled)
	{
		char log[512] = {0};
		glGetShaderInfoLog(handle, 512, 0, log);
		fprintf(stderr, "[ERROR] %s", log);
	}

	return handle;
}

static GLuint shader_create(const char *vertex_source, const char *fragment_source)
{
	GLuint handle = glCreateProgram();
	GLuint vs = shader_compile(vertex_source, GL_VERTEX_SHADER);
	GLuint fs = shader_compile(fragment_source, GL_FRAGMENT_SHADER);

	glAttachShader(handle, vs);
	glAttachShader(handle, fs);
	glLinkProgram(handle);
	glValidateProgram(handle);

	glDeleteShader(vs);
	glDeleteShader(fs);

	return handle;
}
