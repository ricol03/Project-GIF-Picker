/****
 * Settings.vala - contains the settings window
 * ricol03, 2026
 ****/

public class Settings {
	private Logs logs = new Logs();
	private GLib.DateTime datetime = new GLib.DateTime.now_local();

	private Files files = new Files();
	private Dialogs dialogs = new Dialogs();
	private Gtk.ApplicationWindow mainwindow;
	private string windowtitle = "Settings";
	private bool clickedbutton = false;

	private Gtk.Button pathbutton = new Gtk.Button.from_icon_name("folder-open-symbolic");
	private Gtk.Entry pathentry = new Gtk.Entry();
	private Gtk.DropDown closeswitch;

	private Gtk.Label tagsinfo;

	public Settings(Gtk.Application app, Window window) {
		logs.writeToLog(new datetime.now_local().to_string() + " : opened settings\n");

		Gtk.Box box = new Gtk.Box(Gtk.Orientation.VERTICAL, 10) {
			margin_top = 24,
			margin_bottom = 24,
			margin_start = 24,
			margin_end = 24
		};

		var generaltitle = new Gtk.Label("General");
		generaltitle.add_css_class("settings-title");
		generaltitle.set_halign(Gtk.Align.START);
		var generalframe = new Gtk.Frame(null);
		var generalbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 12) {
			margin_top = 12,
			margin_bottom = 12,
			margin_start = 12,
			margin_end = 12
		};

		createGeneralSection(window, generalframe, generalbox);

		var tagstitle = new Gtk.Label("Tags");
		tagstitle.add_css_class("settings-title");
		tagstitle.set_halign(Gtk.Align.START);

		var addbutton = new Gtk.Button.from_icon_name("add-symbolic");
		addbutton.add_css_class("linked");

		var titlecombo = makeRowTitle(tagstitle, addbutton);
		var tagsframe = new Gtk.Frame(null);
		var tagsbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 12) {
			margin_top = 12,
			margin_bottom = 12,
			margin_start = 12,
			margin_end = 12
		};

		addbutton.clicked.connect(() => {
			tagsbox.remove(tagsinfo);
			tagsbox.append(addTag());
			
		});

		createTagsSection(window, tagsframe, tagsbox);

		var shortcutsframe = new Gtk.Frame("Shortcuts");
		var shortcutsbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 12) {
			margin_top = 12,
			margin_bottom = 12,
			margin_start = 12,
			margin_end = 12
		};

		var buttonsbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 2);
		buttonsbox.set_halign(Gtk.Align.END);
		var cancelbutton = new Gtk.Button();
		cancelbutton.set_label("Cancel");

		cancelbutton.clicked.connect(() => {
			logs.writeToLog(new datetime.now_local().to_string() + " : closed settings via close button\n");
			mainwindow.destroy();
		});

		var applybutton = new Gtk.Button();
		applybutton.set_label("Apply");

		applybutton.clicked.connect(() => {
			logs.writeToLog(new datetime.now_local().to_string() + " : applied settings\n");

			files.saveSettingsFile("path", pathentry.get_text());
			files.saveSettingsFile("revealer", "false");
			files.saveSettingsFile("labels", closeswitch.get_selected().to_string());
			clickedbutton = true;
		});

		buttonsbox.append(cancelbutton);
		buttonsbox.append(applybutton);

		box.append(generaltitle);
		box.append(generalframe);
		//box.append(shortcutsframe);
		box.append(titlecombo);
		box.append(tagsframe);
		box.append(buttonsbox);

		mainwindow = new Gtk.ApplicationWindow(app) {
			child = box,
			default_height = 240,
			default_width = 520,
			title = windowtitle
		};
		mainwindow.set_transient_for(null);
		mainwindow.set_resizable(false);
		
		mainwindow.present();

		mainwindow.close_request.connect(() => {
			if (clickedbutton)
				window.refreshState();
			
			logs.writeToLog(new datetime.now_local().to_string() + " : closed settings via titlebar close button\n");
			mainwindow.destroy();
			return true;
		});
	}

	private void createGeneralSection(Window window, Gtk.Frame generalframe, Gtk.Box generalbox) {
		var combobox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 2);

		string placeholder = "(No file selected)";
		string filename = null;
		File file = files.checkSettingsFile();
		if (file.query_exists())
			filename = files.getSetting("path");

		pathentry.set_placeholder_text(placeholder);
		pathentry.set_hexpand(true);
		if (filename != null)
			pathentry.set_text(filename);

		var pathbutton = new Gtk.Button.from_icon_name("folder-open-symbolic");
		pathbutton.add_css_class("linked");

		File? newfile = null;
		pathbutton.clicked.connect(() => {
			dialogs.openFolderDialog.begin(window, (obj, res) => {
				try {
					newfile = dialogs.openFolderDialog.end(res);
					if (newfile != null) {
						pathentry.set_text(newfile.get_path());
						logs.writeToLog(new datetime.now_local().to_string() + " : new path -> " + newfile.get_path() + "\n");
					}
				} catch (Error e) {
					logs.writeToLog(new datetime.now_local().to_string() + " : (settings) " + e.message + "\n");
				}
			});
		});

		combobox.append(pathentry);
		combobox.append(pathbutton);

		var pathentryrow = makeRow("Path for GIF library", combobox);

		string[] options = {"Complete name", "Complete name w/o extension"};

		closeswitch = new Gtk.DropDown.from_strings(options);

		if (file.query_exists()) {
			var num = files.getSetting("labels");
			closeswitch.set_selected(int.parse(num));
		}

		var closerow = makeRow("Label presentation", closeswitch);

		generalbox.append(pathentryrow);
		generalbox.append(closerow);

		generalframe.set_child(generalbox);
	}

	private void createTagsSection(Window window, Gtk.Frame tagsframe, Gtk.Box tagsbox) {

		File file = files.checkFile("tags.conf");
		int lines = files.getFileLines("tags.conf");

		string content;

		try {
			FileUtils.get_contents(file.get_path(), out content);

			if (content == "") {
				tagsinfo = new Gtk.Label("No tags available, click the \"+\" button to add one."); 
				tagsbox.append(tagsinfo);
			}

		} catch (Error e) {
			logs.writeToLog(new datetime.now_local().to_string() + " : " + e.message + "\n");
		}

		for (var i = 0; i < lines; i++) {
			if (i == 0) {
				int id = 0;
				foreach (string line in content.split("\n")) {
					warning("a " + id++.to_string());
				}
			}

		}


		tagsframe.set_child(tagsbox);

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

	private Gtk.Widget makeRowTitle(Gtk.Widget title, Gtk.Button button) {
		var row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
		row.set_hexpand(true);

		title.set_hexpand(true);

		row.append(title);
		row.append(button);

		return row;
	}

	private Gtk.Widget addTag() {
		var row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
		row.set_hexpand(true);

		Gtk.Entry tagname = new Gtk.Entry();
		var deletebutton = new Gtk.Button.from_icon_name("delete-symbolic");
		deletebutton.add_css_class("linked");

		deletebutton.clicked.connect(() => {
		});

		tagname.set_hexpand(true);

		row.append(tagname);
		row.append(deletebutton);

		return row;
	}
}