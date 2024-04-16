#define DR_WAV_IMPLEMENTATION
#include <dr_wav.h>

#define MA_NO_ENCODING
#define MA_NO_DECODING
#define MINIAUDIO_IMPLEMENTATION
#include <miniaudio.h>

#define AUDIO_SOURCE_MAX 64

typedef struct audio_source_t
{
	bool32_t loaded;
	bool32_t playing;
	bool32_t loop;
	
	float volume;
	
	int16_t *data;
	int16_t channels;
	uint32_t sample_pos;
	uint32_t sample_count;
	uint32_t sample_rate;
} audio_source_t;

typedef struct audio_t
{
	ma_device device;
	audio_source_t sources[AUDIO_SOURCE_MAX];
	float master_volume;
} audio_t;

// Forward declaration
static void _miniaudio_data_callback(ma_device *device, void *output, const void *input, ma_uint32 frame_count);