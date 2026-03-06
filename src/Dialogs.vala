/****
 * Dialogs.vala - contains the menu dialogs logic
 * ricol03, 2026
 ****/

public class Dialogs {
	public Dialogs() {}
    
    public File openFolderDialog(Gtk.ApplicationWindow main_window) {
    	var dialog = new Gtk.FileDialog();
		dialog.title = "Open Folder";
		File file = null;

		dialog.select_folder(main_window, null, (obj, res) => {
			try {
				file = dialog.open.end(res);

			} catch (Error e) {
				warning("- %s".printf(e.message));
			}
		});
		
		return file;
    }
}