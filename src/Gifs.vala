/****
 * Gifs.vala - contains the logic for gif showing
 * ricol03, 2026
 ****/

public class Gifs {
	private Files files = new Files();
	private GLib.DateTime datetime = new GLib.DateTime.now_local();

	private string configDir = Environment.get_user_config_dir();
	private string directory = "gifpicker";
	private string filename = "index";
	private string filePath;

	public Gifs(string? dirName) {
		createDirs(dirName);
	}

	public Gifs.null() {}

	public string createDirs(string name) {
		string safeName = Path.get_basename(name);

		filePath = Path.build_filename(
		    configDir,
		    directory,
		    safeName + "-" + filename + ".json"
		);

		return filePath;
	}

	public void saveModel(ListModel model) {
		Gif[] gifList = new Gif[model.get_n_items()];

		for (var i = 0; i < model.get_n_items(); i++) {
			gifList[i] = (Gif) model.get_item(i);
		}

		saveGifs(gifList);
	}

	
	public void saveGifs(Gif[] gifs) {
		var builder = new Json.Builder();
		builder.begin_array();

		foreach (var gif in gifs) {
			if (gif.fileName == null || gif.fileName == "") {
				files.writeToLog("Skipping GIF: filename is null or empty\n");
				continue;
			}

			files.writeToLog("Saving GIF: " + gif.fileName + "\n");
			builder.add_value(gif.saveJson());
		}

		builder.end_array();

		var generator = new Json.Generator();
		generator.set_root(builder.get_root());
		generator.pretty = true;

		try {
			generator.to_file(filePath);
			files.writeToLog("GIF JSON saved successfully\n");
		} catch (Error e) {
			files.writeToLog(
				"Failed to write JSON file: " + e.message + "\n"
			);
		}
	}


	public Gif[] loadGifs() {
		files.writeToLog(new datetime.now_local().to_string() + " : loading gifs from file\n");
		var parser = new Json.Parser();

		try {
			parser.load_from_file(filePath);
		} catch (Error e) {
			files.writeToLog(new datetime.now_local().to_string() + " : Failed to parse JSON file -> " + e.message + "\n");
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
		try {
			var animation = new Gdk.PixbufAnimation.from_file(filePath);
			var iter = animation.get_iter(null);
			var pixbuf = iter.get_pixbuf();

			if (pixbuf == null) {
				warning("Could not decode GIF: %s", filePath);
				return 0;
			}

			var texture = Gdk.Texture.for_pixbuf(pixbuf);
			picture.set_paintable(texture);

			return 1;

		} catch (Error e) {
			warning("Failed to load GIF '%s': %s", filePath, e.message);
			return 0;
		}
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

	public string getFilePath() {
		return filePath;
	}
}