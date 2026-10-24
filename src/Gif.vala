/****
 * Gif.vala - contains the logic for gif showing
 * ricol03, 2026
 ****/

public class Gif : Object {
	public string filePath { get; set; }
	public string fileName { get; set; }
	public string displayName { get; set; }
	public bool isFavorite { get; set; default = false; }
	public string dateTime { get; set; }
	public string[] tags { get; set; }
	private Files files = new Files();

	public Gif() {}

	public Gif.new(string newFilePath, string newFileName, string? newDisplayName, 
			bool? newIsFavorite, string newDateTime, string[]? newTags) {
				
		filePath = newFilePath;
		fileName = newFileName;
		displayName = newDisplayName;
		isFavorite = newIsFavorite;
		dateTime = newDateTime;
		tags = newTags;
	}

	public Json.Node saveJson() {
		var builder = new Json.Builder();

		builder.begin_object();

		builder.set_member_name("filePath");
		builder.add_string_value(filePath);

		builder.set_member_name("fileName");
		builder.add_string_value(fileName);

		builder.set_member_name("displayName");
		builder.add_string_value(displayName);

		builder.set_member_name("isFavorite");
		builder.add_boolean_value(isFavorite);

		builder.set_member_name("dateTime");
		builder.add_string_value(getDate(filePath));

		builder.set_member_name("tags");
		builder.begin_array();

		foreach (string tag in tags) {
			builder.add_string_value (tag);
		}

		builder.end_array();
		builder.end_object();

		return builder.get_root();
	}

	public static Gif loadJson(Json.Object obj) {
		var gif = new Gif();

		if (obj.has_member("filePath"))
		    gif.filePath = obj.get_string_member("filePath");

		if (obj.has_member("fileName"))
		    gif.fileName = obj.get_string_member("fileName");

		if (obj.has_member("displayName"))
		    gif.displayName = obj.get_string_member("displayName");

		if (obj.has_member("isFavorite"))
		    gif.isFavorite = obj.get_boolean_member("isFavorite");

		warning(gif._fileName + ": valor - " + gif._isFavorite.to_string());

		if (obj.has_member("dateTime")) {
		    string date = obj.get_string_member("dateTime");

			if (date != null)
				gif.dateTime = date;
			else
				gif.dateTime = null;
		}

		if (obj.has_member("tags")) {
		    Json.Array tags = obj.get_member("tags").get_array();

			string[] result = {};

			for (uint i = 0; i < tags.get_length (); i++) {
				result += tags.get_string_element (i);
			}

			gif.tags = result;
		}


		return gif;
	}

	public void updateData(string[] newtags, string gifname, string filePath) {
		try {
			Json.Object? targetObject = null;

			// Read the existing JSON file
			var parser = new Json.Parser();
			parser.load_from_file(filePath);

			var node = parser.get_root();
			var files = node.get_array();

			// Find the object matching the filename
			for (uint i = 0; i < files.get_length(); i++) {
				var item = files.get_object_element(i);

				if (item.has_member("fileName") &&
					item.get_string_member("fileName") == gifname) {
					targetObject = item;
					break;
				}
			}

			if (targetObject != null) {
				Json.Array tags;

				if (targetObject.has_member("tags") &&
					targetObject.get_member("tags").get_node_type() == Json.NodeType.ARRAY) {
					tags = targetObject.get_array_member("tags");
				} else {
					tags = new Json.Array();
					targetObject.set_array_member("tags", tags);
				}

				// Overwrites the current tags with new ones
				var newTags = new Json.Array();

				foreach (string tag in newtags) {
					newTags.add_string_element(tag);
				}

				targetObject.set_array_member("tags", newTags);

				// Write the updated JSON array back to the file
				var generator = new Json.Generator();
				generator.set_root(node);
				generator.pretty = true;
				generator.to_file(filePath);

			} else {
				print("File not found in JSON: %s\n", gifname);
			}

		} catch (Error e) {
			print("Failed to update JSON: %s\n", e.message);
		}
	}

	public string getDate(string filePath) {
		GLib.File file = File.new_for_path(filePath);
		GLib.DateTime date = null;

        try {
            FileInfo info = file.query_info(
                "time::modified",
                FileQueryInfoFlags.NONE
            );

			date = info.get_modification_date_time();

		} catch (Error e) {
            print("Error: %s\n", e.message);
        }

		return date.to_string();
	}

	public string getFileName() {
		return fileName;
	}

	// public void setFileName(string newFileName) {
	// 	fileName = newFileName;
	// }

	// public void setDisplayName(string newDisplayName) {
	// 	displayName = newDisplayName;
	// }

}