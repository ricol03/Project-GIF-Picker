/****
 * Files.vala - contains the logic for file indexing, read/write and management
 * ricol03, 2026
 ****/

public class Files {
	private GLib.DateTime datetime = new GLib.DateTime.now_local();

	private static string configDir = Environment.get_user_config_dir();
	private static string directory = "gifpicker";
	private static string logs = "logs";
	private static string settingsname = "settings.conf";
	private static string tagsname = "tags.conf";
	private static string logsname;
	private File folder;
	//private File gifFolder;

	private Gifs gifs;

	private string tagsfile = Path.build_filename(configDir, directory, tagsname);
	private string settingsfile = Path.build_filename(configDir, directory, settingsname);

	private FileMonitor monitor;

	public Files() {
		logsname = datetime.to_string() + ".log";
	}

	public void checkFolderChanges(File folder, Window window) {
		if (gifs == null)
			gifs = new Gifs(this, window.getConvertedName());

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
			writeToLog("Could not monitor folder: " + e.message);
		}
	}

	private async void addNewGif(File file, Window window) {

		if (!(yield waitForGif(file))) {
			writeToLog("GIF is not ready or invalid: " + file.get_path());
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
						new Gdk.PixbufAnimation.from_file(file.get_path());
						return true;
					} catch (Error e) {
						writeToLog("File " + file.get_basename() + " not yet decodable");
					}
				}

			} catch (Error e) {
				writeToLog("File " + file.get_basename() + " not yet available");
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
		string logDirPath = Path.build_filename(configDir, directory, logs);

		File dir = File.new_for_path(logDirPath);

		if (!dir.query_exists()) {
			try {
				dir.make_directory_with_parents();
				writeToLog("created directory -> " + dirPath + "\n");
			} catch (Error e) {
				writeToLog(new datetime.now_local().to_string() + " " + e.message);
			}
		} else
			writeToLog("directory already exists -> " + dirPath + "\n");
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

	public File checkLogFile() {
		string path = Path.build_filename(configDir, directory, logs, logsname);

		File file = File.new_for_path(path);
		return file;
	}

	/*public void createFile(string filePath) {
		File file = checkFile(string fileName)
		try {
			FileUtils.set_contents(filePath, "");
			writeToLog("created file named " + filePath + "\n");
		} catch (Error e) {
			writeToLog("Error creating file: " + e.message);
		}
	}*/

	public void createSettingsFile() {
		File file = checkSettingsFile();
		if (!file.query_exists()) {
			try {
				FileUtils.set_contents(file.get_path(), "");
				writeToLog("created settings file\n");
			} catch (Error e) {
				writeToLog("Error creating settings file: " + e.message + "\n");
			}
		} else
			writeToLog("settings file already exists\n");
	}

	public void createFile(string fileName) {
		File file = checkFile(fileName);
		if (!file.query_exists()) {
			try {
				FileUtils.set_contents(file.get_path(), "");
				writeToLog("created " + fileName + "\n");
			} catch (Error e) {
				writeToLog("Error creating " + fileName + ": " + e.message + "\n");
			}
		} else
			writeToLog("" + fileName + " already exists\n");
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
			writeToLog("" + e.message + "\n");
		}
	}

	public bool saveTagsFile(string text) {
		File file = checkFile("tags.conf");
		string filecontent = "";

		try {
			if (file.query_exists())
				FileUtils.get_contents(file.get_path(), out filecontent);

			if (filecontent != text) {
				FileUtils.set_contents(file.get_path(), text);
				return true;
			}
		} catch (Error e) {
			writeToLog("" + e.message + "\n");
		}

		return false;
	}

	public async string[] createFileIndex(string folderPath) {

		File file = File.new_for_path(folderPath);
		string[] filePaths = null;

		try {
			int num = 0;
			var e = yield file.enumerate_children_async(FileAttribute.STANDARD_NAME, 0, Priority.DEFAULT);
			while (true) {
		        var files = yield e.next_files_async (10, Priority.DEFAULT);

		        if (files == null || files.length() == 0)
		            break;

		        foreach (var info in files) {
					if (info.get_name().contains(".gif")) {
						num++;
		           		filePaths += folderPath + "/" + info.get_name();

		            }
				}
		    }

			writeToLog("GIFs added to index -> " + num.to_string() + " item(s)\n");


        	yield e.close_async();
		} catch (Error e) {
			writeToLog("" + e.message + "\n");
		}

		return filePaths;
	}

	public void writeToLog(string content) {
		File file = checkLogFile();
		FileOutputStream stream;

		try {
			if (file.query_exists(null))
				stream = file.append_to(FileCreateFlags.NONE, null);
			else
				stream = file.create(FileCreateFlags.NONE, null);

			var data = new DataOutputStream(stream);
			data.put_string(new datetime.now_local().to_string() + " : " + content);
			data.close();
		} catch (Error e) {
			warning(e.message);
		}	
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
		try {
			var file = File.new_for_path (path);
			file.create(FileCreateFlags.NONE);
		} catch (Error e) {
			writeToLog(e.message);
		}

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
						writeToLog("Setting retrieved: " + key + " -> " + line.substring((key + "=").length) + "\n");
						return line.substring((key + "=").length);
					}
				}
			} catch (Error e) {
				writeToLog("" + e.message + "\n");
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
			writeToLog("" + e.message + "\n");
		}

		return current;
	}

	public File getFolder() {
		return folder;
	}

	public void setFolder(File newFolder) {
		folder = newFolder;
	}
}