/****
 * Gifs.vala - contains the logic for gif showing
 * ricol03, 2026
 ****/

public class Gifs {
	private Logs logs = new Logs();
	private GLib.DateTime datetime = new GLib.DateTime.now_local();

	private string configDir = Environment.get_user_config_dir();
	private string directory = "io.ricol03.gifpicker";
	private string filename = "index";
	private string filePath;

	public Gifs(string dirName) {
		createDirs(dirName);
	}

	public string createDirs(string name) {
		string safeName = Path.get_basename(name);

		filePath = Path.build_filename(
		    configDir,
		    directory,
		    safeName + "-" + filename + ".json"
		);

		return filePath;
	}

	public void saveGifs(Gif[] gifs) {
		var existingGifs = new Gif[0];

		// Check if the file exists and load existing data
		if (File.new_for_path(filePath).query_exists()) {
		    try {
		        existingGifs = loadGifs();
		    } catch (Error e) {
		        logs.writeToLog(new datetime.now_local().to_string() + " : Failed to load existing GIFs -> " + e.message + "\n");
		    }
		}

		// Merge existing data with new data
		var map = new HashTable<string, Gif>(str_hash, str_equal);
		foreach (var gif in existingGifs) {
		    if (gif.fileName != null)
		        map.set(gif.fileName, gif);
		}

		foreach (var gif in gifs) {
		    if (gif.fileName != null)
		        map.set(gif.fileName, gif); // Overwrite or add new GIFs
		}

		// Save merged data
		var builder = new Json.Builder();
		builder.begin_array();

		foreach (var gif in map.get_values()) {
		    builder.add_value(gif.saveJson());
		}

		builder.end_array();

		var generator = new Json.Generator();
		generator.set_root(builder.get_root());

		try {
			generator.to_file(filePath);
		} catch (Error e) {
			logs.writeToLog(" : Failed to write JSON file -> " + e.message + "\n");
		}
	}

	public Gif[] loadGifs() {
		logs.writeToLog(new datetime.now_local().to_string() + " : loading gifs from file\n");
		var parser = new Json.Parser();

		try {
			parser.load_from_file(filePath);
		} catch (Error e) {
			logs.writeToLog(" : Failed to parse JSON file -> " + e.message + "\n");
		}

		warning("nome do diretório: " + filePath);

		try {
			parser.load_from_file(filePath);
		} catch (Error e) {
			logs.writeToLog(new datetime.now_local().to_string() + " : Failed to parse JSON file -> " + e.message + "\n");
		}

		var root = parser.get_root();
		var array = root.get_array();

		var gifs = new Gif[array.get_length()];

		for (uint i = 0; i < array.get_length(); i++) {
		    var obj = array.get_object_element(i);
		    gifs[i] = Gif.loadJson(obj);
		}

		return gifs;
	}

	public uint makeGifsSmall(Gtk.Picture picture, string filePath) {
		Gdk.PixbufAnimation animation = null;
		animation = new Gdk.PixbufAnimation.from_file(filePath);
		//warning(filePath);
		var iter = animation.get_iter(null);
		var texture = Gdk.Texture.for_pixbuf(iter.get_pixbuf());
		picture.set_paintable(texture);

		return 1;
	}

	public void startGifAnimation(
		Gtk.Picture picture,
		GifState state
	) {
		// Already playing
		if (state.timeout_id != 0)
		    return;

		if (state.filepath == null) {
		    warning("vai mas é trabalhar, ó");
		    return;
		}

		try {
		    state.animation =
		        new Gdk.PixbufAnimation.from_file(state.filepath);

		    state.iter =
		        state.animation.get_iter(null);

		} catch (Error e) {
		    warning("Could not load gif: %s", e.message);
		    return;
		}

		// Show first frame immediately
		var texture =
		    Gdk.Texture.for_pixbuf(state.iter.get_pixbuf());

		picture.set_paintable(texture);

		scheduleNextFrame(picture, state);
	}

	private void scheduleNextFrame(
		Gtk.Picture picture,
		GifState state
	) 
  {
		if (state.iter == null)
		    return;

		state.timeout_id = Timeout.add(
		    state.iter.get_delay_time(),
		    () => {
		        state.timeout_id = 0;

		        if (state.iter == null)
		            return false;

		        state.iter.advance(null);

		        var texture =
		            Gdk.Texture.for_pixbuf(state.iter.get_pixbuf());

		        picture.set_paintable(texture);

		        scheduleNextFrame(picture, state);

		        return false;
		    }
		);
	}

	public void stopGifAnimation(
		Gtk.Picture picture,
		GifState state
	) 
	{
		if (state.timeout_id != 0) {
			Source.remove(state.timeout_id);
			state.timeout_id = 0;
		}

		state.iter = null;
    	state.animation = null;
	}
}