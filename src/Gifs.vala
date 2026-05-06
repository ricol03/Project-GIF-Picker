/****
 * Gifs.vala - contains the logic for gif showing
 * ricol03, 2026
 ****/

public class Gifs {
	private Logs logs = new Logs();
	private GLib.DateTime datetime = new GLib.DateTime.now_local();

	private Files files = new Files();
	private string configDir = Environment.get_user_config_dir();
	private string directory = "io.ricol03.gifpicker";
	private string filename = "index";
	private string filePath;

	public Gifs(string dirName) {
		createDirs(dirName);
	}

	public string createDirs(string? dirName) {
		filePath = Path.build_filename(configDir, directory, dirName + "-" + filename + ".json");
		return filePath;
	}

	public void saveGifs(Gif[] gifs) {
		var builder = new Json.Builder();
		builder.begin_array();

		foreach (var gif in gifs) {
		    builder.add_value(gif.saveJson());
		}

		builder.end_array();

		var generator = new Json.Generator();
		generator.set_root(builder.get_root());

		generator.to_file(filePath);
	}

	public Gif[] loadGifs() {
		logs.writeToLog(new datetime.now_local().to_string() + " : loading gifs from file\n");
		var parser = new Json.Parser();
		if (!File.new_for_path(filePath).query_exists()) {
			files.createFile(filePath);
		}

		parser.load_from_file(filePath);

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
		var animation = new Gdk.PixbufAnimation.from_file(filePath);
		var iter = animation.get_iter(null);

		uint id = Timeout.add(iter.get_delay_time(), () => {
			if (iter.advance(null)) {
				var texture = Gdk.Texture.for_pixbuf(iter.get_pixbuf());
				picture.set_paintable(texture);
			}

			return true;
		});

		return id;
	}
}