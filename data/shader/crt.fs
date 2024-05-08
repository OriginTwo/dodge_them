// modified from: https://www.shadertoy.com/view/4sf3Dr

#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;

out vec4 finalColor;

void main()
{
	vec4 color;

	// chromatic aberration??
	color.r = texture(texture0, vec2(fragTexCoord.x - 0.0025, fragTexCoord.y)).r;
	color.g = texture(texture0, fragTexCoord).g;
	color.b = texture(texture0, vec2(fragTexCoord.x + 0.0025, fragTexCoord.y)).b;
	color.a = 1;

	// scanline
	color.rgb -= sin(fragTexCoord.y*textureSize(texture0, 0).y*2)*0.02;

	finalColor = color*fragColor;
}
