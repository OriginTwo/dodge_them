#define PI 3.14159265358979323846f

#define SIGN(x)             ((x) < 0 ? -1 : (x) > 0 ? 1 : 0)
#define ABS(x)              ((x) < 0 ? -(x) : (x))
#define MAX(a, b)           ((a) > (b) ? (a) : (b))
#define MIN(a, b)           ((a) < (b) ? (a) : (b))
#define CLAMP(a, min, max)  (MAX(min, MIN(max, a)))

INLINE float radian(float degree)
{
	return degree * PI/180.f;
}

INLINE float degree(float radian)
{
	return radian * 180.f/PI;
}

INLINE float lerp(float start, float end, float percent)
{
	return start + (end - start) * percent;
}

// --------------------------------------------------------
// Float Vector 2
// --------------------------------------------------------
#define VEC2(x, y) vec2_init(x, y)

INLINE vec2_t vec2_init(float x, float y)
{
	return (vec2_t){ x, y };
}

// --------------------------------------------------------
// Float Vector 3
// --------------------------------------------------------
#define VEC3(x, y, z) vec3_init(x, y, z)

INLINE vec3_t vec3_init(float x, float y, float z)
{
	return (vec3_t){ x, y, z };
}

// --------------------------------------------------------
// Float Vector 4
// --------------------------------------------------------
#define VEC4(x, y, z, w) vec4_init(x, y, z, w)

INLINE vec4_t vec4_init(float x, float y, float z, float w)
{
	return (vec4_t){ x, y, z, w };
}

// --------------------------------------------------------
// Integer Vector 2
// --------------------------------------------------------
#define IVEC2(x, y) ivec2_init(x, y)

INLINE ivec2_t ivec2_init(int32_t x, int32_t y)
{
	return (ivec2_t){ x, y };
}

// --------------------------------------------------------
// Integer Vector 3
// --------------------------------------------------------
#define IVEC3(x, y, z) ivec3_init(x, y, z)

INLINE ivec3_t ivec3_init(int32_t x, int32_t y, int32_t z)
{
	return (ivec3_t){ x, y, z };
}

// --------------------------------------------------------
// Integer Vector 4
// --------------------------------------------------------
#define IVEC4(x, y, z, w) ivec4_init(x, y, z, w)

INLINE ivec4_t ivec4_init(int32_t x, int32_t y, int32_t z, int32_t w)
{
	return (ivec4_t){ x, y, z, w };
}

// --------------------------------------------------------
// 3x3 Matrix
// --------------------------------------------------------
// 1 0 0
// 0 1 0
// 0 0 1
#define MAT3_IDENTITY_INIT {\
{ 1.0f, 0.0f, 0.0f },\
{ 0.0f, 1.0f, 0.0f },\
{ 0.0f, 0.0f, 1.0f },\
}

static void mat3_identity(mat3_t dest)
{
	memset(dest, 0, sizeof(mat3_t));
	dest[0][0] = 1.f;
	dest[1][1] = 1.f;
	dest[2][2] = 1.f;
}

INLINE void mat3_zero(mat3_t dest)
{
	memset(dest, 0, sizeof(mat3_t));
}

static void mat3_mul(mat3_t a, mat3_t b, mat3_t dest)
{
	for (int32_t c = 0; c < 3; ++c)
	{
		for (int32_t r = 0; r < 3; ++r)
		{
			dest[c][r] =
				a[0][r] * b[c][0] +
				a[1][r] * b[c][1] +
				a[2][r] * b[c][2];
		}
	}
}

static vec2_t mat3_mul_vec2(mat3_t m, vec2_t v)
{
	vec2_t result = {
		m[0][0]*v.x + m[0][1]*v.y + m[0][2],
		m[1][0]*v.x + m[1][1]*v.y + m[1][2]
	};
	return result;
}

static void mat3_translate(mat3_t dest, vec2_t t)
{
	mat3_t dest_cpy;
	memcpy(dest_cpy, dest, sizeof(mat3_t));

	mat3_t temp = MAT3_IDENTITY_INIT;
	temp[0][2] = t.x;
	temp[1][2] = t.y;

	mat3_mul(dest_cpy, temp, dest);
}

static void mat3_rotate(mat3_t dest, float angle)
{
	mat3_t dest_cpy;
	memcpy(dest_cpy, dest, sizeof(mat3_t));

	mat3_t temp = MAT3_IDENTITY_INIT;
	temp[0][0] =  cosf(angle); temp[0][1] = sinf(angle);
	temp[1][0] = -sinf(angle); temp[1][1] = cosf(angle);

	mat3_mul(dest_cpy, temp, dest);
}

// --------------------------------------------------------
// 4x4 Matrix
// --------------------------------------------------------
// 1 0 0 0
// 0 1 0 0
// 0 0 1 0
// 0 0 0 1
#define MAT4_IDENTITY_INIT {\
{ 1.0f, 0.0f, 0.0f, 0.0f },\
{ 0.0f, 1.0f, 0.0f, 0.0f },\
{ 0.0f, 0.0f, 1.0f, 0.0f },\
{ 0.0f, 0.0f, 0.0f, 1.0f }\
}

static void mat4_identity(mat4_t dest)
{
	memset(dest, 0, sizeof(mat4_t));
	dest[0][0] = 1.f;
	dest[1][1] = 1.f;
	dest[2][2] = 1.f;
	dest[3][3] = 1.f;
}

INLINE void mat4_zero(mat4_t dest)
{
	memset(dest, 0, sizeof(mat4_t));
}

INLINE void mat4_ortho(float left, float right,
					   float bottom, float top,
					   float near, float far,
					   mat4_t dest)
{
	mat4_zero(dest);

	float rl =  1.f / (right - left);
	float tb =  1.f / (top - bottom);
	float fn = -1.f / (far - near);

	dest[0][0] = 2.f * rl;
	dest[1][1] = 2.f * tb;
	dest[2][2] = 2.f * fn;

	dest[3][0] = -(right + left) * rl;
	dest[3][1] = -(top + bottom) * tb;
	dest[3][2] =  (far + near) * fn;
	dest[3][3] = 1.f;
}
