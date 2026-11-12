#define STBI_ONLY_PNG
#define STB_IMAGE_IMPLEMENTATION
#include <stb_image.h>

static texture_t texture_init(uint8_t *data, int32_t width, int32_t height)
{
	texture_t texture = {
		.width = width,
		.height = height
	};

	glGenTextures(1, &texture.handle);
	glBindTexture(GL_TEXTURE_2D, texture.handle);

	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);

	glBindTexture(GL_TEXTURE_2D, 0);

	return texture;
}

static texture_t texture_load(const char *filename)
{
	int32_t width;
	int32_t height;
	uint8_t *pixels = stbi_load(filename, &width, &height, 0, STBI_rgb_alpha);
	texture_t result = texture_init(pixels, width, height);
	stbi_image_free(pixels);
	return result;
}

static void texture_destroy(texture_t *texture)
{
	glDeleteTextures(1, &texture->handle);
	texture->handle = 0;
	texture->width = 0;
	texture->height = 0;
}

static void font_load(font_t *font, const char *tex_filename, const char *fnt_filename)
{
	font->texture = texture_load(tex_filename);

	uint32_t file_len;
	char *file_data = file_load(fnt_filename, &file_len);

	char name[32] = {0};
	char value[32] = {0};

	enum
	{
		READ_none,
		READ_name,
		READ_value
	};

	int8_t read_char = 0;
	int8_t read_state = READ_none;
	bool32_t commented = 0;
	uint32_t read_pos = 0;

	for (uint32_t i = 0; i < file_len;)
	{
		if (file_data[i] == '#')
		{
			commented = 1;
		}

		if (commented)
		{
			if (file_data[i] == '\n')
			{
				commented = 0;
			}
			i++;
		}
		else
		{
			switch (read_state)
			{
				case READ_none:
				{
					if (char_is_alpha(file_data[i]))
					{
						read_state = READ_name;
						read_pos = i;
					}
					else
					{
						i++;
					}
					break;
				}

				case READ_name:
				{
					if (file_data[i] == '=')
					{
						int16_t name_len = i - read_pos;
						strncpy(name, file_data + read_pos, name_len);
						name[name_len] = 0;
						read_state = READ_value;
						read_pos = ++i;
					}
					else
					{
						i++;
					}
					break;
				}

				case READ_value:
				{
					if (char_is_space(file_data[i]) || i == file_len - 1)
					{
						int16_t value_len = i - read_pos;
						strncpy(value, file_data + read_pos, value_len);
						value[value_len] = 0;
						if (string_compare(name, "char id"))
						{
							read_char = (int8_t)(string_get_first_int(value) - 32);
							if (read_char < 0 || read_char > 95)
							{
								read_char = 0;
							}
						}
						else if (string_compare(name, "x"))
						{
							font->char_x[read_char] = (int16_t)string_get_first_int(value);
						}
						else if (string_compare(name, "y"))
						{
							font->char_y[read_char] = (int16_t)string_get_first_int(value);
						}
						else if (string_compare(name, "width"))
						{
							font->char_w[read_char] = (int16_t)string_get_first_int(value);
						}
						else if (string_compare(name, "height"))
						{
							font->char_h[read_char] = (int16_t)string_get_first_int(value);
						}
						else if (string_compare(name, "xoffset"))
						{
							font->char_x_offset[read_char] = (int16_t)string_get_first_int(value);
						}
						else if (string_compare(name, "yoffset"))
						{
							font->char_y_offset[read_char] = (int16_t)string_get_first_int(value);
						}
						else if (string_compare(name, "xadvance"))
						{
							font->char_x_advance[read_char] = (int16_t)string_get_first_int(value) - 0;
						}
						else if (string_compare(name, "lineHeight"))
						{
							font->line_height = (int16_t)string_get_first_int(value);
						}
						read_state = READ_none;
					}
					else
					{
						i++;
					}
					break;
				}

				default:
				{
					i++;
					break;
				}
			}
		}
	}
}

static void font_destroy(font_t *font)
{
	texture_destroy(&font->texture);
}

static int32_t font_get_text_width(font_t *font, const char *text)
{
	int32_t result = 0;

	for (uint32_t i = 0; text[i]; ++i)
	{
		if (text[i] >= 32 && text[i] < 127)
		{
			result += font->char_x_advance[text[i] - 32];
		}
	}

	return result;
}
