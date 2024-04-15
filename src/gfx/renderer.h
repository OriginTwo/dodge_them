#include "asset.h"

// Render flags
#define RENDERER_TEXT_ALIGN_CENTER_X (1 << 0)
#define RENDERER_TEXT_ALIGN_CENTER_Y (1 << 1)
#define RENDERER_TEXT_ALIGN_CENTER (RENDERER_TEXT_ALIGN_CENTER_X | RENDERER_TEXT_ALIGN_CENTER_Y)

typedef struct render_source_t
{
	int16_t min_x;
	int16_t min_y;
	int16_t max_x;
	int16_t max_y;
} render_source_t;

#define RENDER_SOURCE(min_x, min_y, max_x, max_y) (render_source_t){ (int16_t)(min_x), (int16_t)(min_y), (int16_t)(max_x), (int16_t)(max_y) }

typedef enum render_request_type
{
	RENDER_REQUEST_NULL,
	RENDER_REQUEST_FILLED_RECT,
	RENDER_REQUEST_TEXTURE,
	RENDER_REUQEST_COUNT
} render_request_type;

typedef struct render_request_t
{
	render_request_type type;
	texture_t *texture;
	
	uint32_t data_size;
	uint32_t data_offset;
	int32_t flags;
} render_request_t;

typedef struct renderer_t
{
	// Filled rect vertex: x,y, r,g,b,a
#define RENDERER_MAX_FILLED_RECT 1024
#define RENDERER_MAX_FILLED_RECT_VERTEX (RENDERER_MAX_FILLED_RECT * 4)
#define RENDERER_FILLED_RECT_VERTEX_SIZE 6
#define RENDERER_BYTES_PER_FILLED_RECT_VERTEX (RENDERER_FILLED_RECT_VERTEX_SIZE * sizeof(GLfloat))
	GLuint filled_rect_shader;
	GLuint filled_rect_vao;
	GLuint filled_rect_vbo;
	GLuint filled_rect_ibo;
	GLfloat *filled_rect_vertices;
	uint32_t filled_rect_count;
	
	// Texture vertex: x,y, u,v, r,g,b,a
#define RENDERER_MAX_TEXTURE 1024
#define RENDERER_MAX_TEXTURE_VERTEX (RENDERER_MAX_TEXTURE * 4)
#define RENDERER_TEXTURE_VERTEX_SIZE 8
#define RENDERER_BYTES_PER_TEXTURE_VERTEX (RENDERER_TEXTURE_VERTEX_SIZE * sizeof(GLfloat))
	GLuint texture_shader;
	GLuint texture_vao;
	GLuint texture_vbo;
	GLuint texture_ibo;
	GLfloat *texture_vertices;
	uint32_t texture_count;
	
#define RENDERER_MAX_REQUEST 128
	uint32_t request_count;
	render_request_t requests[RENDERER_MAX_REQUEST];
	render_request_t active_request;
} renderer_t;