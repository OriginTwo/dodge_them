typedef int8_t   bool8_t;
typedef int32_t  bool32_t;

typedef struct rect_t
{
	int32_t x;
	int32_t y;
	int32_t width;
	int32_t height;
} rect_t;

typedef union color_t
{
	uint32_t data; // ABGR
	struct { uint8_t r, g, b, a; };
} color_t;

typedef union vec2_t
{
	float elements[2];
	struct { float x, y; };
} vec2_t;
typedef union vec3_t
{
	float elements[3];
	struct { float x, y, z; };
	struct { float r, g, b; };
} vec3_t;
typedef union vec4_t
{
	float elements[4];
	struct { float x, y, z, w; };
	struct { float r, g, b, a; };
} vec4_t;

typedef union ivec2_t
{
	int32_t elements[2];
	struct { int32_t x, y; };
} ivec2_t;
typedef union ivec3_t
{
	int32_t elements[3];
	struct { int32_t x, y, z; };
} ivec3_t;
typedef union ivec4_t
{
	int32_t elements[4];
	struct { int32_t x, y, z, w; };
} ivec4_t;

typedef float mat3_t[3][3];
typedef float mat4_t[4][4];