package asset_desc_gen

import "core:os"
import "core:fmt"
import "core:strings"
import "core:path/filepath"

main :: proc()
{
	out_file, out_file_err := os.open("generated_asset_desc.odin", os.O_CREATE | os.O_TRUNC | os.O_WRONLY)
	if out_file_err != os.ERROR_NONE
	{
		fmt.printf("Couldn't open output file (%d)\n", out_file_err)
		return
	}
	defer os.close(out_file)

	fmt.fprint(out_file, "package asset\n\n")
	fmt.fprint(out_file, "EMBED_ASSETS :: #config(DIST_BUILD, false)\n\n")

	TEXTURE_PATH      :: "data/image"
	TEXTURE_ENUM_NAME :: "Texture_ID"
	TEXTURE_DESC_NAME :: "texture_asset_descs"
	TEXTURE_EXT       :: ".png"

	FONT_PATH      :: "data/font"
	FONT_ENUM_NAME :: "Font_ID"
	FONT_DESC_NAME :: "font_asset_descs"
	FONT_EXT       :: ".ttf"

	SOUND_PATH      :: "data/sound"
	SOUND_ENUM_NAME :: "Sound_ID"
	SOUND_DESC_NAME :: "sound_asset_descs"
	SOUND_EXT       :: ".wav"

	MUSIC_PATH      :: "data/music"
	MUSIC_ENUM_NAME :: "Music_ID"
	MUSIC_DESC_NAME :: "music_asset_descs"
	MUSIC_EXT       :: ".ogg"

	gen_enum(out_file, TEXTURE_PATH, TEXTURE_ENUM_NAME, TEXTURE_EXT)
	gen_enum(out_file, FONT_PATH,    FONT_ENUM_NAME,    FONT_EXT)
	gen_enum(out_file, SOUND_PATH,   SOUND_ENUM_NAME,   SOUND_EXT)
	gen_enum(out_file, MUSIC_PATH,   MUSIC_ENUM_NAME,   MUSIC_EXT)

	gen_desc(out_file, TEXTURE_PATH, TEXTURE_ENUM_NAME, TEXTURE_DESC_NAME, TEXTURE_EXT)
	gen_desc(out_file, FONT_PATH,    FONT_ENUM_NAME,    FONT_DESC_NAME,    FONT_EXT)
	gen_desc(out_file, SOUND_PATH,   SOUND_ENUM_NAME,   SOUND_DESC_NAME,   SOUND_EXT)
	gen_desc(out_file, MUSIC_PATH,   MUSIC_ENUM_NAME,   MUSIC_DESC_NAME,   MUSIC_EXT)
}

gen_enum :: proc(out_file: os.Handle, path, enum_name, expected_ext: string)
{
	dir, dir_err := os.open(path)
	if dir_err != os.ERROR_NONE
	{
		fmt.printf("Couldn't open directory(%d): '%s'\n", dir_err, path)
		return
	}
	defer os.close(dir)

	file_infos, file_infos_err := os.read_dir(dir, 0)
	if file_infos_err != os.ERROR_NONE
	{
		fmt.printf("Couldn't read directory(%d): '%s'\n", file_infos_err, path)
		return
	}
	defer os.file_info_slice_delete(file_infos)

	fmt.fprintf(out_file, "%s :: enum\n", enum_name)
	fmt.fprint(out_file, "{\n")
	fmt.fprint(out_file, "\tNONE,\n")

	for &file_info in file_infos
	{
		ext := filepath.ext(file_info.name)
		if ext == expected_ext
		{
			name_no_ext := filepath.stem(file_info.name)
			fmt.fprintf(out_file, "\t%s,\n", strings.to_upper(name_no_ext))
		}
	}

	fmt.fprint(out_file, "}\n\n")
}

gen_desc :: proc(out_file: os.Handle, path, enum_name, desc_name, expected_ext: string)
{
	dir, dir_err := os.open(path)
	if dir_err != os.ERROR_NONE
	{
		fmt.printf("Couldn't open directory(%d): '%s'\n", dir_err, path)
		return
	}
	defer os.close(dir)

	file_infos, file_infos_err := os.read_dir(dir, 0)
	if file_infos_err != os.ERROR_NONE
	{
		fmt.printf("Couldn't read directory(%d): '%s'\n", file_infos_err, path)
		return
	}
	defer os.file_info_slice_delete(file_infos)

	fmt.fprint(out_file, "@(private)\n")
	fmt.fprintf(out_file, "%s: [%s]Asset_Desc = {{\n", desc_name, enum_name)
	fmt.fprint(out_file, "\t.NONE = {},\n")

	for &file_info in file_infos
	{
		ext := filepath.ext(file_info.name)
		if ext == expected_ext
		{
			name_no_ext := filepath.stem(file_info.name)
			rel_path := fmt.tprintf("%s/%s", path, file_info.name)
			fmt.fprintf(
				out_file,
				"\t.%[1]s = {{ path = \"%[2]s\", data = #load(\"%[2]s\") when EMBED_ASSETS else nil }},\n",
				strings.to_upper(name_no_ext),
				rel_path)
		}
	}

	fmt.fprint(out_file, "}\n\n")
}
