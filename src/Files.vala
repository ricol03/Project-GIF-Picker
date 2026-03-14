/****
 * Files.vala - contains the logic for file indexing and management
 * ricol03, 2026
 ****/

public class Files {

	public Files() {}
	
	public File getFile(string path) {
		return File.new_for_path(path);
	}

	public void createSettingsDirectory() {
		string configDir = Environment.get_user_config_dir();
		string dirPath = Path.build_filename(configDir, "io.ricol03.gifpicker");

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
		string configDir = Environment.get_user_config_dir();
		string settingsPath = Path.build_filename(configDir, "io.ricol03.gifpicker", "settings.conf");

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