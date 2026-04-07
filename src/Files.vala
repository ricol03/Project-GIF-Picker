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
						return line.substring((key + "=").length);
					}
				}
			} catch (Error e) {
				warning(e.message);
			}
		}

		return null;
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
		if (!file.query_exists())
			FileUtils.set_contents(file.get_path(), null);
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
			warning(e.message);
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
		            filePaths += folderPath + "/" + info.get_name();
				}
		    }
        	yield e.close_async();
		} catch (Error e) {
			warning(e.message);
		}

		return filePaths;
	}

	public async string[] getIndex(string folderPath) {
		string[] paths = yield createFileIndex(folderPath);
		return paths;
	}
}