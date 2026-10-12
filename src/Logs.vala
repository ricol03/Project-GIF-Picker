/****
 * Gif.vala - contains the logic for log writing
 * ricol03, 2026
 ****/

public class Logs {
	private Files files;
	private string filename = "gifpicker.log";

	public Logs() {}

	public File checkLogFile() {
		File file = files.checkFile(filename);
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