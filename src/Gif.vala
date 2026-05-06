/****
 * Gif.vala - contains the logic for gif showing
 * ricol03, 2026
 ****/

public class Gif : Object {
	public string file_name { get; set; }
	public string display_name { get; set; }
	public bool is_favorite { get; set; default = false; }
	private GLib.DateTime dateTime = new GLib.DateTime.now_local();

	public Gif() {}

	public Json.Node saveJson() {
		var builder = new Json.Builder();

		builder.begin_object();

		builder.set_member_name("fileName");
		builder.add_string_value(file_name);

		builder.set_member_name("displayName");
		builder.add_string_value(display_name);

		builder.set_member_name("isFavorite");
		builder.add_boolean_value(is_favorite);

		builder.set_member_name("dateTime");
		builder.add_string_value(dateTime.to_string());

		builder.end_object();

		return builder.get_root();
	}

	public static Gif loadJson(Json.Object obj) {
		var gif = new Gif();

		if (obj.has_member("fileName"))
		    gif.file_name = obj.get_string_member("fileName");

		if (obj.has_member("displayName"))
		    gif.display_name = obj.get_string_member("displayName");

		if (obj.has_member("isFavorite"))
		    gif.is_favorite = obj.get_boolean_member("isFavorite");

		// if (obj.has_member("dateTime")) {
		//     gif.dateTime = obj.get_string_member("dateTime").date;
		// 	GLib.DateTime.
		// }

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