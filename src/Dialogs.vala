/****
 * Dialogs.vala - contains the menu dialogs logic
 * ricol03, 2026
 ****/

public class Dialogs {
	private Files files;

	public Dialogs(Files files) {
		this.files = files;
	}
    
    public async File openFolderDialog(Gtk.ApplicationWindow mainwindow) {
    	var dialog = new Gtk.FileDialog();
		dialog.title = "Open Folder";
		File file = null;

		try {
			file = yield dialog.select_folder(mainwindow, null);
			files.writeToLog("Folder selected -> " + file.get_path() + "\n");
			return file;
		} catch (Error e) {
			files.writeToLog(e.message + "\n");
		}
	
		return file;
    }
}