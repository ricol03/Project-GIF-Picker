/****
 * Edit.vala - contains the edit window logic
 * ricol03, 2026
 ****/

public class Edit {

	private Gtk.ApplicationWindow mainwindow;

    public Edit(Gtk.Application app, Window window, 
        string filepath, string filename, string datetime) {

        Gtk.Box box = new Gtk.Box(Gtk.Orientation.VERTICAL, 2) {
			margin_top = 20,
			margin_bottom = 20,
			margin_start = 20,
			margin_end = 20
		};

        var filenameentry = new Gtk.Entry();
        filenameentry.set_placeholder_text(filename);
        filenameentry.set_sensitive(false);

        box.append(makeRow("Filename", filenameentry));

        var friendlynameentry = new Gtk.Entry();
        friendlynameentry.set_placeholder_text("e.g. Nagisa smile");

        box.append(makeRow("Display name", friendlynameentry));

        var tagsentry = new Gtk.Entry();
        tagsentry.set_placeholder_text("e.g. Anime, Cute");

        box.append(makeRow("Tags", tagsentry));

        var datetimeentry = new Gtk.Entry();
        
        DateTime? date = new DateTime.from_iso8601 (datetime, null);

        datetimeentry.set_placeholder_text(date.format("%Y-%m-%d %H:%M:%S"));

        if (date == null) {
            datetimeentry.set_placeholder_text("(no date and time available)");
        }
       
        datetimeentry.set_sensitive(false);

        box.append(makeRow("Date and time", datetimeentry));

        string[] options = {"Complete name", "Complete name w/o extension"};

        var closeswitch = new Gtk.DropDown.from_strings(options);

        box.append(makeRow("Tags", closeswitch));

        string windowtitle = "Properties of " + filename;

        mainwindow = new Gtk.ApplicationWindow(app) {
            child = box,
			default_height = 500,
			default_width = 400,
			title = windowtitle
		};
        mainwindow.set_resizable(false);

        mainwindow.present();
    }

    private Gtk.Widget makeRow(string title, Gtk.Widget control) {
		var row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
		row.set_hexpand(true);

		var label = new Gtk.Label(title);
		label.set_xalign(0);
		label.width_request = 125;

        control.set_hexpand(true);

		row.append(label);
		row.append(control);

		return row;
	}
}