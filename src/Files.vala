/****
 * Files.vala - contains the logic for file indexing, read/write and management
 * ricol03, 2026
 ****/

public class Files {
	private string configDir = Environment.get_user_config_dir();
	private string directory = "io.ricol03.gifpicker";
	private string filename = "settings.conf";

	public Files() {}

	public int getFileLines() {
		string? line = null;
		int current = 1;

		try {
			var file = File.new_for_path(Path.build_filename(configDir, directory, filename));
			var dis = new DataInputStream(file.read());

			while ((line = dis.read_line(null)) != null)
				current++;

		} catch (Error e) {
			warning(e.message);
		}
		warning(current.to_string());
		return current;
	}

	public void setRevealerStatus(string text) {
		if (getFileLines() >= 2) {
			string content;
			FileUtils.get_contents(Path.build_filename(configDir, directory, filename), out content);

			string[] lines = content.split("\n");

			int target = 1;

			if (target < lines.length) {
				lines[target] = text;
			}

			string new_content = string.joinv("\n", lines);

			FileUtils.set_contents(Path.build_filename(configDir, directory, filename), new_content);
		} else {
			try {
				var file = File.new_for_path(Path.build_filename(configDir, directory, filename));
				var stream = file.append_to(FileCreateFlags.NONE);

				stream.write(text.data);
				stream.close();
			} catch (Error e) {
				warning(e.message.to_string());
			}
		}
	}

	public string getRevealerStatus() {
		string? line = null;
		try {
			var file = File.new_for_path(Path.build_filename(configDir, directory, filename));
			var dis = new DataInputStream(file.read());

			int target_line = 2;
			int current = 1;

			while ((line = dis.read_line(null)) != null) {
				if (current == target_line)
				    break;

				current++;
			}
		} catch (Error e) {
			warning(e.message);
		}

		return line;
	}

	public File getFile(string path) {
		return File.new_for_path(path);
	}

	public void createSettingsDirectory() {
		string dirPath = Path.build_filename(configDir, directory);

		File dir = File.new_for_path(dirPath);

		if (!dir.query_exists()) {
			try {
				dir.make_directory_with_parents();
			} catch (Error e) {
				warning(e.message);
			}
		}
	}

	public File checkSettingsFile() {

		string settingsPath = Path.build_filename(configDir, directory, filename);

		File file = File.new_for_path(settingsPath);
		return file;
	}

	public void createSettingsFile() {
		File file = checkSettingsFile();

		if (!file.query_exists()) {
			FileUtils.set_contents(file.get_path(), null);
		}
	}

	public void saveSettingsFile(string text) {
		File file = checkSettingsFile();
		FileOutputStream newfile = null;

		if (!file.query_exists(null)) {
			newfile = file.replace(null, true, FileCreateFlags.PRIVATE, null);
		} else {
			newfile = file.create(FileCreateFlags.PRIVATE, null);
		}

		FileUtils.set_contents(file.get_path(), text);

		newfile.write(text.data);
		newfile.close();
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

		        foreach (var info in files)
		            filePaths += info.get_name();
		    }
        	yield e.close_async();
		} catch (Error e) {
			warning(e.message);
		}

		return filePaths;
	}

	public signal void index_ready(string[] paths);

	public void getIndex(string folderPath) {
		createFileIndex.begin(folderPath, (obj, res) => {
		    try {
		        var paths = createFileIndex.end(res);
		        index_ready(paths);
		    } catch (Error e) {
		        warning(e.message);
		    }
		});
	}
}