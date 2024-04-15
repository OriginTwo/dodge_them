static uint32_t audio_next_available_source_slot = 0;

static audio_source_t audio_source_load(const char *filename, float volume)
{
	audio_source_t source = {0};
	drwav wav = {0};
	
	drwav_init_file(&wav, filename, 0);
	
	source.data = malloc(wav.totalPCMFrameCount *wav.channels * sizeof(int16_t));
	drwav_read_pcm_frames_s16(&wav, wav.totalPCMFrameCount, source.data);
	
	source.loaded = 1;
	source.playing = 0;
	
	source.volume = volume;
	source.channels = wav.channels;
	source.sample_pos = 0;
	source.sample_count = wav.totalPCMFrameCount * wav.channels;
	source.sample_rate = wav.sampleRate;
	
	return source;
}

static void audio_source_destroy(audio_source_t *source)
{
	if (source->loaded)
	{
		source->loaded = 0;
		source->playing = 0;
		free(source->data);
	}
}

static void audio_source_play(audio_source_t *source)
{
	if (source->loaded)
	{
		source->playing = 1;
		source->sample_pos = 0;
	}
}

static void audio_create(audio_t *audio)
{
	audio->master_volume = 1.f;
	
	ma_device_config device_config   = ma_device_config_init(ma_device_type_playback);
	device_config.playback.format    = ma_format_s16;
	device_config.playback.channels  = 1;
	device_config.sampleRate         = 44100;
	device_config.dataCallback       = _miniaudio_data_callback;
	device_config.pUserData          = audio;
	
	ma_device_init(0, &device_config, &audio->device);
	ma_device_start(&audio->device);
}

static void audio_destroy(audio_t *audio)
{
	for (uint32_t i = 0; i < AUDIO_SOURCE_MAX; ++i)
	{
		audio_source_destroy(audio->sources + i);
	}
	
	ma_device_uninit(&audio->device);
}

// Return the index of the source in the audio sources array
static uint32_t audio_load_source(audio_t *audio, const char *filename, float volume)
{
	audio->sources[audio_next_available_source_slot++] = audio_source_load(filename, volume);
	return audio_next_available_source_slot - 1;
}

static void audio_play_source(audio_t *audio, uint32_t source_index, bool32_t loop)
{
	ASSERT(source_index < AUDIO_SOURCE_MAX);
	audio_source_t *source = audio->sources + source_index;
	source->loop = loop;
	audio_source_play(source);
}


static void _miniaudio_data_callback(ma_device *device,
									 void *output,
									 const void *input,
									 ma_uint32 frame_count)
{
	audio_t *audio = (audio_t *)device->pUserData;
	drwav_int16 *sample_out = (drwav_int16 *)output;
	
	for (uint32_t i = 0; i < AUDIO_SOURCE_MAX; ++i)
	{
		audio_source_t *source = audio->sources + i;
		
		if (source->loaded && source->playing)
		{
			float sample_volume = source->volume * audio->master_volume;
			
			for (uint32_t frame_write = 0; frame_write < frame_count; ++frame_write)
			{
				sample_out[frame_write] += (int16_t)(source->data[source->sample_pos++] * sample_volume);
				
				if (source->sample_pos >= source->sample_count)
				{
					if (source->loop)
					{
						source->sample_pos = 0;
					}
					else
					{
						source->playing = 0;
						source->sample_pos = 0;
						break;
					}
				}
			}
		}
	}
}