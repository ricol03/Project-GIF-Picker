/****
 * Dialogs.vala - contains the menu dialogs logic
 * ricol03, 2026
 ****/

public class Dialogs {
	private Logs logs = new Logs();
	private GLib.DateTime datetime = new GLib.DateTime.now_local();

	public Dialogs() {}
    
    public async File openFolderDialog(Gtk.ApplicationWindow mainwindow) {
    	var dialog = new Gtk.FileDialog();
		dialog.title = "Open Folder";
		File file = null;

		try {
			file = yield dialog.select_folder(mainwindow, null);
			logs.writeToLog(new datetime.now_local().to_string() + " : folder selected -> " + file.get_path() + "\n");
			return file;
		} catch (Error e) {
			logs.writeToLog(new datetime.now_local().to_string() + " : " + e.message + "\n");
		}
	
		return file;
    }
}