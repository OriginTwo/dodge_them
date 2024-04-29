#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;

uniform vec2 textureSize;
uniform float outlineSize = 1;
uniform vec4 outlineColor;

out vec4 finalColor;

void main()
{
	vec2 size = vec2(
		outlineSize/textureSize.x,
		outlineSize/textureSize.y);

	float left  = texture(texture0, fragTexCoord + vec2(-size.x, 0)).a;
	float right = texture(texture0, fragTexCoord + vec2( size.x, 0)).a;
	float up    = texture(texture0, fragTexCoord + vec2(0,  size.y)).a;
	float down  = texture(texture0, fragTexCoord + vec2(0, -size.y)).a;
	float outline = min(left + right + up + down, 1.0);

	vec4 color = texture(texture0, fragTexCoord)*fragColor;
	finalColor = mix(color, outlineColor, outline - color.a);
}
