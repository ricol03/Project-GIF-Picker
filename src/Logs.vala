/****
 * Gif.vala - contains the logic for log writing
 * ricol03, 2026
 ****/

public class Logs {
	private string configDir = Environment.get_user_config_dir();
	private string directory = "io.ricol03.gifpicker";
	private string filename = "gifpicker.log";

	public Logs() {}

	public File checkLogFile() {
		string settingsPath = Path.build_filename(configDir, directory, filename);

		File file = File.new_for_path(settingsPath);
		return file;
	}

	public void writeToLog(string content) {
		File file = checkLogFile();

		//var file = File.new_for_path(path);
		FileOutputStream stream;

		if (file.query_exists(null))
			stream = file.append_to(FileCreateFlags.NONE, null);
		else
			stream = file.create(FileCreateFlags.NONE, null);

		var data = new DataOutputStream(stream);
		data.put_string(content);
		data.close();
	}

}