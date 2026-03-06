/****
 * Dialogs.vala - contains the menu dialogs logic
 * ricol03, 2026
 ****/

public class Dialogs {
	public Dialogs() {}
    
    public async File openFolderDialog(Gtk.ApplicationWindow main_window) {
    	var dialog = new Gtk.FileDialog();
		dialog.title = "Open Folder";
		File file = null;

		try {
			file = yield dialog.select_folder(main_window, null);
			return file;
		} catch (Error e) {
			warning("- %s".printf(e.message));
		}
	
		return file;
    }
}