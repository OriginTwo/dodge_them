typedef struct texture_t
{
	GLuint handle;
	int32_t width;
	int32_t height;
} texture_t;

typedef struct font_t
{
	texture_t texture;
	int16_t line_height;
	int16_t char_x[95];
	int16_t char_y[95];
	int16_t char_w[95];
	int16_t char_h[95];
	int16_t char_x_offset[95];
	int16_t char_y_offset[95];
	int16_t char_x_advance[95];
} font_t;