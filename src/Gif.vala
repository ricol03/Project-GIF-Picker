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
	private GLib.DateTime date;

	public Gif() {}

	public Json.Node saveJson() {
		var builder = new Json.Builder();

		GLib.File file = File.new_for_path(fileName);

        try {
            FileInfo info = file.query_info(
                "time::modified",
                FileQueryInfoFlags.NONE
            );

			date = info.get_modification_date_time();

		} catch (Error e) {
            print("Error: %s\n", e.message);
        }

		builder.begin_object();

		builder.set_member_name("filePath");
		builder.add_string_value(fileName);

		builder.set_member_name("fileName");
		builder.add_string_value(fileName);

		builder.set_member_name("displayName");
		builder.add_string_value(displayName);

		builder.set_member_name("isFavorite");
		builder.add_boolean_value(isFavorite);

		builder.set_member_name("dateTime");
		builder.add_string_value(date.to_string());

		builder.end_object();

		return builder.get_root();
	}

	public static Gif loadJson(Json.Object obj) {
		var gif = new Gif();

		if (obj.has_member("fileName"))
		    gif.fileName = obj.get_string_member("fileName");

		if (obj.has_member("displayName"))
		    gif.displayName = obj.get_string_member("displayName");

		if (obj.has_member("isFavorite"))
		    gif.isFavorite = obj.get_boolean_member("isFavorite");

		if (obj.has_member("dateTime")) {

		    string date = obj.get_string_member("dateTime");

			if (date != null) {

				/*string[] parts = date.split(" ");

				string[] d = parts[0].split("-");
				string[] t = parts[1].split(":");

				int year   = int.parse(d[0]);
				int month  = int.parse(d[1]);
				int day    = int.parse(d[2]);
				int hour   = int.parse(t[0]);
				int minute = int.parse(t[1]);
				int second = int.parse(t[2]);

				DateTime dt = new DateTime.local(
					year, month, day,
					hour, minute, second
				);*/
				
				gif.dateTime = date;
			} else {
				gif.dateTime = null;
			}
		}

		return gif;
	}

	// public string getFileName() {
	// 	return fileName;
	// }

	// public void setFileName(string newFileName) {
	// 	fileName = newFileName;
	// }

	// public void setDisplayName(string newDisplayName) {
	// 	displayName = newDisplayName;
	// }

}