#include "shader.c"
#include "asset.c"

static void renderer_create(renderer_t *renderer)
{
	// Shaders
	{
#include "shader_source.h"
		renderer->filled_rect_shader = shader_create(filled_rect_v, filled_rect_f);
		renderer->texture_shader = shader_create(texture_v, texture_f);
	}
	
	// Filled rect
	{
		glGenVertexArrays(1, &renderer->filled_rect_vao);
		glBindVertexArray(renderer->filled_rect_vao);
		
		glGenBuffers(1, &renderer->filled_rect_vbo);
		glBindBuffer(GL_ARRAY_BUFFER, renderer->filled_rect_vbo);
		glBufferData(GL_ARRAY_BUFFER, RENDERER_MAX_FILLED_RECT_VERTEX * RENDERER_BYTES_PER_FILLED_RECT_VERTEX, 0, GL_DYNAMIC_DRAW);
		
		// Position
		glEnableVertexAttribArray(0);
		glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, RENDERER_BYTES_PER_FILLED_RECT_VERTEX, (void *)0);
		
		// Color
		glEnableVertexAttribArray(1);
		glVertexAttribPointer(1, 4, GL_FLOAT, GL_FALSE, RENDERER_BYTES_PER_FILLED_RECT_VERTEX, (void *)(sizeof(GLfloat) * 2));
		
		glGenBuffers(1, &renderer->filled_rect_ibo);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, renderer->filled_rect_ibo);
		{
			GLuint offset = 0;
			GLuint indices[RENDERER_MAX_FILLED_RECT * 6] = {0};
			
			for (GLuint i = 0; i < RENDERER_MAX_FILLED_RECT * 6; i += 6)
			{
				indices[i + 0] = offset + 0;
				indices[i + 1] = offset + 1;
				indices[i + 2] = offset + 2;
				indices[i + 3] = offset + 2;
				indices[i + 4] = offset + 3;
				indices[i + 5] = offset + 0;
				offset += 4;
			}
			
			glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
		}
		
		renderer->filled_rect_vertices = malloc(RENDERER_MAX_FILLED_RECT_VERTEX * RENDERER_BYTES_PER_FILLED_RECT_VERTEX);
	}
	
	// Texture
	{
		glGenVertexArrays(1, &renderer->texture_vao);
		glBindVertexArray(renderer->texture_vao);
		
		glGenBuffers(1, &renderer->texture_vbo);
		glBindBuffer(GL_ARRAY_BUFFER, renderer->texture_vbo);
		glBufferData(GL_ARRAY_BUFFER, RENDERER_MAX_TEXTURE_VERTEX * RENDERER_BYTES_PER_TEXTURE_VERTEX, 0, GL_DYNAMIC_DRAW);
		
		// Position
		glEnableVertexAttribArray(0);
		glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, RENDERER_BYTES_PER_TEXTURE_VERTEX, (void *)0);
		
		// UV
		glEnableVertexAttribArray(1);
		glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, RENDERER_BYTES_PER_TEXTURE_VERTEX, (void *)(sizeof(GLfloat) * 2));
		
		// Color
		glEnableVertexAttribArray(2);
		glVertexAttribPointer(2, 4, GL_FLOAT, GL_FALSE, RENDERER_BYTES_PER_TEXTURE_VERTEX, (void *)(sizeof(GLfloat) * 4));
		
		glGenBuffers(1, &renderer->texture_ibo);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, renderer->texture_ibo);
		{
			GLuint offset = 0;
			GLuint indices[RENDERER_MAX_TEXTURE * 6] = {0};
			
			for (GLuint i = 0; i < RENDERER_MAX_TEXTURE * 6; i += 6)
			{
				indices[i + 0] = offset + 0;
				indices[i + 1] = offset + 1;
				indices[i + 2] = offset + 2;
				indices[i + 3] = offset + 2;
				indices[i + 4] = offset + 3;
				indices[i + 5] = offset + 0;
				offset += 4;
			}
			
			glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
		}
		
		renderer->texture_vertices = malloc(RENDERER_MAX_TEXTURE_VERTEX * RENDERER_BYTES_PER_TEXTURE_VERTEX);
	}
	
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindVertexArray(0);
}

static void renderer_destroy(renderer_t *renderer)
{
	glDeleteProgram(renderer->filled_rect_shader);
	glDeleteVertexArrays(1, &renderer->filled_rect_vao);
	glDeleteBuffers(1, &renderer->filled_rect_vbo);
	glDeleteBuffers(1, &renderer->filled_rect_ibo);
	free(renderer->filled_rect_vertices);
	
	glDeleteProgram(renderer->texture_shader);
	glDeleteVertexArrays(1, &renderer->texture_vao);
	glDeleteBuffers(1, &renderer->texture_vbo);
	glDeleteBuffers(1, &renderer->texture_ibo);
	free(renderer->texture_vertices);
}

static void renderer_finish_active_request(renderer_t *renderer)
{
	ASSERT(renderer->request_count < RENDERER_MAX_REQUEST);
	renderer->requests[renderer->request_count++] = renderer->active_request;
	renderer->active_request.type = RENDER_REQUEST_NULL;
}

static void renderer_begin(renderer_t *renderer)
{
	renderer->filled_rect_count = 0;
	renderer->texture_count = 0;
	
	renderer->request_count = 0;
	renderer->active_request.type = RENDER_REQUEST_NULL;
}

static void renderer_end(renderer_t *renderer)
{
	renderer_finish_active_request(renderer);
	
	mat4_t projection;
	mat4_ortho(0.f, (float)window.width, (float)window.height, 0.f, -1.f, 1.f, projection);
	
	for (uint32_t i = 0; i < renderer->request_count; ++i)
	{
		render_request_t *request = renderer->requests + i;
		
		switch (request->type)
		{
			case RENDER_REQUEST_FILLED_RECT:
			{
				glUseProgram(renderer->filled_rect_shader);
				glBindVertexArray(renderer->filled_rect_vao);
				glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, renderer->filled_rect_ibo);
				
				glBindBuffer(GL_ARRAY_BUFFER, renderer->filled_rect_vbo);
				glBufferSubData(GL_ARRAY_BUFFER, 0, request->data_size, renderer->filled_rect_vertices + request->data_offset/sizeof(GLfloat));
				
				glUniformMatrix4fv(glGetUniformLocation(renderer->filled_rect_shader, "u_projection"), 1, GL_FALSE, &projection[0][0]);
				
				glDrawElements(GL_TRIANGLES, request->data_size/RENDERER_BYTES_PER_FILLED_RECT_VERTEX/4*6, GL_UNSIGNED_INT, 0);
				
				break;
			}
			
			case RENDER_REQUEST_TEXTURE:
			{
				glUseProgram(renderer->texture_shader);
				glBindVertexArray(renderer->texture_vao);
				glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, renderer->texture_ibo);
				glBindTexture(GL_TEXTURE_2D, request->texture->handle);
				
				glBindBuffer(GL_ARRAY_BUFFER, renderer->texture_vbo);
				glBufferSubData(GL_ARRAY_BUFFER, 0, request->data_size, renderer->texture_vertices + request->data_offset/sizeof(GLfloat));
				
				glUniformMatrix4fv(glGetUniformLocation(renderer->texture_shader, "u_projection"), 1, GL_FALSE, &projection[0][0]);
				
				glDrawElements(GL_TRIANGLES, request->data_size/RENDERER_BYTES_PER_TEXTURE_VERTEX/4*6, GL_UNSIGNED_INT, 0);
				
				break;
			}
			
			default: break;
		}
	}
	
	glUseProgram(0);
	glBindVertexArray(0);
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
	glBindTexture(GL_TEXTURE_2D, 0);
}

static void renderer_push_filled_rectv(renderer_t *renderer,
									   ivec2_t p1,
									   ivec2_t p2,
									   ivec2_t p3,
									   ivec2_t p4,
									   color_t color00,
									   color_t color10,
									   color_t color11,
									   color_t color01)
{
	if (renderer->filled_rect_count >= RENDERER_MAX_FILLED_RECT)
	{
		renderer_end(renderer);
		renderer_begin(renderer);
	}
	
	render_request_type request_type = RENDER_REQUEST_FILLED_RECT;
	if (renderer->active_request.type != request_type)
	{
		renderer_finish_active_request(renderer);
		
		renderer->active_request.type = request_type;
		renderer->active_request.data_offset = renderer->filled_rect_count * RENDERER_BYTES_PER_FILLED_RECT_VERTEX*4;
		renderer->active_request.data_size = RENDERER_BYTES_PER_FILLED_RECT_VERTEX*4;
		renderer->active_request.flags = 0;
	}
	else
	{
		renderer->active_request.data_size += RENDERER_BYTES_PER_FILLED_RECT_VERTEX*4;
	}
	
	GLfloat *data = renderer->filled_rect_vertices + renderer->filled_rect_count*RENDERER_FILLED_RECT_VERTEX_SIZE*4;
	
	*data++ = (GLfloat)p1.x;
	*data++ = (GLfloat)p1.y;
	*data++ = RF(color00);
	*data++ = GF(color00);
	*data++ = BF(color00);
	*data++ = AF(color00);
	
	*data++ = (GLfloat)p2.x;
	*data++ = (GLfloat)p2.y;
	*data++ = RF(color10);
	*data++ = GF(color10);
	*data++ = BF(color10);
	*data++ = AF(color10);
	
	*data++ = (GLfloat)p3.x;
	*data++ = (GLfloat)p3.y;
	*data++ = RF(color11);
	*data++ = GF(color11);
	*data++ = BF(color11);
	*data++ = AF(color11);
	
	*data++ = (GLfloat)p4.x;
	*data++ = (GLfloat)p4.y;
	*data++ = RF(color01);
	*data++ = GF(color01);
	*data++ = BF(color01);
	*data++ = AF(color01);
	
	renderer->filled_rect_count++;
}

static void renderer_push_filled_rect(renderer_t *renderer,
									  rect_t rect,
									  color_t color)
{
	renderer_push_filled_rectv(renderer,
							   IVEC2(rect.x,              rect.y),
							   IVEC2(rect.x + rect.width, rect.y),
							   IVEC2(rect.x + rect.width, rect.y + rect.height),
							   IVEC2(rect.x,              rect.y + rect.height),
							   color, color, color, color);
}

static void renderer_push_rotated_filled_rect(renderer_t *renderer,
											  rect_t rect,
											  float angle,
											  color_t color)
{
	mat3_t transform = MAT3_IDENTITY_INIT;
	mat3_translate(transform, VEC2(-rect.width/2, -rect.height/2));
	mat3_rotate(transform, angle);
	mat3_translate(transform, VEC2(rect.x, rect.y));
	
	vec2_t p1f = mat3_mul_vec2(transform, VEC2(0, 0));
	ivec2_t p1 = { p1f.x, p1f.y };
	
	vec2_t p2f = mat3_mul_vec2(transform, VEC2(rect.width, 0));
	ivec2_t p2 = { p2f.x, p2f.y };
	
	vec2_t p3f = mat3_mul_vec2(transform, VEC2(rect.width, rect.height));
	ivec2_t p3 = { p3f.x, p3f.y };
	
	vec2_t p4f = mat3_mul_vec2(transform, VEC2(0, rect.height));
	ivec2_t p4 = { p4f.x, p4f.y };
	
	renderer_push_filled_rectv(renderer,
							   p1, p2, p3, p4,
							   color, color, color, color);
}

static void renderer_push_texturev(renderer_t *renderer,
								   rect_t rect,
								   texture_t *texture,
								   render_source_t source,
								   color_t color00,
								   color_t color10,
								   color_t color11,
								   color_t color01)
{
	if (renderer->texture_count >= RENDERER_MAX_TEXTURE)
	{
		renderer_end(renderer);
		renderer_begin(renderer);
	}
	
	render_request_type request_type = RENDER_REQUEST_TEXTURE;
	if (renderer->active_request.type != request_type ||
		renderer->active_request.texture != texture)
	{
		renderer_finish_active_request(renderer);
		
		renderer->active_request.type = request_type;
		renderer->active_request.texture = texture;
		renderer->active_request.data_offset = renderer->texture_count * RENDERER_BYTES_PER_TEXTURE_VERTEX*4;
		renderer->active_request.data_size = RENDERER_BYTES_PER_TEXTURE_VERTEX*4;
		renderer->active_request.flags = 0;
	}
	else
	{
		renderer->active_request.data_size += RENDERER_BYTES_PER_TEXTURE_VERTEX*4;
	}
	
	GLfloat src_min_x = (GLfloat)source.min_x / (GLfloat)texture->width;
	GLfloat src_min_y = (GLfloat)source.min_y / (GLfloat)texture->height;
	GLfloat src_max_x = (GLfloat)source.max_x / (GLfloat)texture->width;
	GLfloat src_max_y = (GLfloat)source.max_y / (GLfloat)texture->height;
	
	GLfloat *data = renderer->texture_vertices + renderer->texture_count*RENDERER_TEXTURE_VERTEX_SIZE*4;
	
	*data++ = (GLfloat)rect.x;
	*data++ = (GLfloat)rect.y;
	*data++ = src_min_x;
	*data++ = src_min_y;
	*data++ = RF(color00);
	*data++ = GF(color00);
	*data++ = BF(color00);
	*data++ = AF(color00);
	
	*data++ = (GLfloat)(rect.x + rect.width);
	*data++ = (GLfloat)rect.y;
	*data++ = src_max_x;
	*data++ = src_min_y;
	*data++ = RF(color10);
	*data++ = GF(color10);
	*data++ = BF(color10);
	*data++ = AF(color10);
	
	*data++ = (GLfloat)(rect.x + rect.width);
	*data++ = (GLfloat)(rect.y + rect.height);
	*data++ = src_max_x;
	*data++ = src_max_y;
	*data++ = RF(color11);
	*data++ = GF(color11);
	*data++ = BF(color11);
	*data++ = AF(color11);
	
	*data++ = (GLfloat)rect.x;
	*data++ = (GLfloat)(rect.y + rect.height);
	*data++ = src_min_x;
	*data++ = src_max_y;
	*data++ = RF(color01);
	*data++ = GF(color01);
	*data++ = BF(color01);
	*data++ = AF(color01);
	
	renderer->texture_count++;
}

static void renderer_push_texture(renderer_t *renderer,
								  rect_t rect,
								  texture_t *texture,
								  render_source_t source,
								  color_t color)
{
	renderer_push_texturev(renderer,
						   rect,
						   texture,
						   source,
						   color, color, color, color);
}

static void renderer_push_text_character(renderer_t *renderer,
										 font_t *font,
										 int32_t character,
										 rect_t rect,
										 color_t color)
{
	GLfloat uv_x = font->char_x[character];
	GLfloat uv_y = font->char_y[character];
	GLfloat uv_w = font->char_w[character];
	GLfloat uv_h = font->char_h[character];
	
	renderer_push_texture(renderer,
						  rect,
						  &font->texture,
						  RENDER_SOURCE(uv_x,
										uv_y,
										uv_x + uv_w,
										uv_y + uv_h),
						  color);
}

static void renderer_push_text(renderer_t *renderer,
							   font_t *font,
							   ivec2_t position,
							   const char *text,
							   color_t color,
							   float scale,
							   int32_t flags)
{
	vec2_t posf = { position.x, position.y };
	float width = 0.f;
	
	if (flags & RENDERER_TEXT_ALIGN_CENTER_X)
	{
		int32_t text_width = font_get_text_width(font, text);
		posf.x -= (float)text_width/2.f * scale;
	}
	if (flags & RENDERER_TEXT_ALIGN_CENTER_Y)
	{
		posf.y -= (float)font->line_height/2.f * scale;
	}
	
	for (uint32_t i = 0; text[i]; ++i)
	{
		char character = text[i];
		
		if (character > 32 && character < 127)
		{
			vec2_t size =  VEC2(font->char_w[character - 32] * scale,
								font->char_h[character - 32] * scale);
			vec2_t offset = VEC2(font->char_x_offset[character - 32] * scale,
								 font->char_y_offset[character - 32] * scale);
			
			vec2_t min = VEC2(posf.x + 0.f*size.x + offset.x,
							  posf.y + 0.f*size.y + offset.y);
			
			vec2_t max = VEC2(posf.x + 1.f*size.x + offset.x,
							  posf.y + 1.f*size.y + offset.y);
			
			renderer_push_text_character(renderer,
										 font,
										 character - 32,
										 RECT(min.x + 0.5f,
											  min.y + 0.5f,
											  max.x - min.x + 0.5f,
											  max.y - min.y + 0.5f),
										 color);
			
			posf.x += (float)font->char_x_advance[character - 32] * scale;
			width += (float)font->char_x_advance[character - 32] * scale;
		}
		else if (character == 32)
		{
			posf.x += (float)font->char_x_advance[character - 32] * scale;
			width += (float)font->char_x_advance[character - 32] * scale;
		}
	}
	
	//return (i32)width;
}