#define COLOR(_r, _g, _b, _a)  (color_t){ .r = (_r), .g = (_g), .b = (_b), .a = (_a) }
#define COLOR_ALPHA(color, _a) (color_t){ .r = (color).r, .g = (color).g, .b = (color).b, .a = (_a) }
#define RF(color)              (float)(color).r / 255.f
#define GF(color)              (float)(color).g / 255.f
#define BF(color)              (float)(color).b / 255.f
#define AF(color)              (float)(color).a / 255.f

#define RECT(x, y, w, h) (rect_t){ (int32_t)(x), (int32_t)(y), (int32_t)(w), (int32_t)(h) }


static int32_t random_int(int32_t min, int32_t max)
{
	return (rand() % (max - min)) + min;
}

static float random_float(float min, float max)
{
	return ((float)rand() / (float)RAND_MAX) * (max - min) + min;
}

static bool32_t char_is_space(char c)
{
	return (c <= 32);
}

static bool32_t char_is_alpha(char c)
{
	return ((c >= 'a' && c <= 'z') ||
			(c >= 'A' && c <= 'Z'));
}

static bool32_t char_is_digit(char c)
{
	return (c >= '0' && c <= '9');
}

static bool32_t string_compare(const char *str1, const char *str2)
{
	bool32_t result = 1;

	if (str1 && str2)
	{
		for (uint32_t i = 0;; ++i)
		{
			if (str1[i] != str2[i])
			{
				result = 0;
				break;
			}
			if (str1[i] == 0 && str2[i] == 0)
			{
				break;
			}
		}
	}
	else
	{
		result = 0;
	}

	return result;
}

static int32_t string_get_first_int(const char *str)
{
	int32_t result = 0;
	int32_t last_digit = -1;

	for (int32_t i = 0; str[i]; ++i)
	{
		if (char_is_digit(str[i]))
		{
			last_digit = i;
		}
		else if (last_digit != -1)
		{
			break;
		}
	}

	if (last_digit >= 0)
	{
		int32_t digit_multiplier = 1;
		for (int32_t i = last_digit; i >= 0; --i)
		{
			if (char_is_digit(str[i]))
			{
				int32_t digit = str[i] - '0';
				result += digit * digit_multiplier;
				digit_multiplier *= 10;
			}
			else
			{
				if (str[i] == '-')
				{
					result *= -1;
				}
				break;
			}
		}
	}

	return result;
}

static char *file_load(const char *filename, uint32_t *file_len)
{
	char *result = 0;
	FILE *file = fopen(filename, "rb");

	if (file)
	{
		fseek(file, 0, SEEK_END);
		long file_size = ftell(file);
		fseek(file, 0, SEEK_SET);

		result = malloc(file_size + 1);
		if (result)
		{
			fread(result, 1, file_size, file);
			result[file_size] = 0;
		}

		if (file_len)
		{
			*file_len = (uint32_t)file_size;
		}

		fclose(file);
	}

	return result;
}

static bool32_t rect_collide(rect_t a, rect_t b)
{
	return (!(a.x + a.width <= b.x || a.x >= b.x + b.width) &&
			!(a.y + a.height <= b.y || a.y >= b.y + b.height));
}
