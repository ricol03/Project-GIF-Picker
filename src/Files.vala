/****
 * Files.vala - contains the logic for file indexing, read/write and management
 * ricol03, 2026
 ****/

public class Files {
	private GLib.DateTime datetime = new GLib.DateTime.now_local();

	private static string configDir = Environment.get_user_config_dir();
	private static string directory = "gifpicker";
	private static string settingsname = "settings.conf";
	private static string tagsname = "tags.conf";
	private static string logsname = "gifpicker.log";

	private Gifs gifs;

	private string tagsfile = Path.build_filename(configDir, directory, tagsname);
	private string settingsfile = Path.build_filename(configDir, directory, settingsname);

	private FileMonitor monitor;

	public Files() {}

	public void checkFolderChanges(File folder, Window window) {
		if (gifs == null)
			gifs = new Gifs(window.getConvertedName());

		try {
			monitor = folder.monitor_directory(
				FileMonitorFlags.NONE,
				null
			);

			monitor.changed.connect((file, other_file, event_type) => {
				switch (event_type) {
					case FileMonitorEvent.CREATED:
						addNewGif.begin(file, window);
						break;

					case FileMonitorEvent.DELETED:
						Gif gif = new Gif();

						Idle.add(() => {
							Gif check = null;

							for (var i = 0; i < window.model.get_n_items(); i++) {
								check = (Gif)window.model.get_item(i);

								if (file.get_basename() == check.getFileName()) {
									window.model.remove(i);
									break;
								}
							}

							window.checkNextButton((int)window.model.get_n_items());

							Gif[] newGifList = new Gif[window.model.get_n_items()];

							for (var i = 0; i < window.model.get_n_items(); i++)
								newGifList[i] = (Gif)window.model.get_item(i);
							
							gifs.saveModel(window.model);

							return Source.REMOVE;
						});
						break;

					case FileMonitorEvent.CHANGED:
						break;

					default:
						break;
				}
			});
		} catch (Error e) {
			warning("Could not monitor folder: %s", e.message);
		}
	}

	private async void addNewGif(File file, Window window) {

		if (!(yield waitForGif(file))) {
			warning("GIF is not ready or invalid: %s", file.get_path());
			return;
		}

		bool hasFile = false;

		Gif gif = new Gif();

		for (var i = 0; i < window.model.get_n_items(); i++) {

			Gif check = (Gif)window.model.get_item(i);

			if (file.get_basename() == check.getFileName()) {
				hasFile = true;
				break;
			}
		}

		if (!hasFile) {
			Idle.add(() => {
				var newGif = new Gif.new(file.get_path(), file.get_basename(), file.get_basename(), false, gif.getDate(file.get_path()), null);

				window.model.append(newGif);

				window.checkNextButton((int)window.model.get_n_items());

				Gif[] newGifList = new Gif[window.model.get_n_items()];

				for (var i = 0; i < window.model.get_n_items(); i++)
					newGifList[i] = (Gif)window.model.get_item(i);
				
				gifs.saveGifs(newGifList);

				return Source.REMOVE;
			});
		}

	}

	private async bool waitForGif(File file) {
		int64 previousSize = -1;
		int checks = 0;

		for (var i = 0; i < 50; i++) {
			warning("hallo " + i.to_string());
			try {
				var info = file.query_info(FileAttribute.STANDARD_SIZE, FileQueryInfoFlags.NONE);

				int64 size = info.get_size();

				if (size > 0 && size == previousSize)
					checks++;
				else
					checks = 0;

				previousSize = size;

				if (checks >= 3) {
					try {
						var animation = new Gdk.PixbufAnimation.from_file(file.get_path());
						return true;
					} catch (Error e) {
						warning("File " + file.get_basename() + " not yet decodable");
					}
				}

			} catch (Error e) {
				warning("File " + file.get_basename() + " not yet available");
			}

			yield waitForTimeout(100);
		}

		return false;
	}

	private async void waitForTimeout(uint milliseconds) {
		Timeout.add(milliseconds, () => {
			waitForTimeout.callback();
			return Source.REMOVE;
		});
		yield;
	}

	public void createThread(Window window, Gif[] newGifList) {
		new Thread<void*>("worker", () => {

			
			
			return null;
		});
	}


	public bool hasFileContent(string filePath) {
		try {
		    var file = File.new_for_path(filePath);

		    if (!file.query_exists())
		        return false;

		    var info = file.query_info("standard::size", 0);
		    return info.get_size() > 0;

		} catch (Error e) {
		    return false;
		}
	}

	public void createSettingsDirectory() {
		string dirPath = Path.build_filename(configDir, directory);

		File dir = File.new_for_path(dirPath);

		if (!dir.query_exists()) {
			try {
				dir.make_directory_with_parents();
				writeToLog(new datetime.now_local().to_string() + " : created directory -> " + dirPath + "\n");
			} catch (Error e) {
				writeToLog(new datetime.now_local().to_string()+ " " + e.message);
			}
		} else
			writeToLog(new datetime.now_local().to_string() + " : directory already exists -> " + dirPath + "\n");
	}

	public File checkSettingsFile() {
		File file = File.new_for_path(settingsfile);
		return file;
	}

	public File checkFile(string? fileName) {
		string path = Path.build_filename(configDir, directory, fileName);

		File file = File.new_for_path(path);
		return file;
	}

	/*public void createFile(string filePath) {
		File file = checkFile(string fileName)
		try {
			FileUtils.set_contents(filePath, "");
			writeToLog(new datetime.now_local().to_string() + " : created file named " + filePath + "\n");
		} catch (Error e) {
			writeToLog(new datetime.now_local().to_string() + " : Error creating file: " + e.message);
		}
	}*/

	public void createSettingsFile() {
		File file = checkSettingsFile();
		if (!file.query_exists()) {
			try {
				FileUtils.set_contents(file.get_path(), "");
				writeToLog(new datetime.now_local().to_string() + " : created settings file\n");
			} catch (Error e) {
				writeToLog(new datetime.now_local().to_string() + " : Error creating settings file: " + e.message + "\n");
			}
		} else
			writeToLog(new datetime.now_local().to_string() + " : settings file already exists\n");
	}

	public void createFile(string fileName) {
		File file = checkFile(fileName);
		if (!file.query_exists()) {
			try {
				FileUtils.set_contents(file.get_path(), "");
				writeToLog(new datetime.now_local().to_string() + " : created " + fileName + "\n");
			} catch (Error e) {
				writeToLog(new datetime.now_local().to_string() + " : Error creating " + fileName + ": " + e.message + "\n");
			}
		} else
			writeToLog(new datetime.now_local().to_string() + " : " + fileName + " already exists\n");
	}

	public void saveSettingsFile(string key, string text) {
		File file = checkSettingsFile();
		string content = "";
		bool found = false;

		try {
			if (file.query_exists())
				FileUtils.get_contents(file.get_path(), out content);

			string[] lines = content.split("\n");
			string newcontent = "";

			foreach (string line in lines) {
				string stripped = line.strip();

				if (stripped == "")
					continue;

				if (stripped.has_prefix(key + "=")) {
					newcontent += key + "=" + text + "\n";
					found = true;
				} else {
					newcontent += stripped + "\n";
				}
			}

			if (!found)
				newcontent += key + "=" + text + "\n";

			FileUtils.set_contents(file.get_path(), newcontent);
		} catch (Error e) {
			writeToLog(new datetime.now_local().to_string() + " : " + e.message + "\n");
		}
	}

	public void saveTagsFile(string text) {
		File file = checkFile("tags.conf");
		string content = "";

		try {
			if (file.query_exists())
				FileUtils.get_contents(file.get_path(), out content);

			FileUtils.set_contents(file.get_path(), text);
		} catch (Error e) {
			writeToLog(new datetime.now_local().to_string() + " : " + e.message + "\n");
		}
	}

	public async string[] createFileIndex(string folderPath) {

		File file = File.new_for_path(folderPath);
		string[] filePaths = null;

		try {
			var e = yield file.enumerate_children_async(FileAttribute.STANDARD_NAME, 0, Priority.DEFAULT);
			while (true) {
		        var files = yield e.next_files_async (10, Priority.DEFAULT);

		        if (files == null || files.length() == 0)
		            break;

		        foreach (var info in files) {
					if (info.get_name().contains(".gif")) {
		           		filePaths += folderPath + "/" + info.get_name();
						writeToLog(new datetime.now_local().to_string() + " : added to index -> " + info.get_name() + "\n");
		            }
				}
		    }
        	yield e.close_async();
		} catch (Error e) {
			writeToLog(new datetime.now_local().to_string() + " : " + e.message + "\n");
		}

		return filePaths;
	}

	
	public File checkLogFile() {
		File file = checkFile(logsname);
		return file;
	}

	public void writeToLog(string content) {
		File file = checkLogFile();
		FileOutputStream stream;

		if (file.query_exists(null)) {
			stream = file.append_to(FileCreateFlags.NONE, null);
		} else {
			stream = file.create(FileCreateFlags.NONE, null);
		}

		var data = new DataOutputStream(stream);
		data.put_string(content);
		data.close();
	}

	//getters / setters

	public string getTagsFilename() {
		return tagsfile;
	}

	public async string[] getIndex(string folderPath) {
		string[] paths = yield createFileIndex(folderPath);
		return paths;
	}

	public File getFile(string path) {
		return File.new_for_path(path);
	}

	public string? getSetting(string key) {
		File file = checkSettingsFile();
		if (file.query_exists()) {
			try {
				string content;
				FileUtils.get_contents(file.get_path(), out content);

				foreach (string line in content.split("\n")) {
					if (line.has_prefix(key + "=")) {
						writeToLog(new datetime.now_local().to_string() + " : setting retrieved: " + key + " - " + line.substring((key + "=").length) + "\n");
						return line.substring((key + "=").length);
					}
				}
			} catch (Error e) {
				writeToLog(new datetime.now_local().to_string() + " : " + e.message + "\n");
			}
		}

		return null;
	}

	public int getFileLines(string fileName) {
		string? line = null;
		int current = 1;

		try {
			var file = File.new_for_path(Path.build_filename(configDir, directory, fileName));
			var dis = new DataInputStream(file.read());

			while ((line = dis.read_line(null)) != null)
				current++;

		} catch (Error e) {
			writeToLog(new datetime.now_local().to_string() + " : " + e.message + "\n");
		}

		return current;
	}


}