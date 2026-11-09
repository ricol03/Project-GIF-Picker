/****
 * Settings.vala - contains the settings window
 * ricol03, 2026
 ****/

public class Settings {
	private GLib.DateTime datetime = new GLib.DateTime.now_local();

	private Files files = new Files();
	private Dialogs dialogs = new Dialogs();
	private Gtk.ApplicationWindow mainwindow;
	private string windowtitle = "Settings";
	private bool clickedbutton = false;

	private Gtk.Button pathbutton = new Gtk.Button.from_icon_name("folder-open-symbolic");
	private Gtk.Entry pathentry = new Gtk.Entry();
	private Gtk.DropDown closeswitch;

	private Gtk.Button editbutton;
	private Gtk.Label tagsinfo;

	public Settings(Gtk.Application app, Window window) {
		files.writeToLog(new datetime.now_local().to_string() + " : opened settings\n");

		Gtk.Box topbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 10) {
			margin_top = 15,
			margin_bottom = 15,
			margin_start = 15,
			margin_end = 15
		};

		Gtk.Box box = new Gtk.Box(Gtk.Orientation.VERTICAL, 10) {
			margin_top = 15,
			margin_bottom = 15,
			margin_start = 15,
			margin_end = 15
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

		Gtk.Button addbutton;

		#if WINDOWS
			var addicon = new Gtk.Image.from_resource(
				"/io/ricol03/gifpicker/icons/icons/hicolor/scalable/actions/win/Gnome-list-add.svg"
			);

			addbutton = new Gtk.Button();
			addbutton.set_child(addicon);
		#else
			addbutton = new Gtk.Button.from_icon_name("folder-open-symbolic");
		#endif
		addbutton.add_css_class("linked");
		addbutton.set_tooltip_markup("Add new tag");

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
			tagsbox.append(addTag(tagsbox, null));

			editbutton.clicked();
		});

		var scrolled = new Gtk.ScrolledWindow();
		scrolled.set_child(tagsframe);
		scrolled.set_max_content_height(300);
		scrolled.set_propagate_natural_height(true);
		scrolled.set_policy (
			Gtk.PolicyType.NEVER,
			Gtk.PolicyType.AUTOMATIC
		);

		createTagsSection(window, tagsframe, tagsbox);

		/*var shortcutsframe = new Gtk.Frame("Shortcuts");
		var shortcutsbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 12) {
			margin_top = 12,
			margin_bottom = 12,
			margin_start = 12,
			margin_end = 12
		};*/

		var buttonsbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 2);
		buttonsbox.set_halign(Gtk.Align.END);
		
		var cancelbutton = new Gtk.Button();
		cancelbutton.set_size_request(100, -1);
		cancelbutton.set_label("Cancel");

		cancelbutton.clicked.connect(() => {
			files.writeToLog(new datetime.now_local().to_string() + " : closed settings via close button\n");
			mainwindow.destroy();
		});

		var applybutton = new Gtk.Button();
		applybutton.set_size_request(100, -1);
		applybutton.set_label("Apply");

		applybutton.clicked.connect(() => {
			applyChanges(tagsbox);
		});

		var okbutton = new Gtk.Button();
		okbutton.set_size_request(100, -1);
		okbutton.set_label("OK");

		okbutton.clicked.connect(() => {
			applyChanges(tagsbox);

			if (clickedbutton) {
				window.refreshState();
				window.refreshChecks();
			}
				
			files.writeToLog(new datetime.now_local().to_string() + " : closed settings via titlebar close button\n");
			mainwindow.destroy();
		});

		buttonsbox.append(okbutton);
		buttonsbox.append(cancelbutton);
		buttonsbox.append(applybutton);

		buttonsbox.set_spacing(10);

		topbox.append(generaltitle);
		topbox.append(generalframe);
		//box.append(shortcutsframe);
		topbox.append(titlecombo);
		topbox.append(scrolled);

		box.append(topbox);

		var spacer = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		spacer.vexpand = true;
		box.append (spacer);

		box.append(buttonsbox);

		mainwindow = new Gtk.ApplicationWindow(app) {
			child = box,
			default_height = 500,
			default_width = 520,
			title = windowtitle
		};
		mainwindow.set_transient_for(window);
		mainwindow.set_resizable(false);
		mainwindow.set_modal(true);
		
		mainwindow.present();

		mainwindow.close_request.connect(() => {
			if (clickedbutton) {
				window.refreshState();
				window.refreshChecks();
			}
				
			files.writeToLog(new datetime.now_local().to_string() + " : closed settings via titlebar close button\n");
			mainwindow.destroy();
			return true;
		});
	}

	private void applyChanges(Gtk.Box tagsbox) {
		files.writeToLog(new datetime.now_local().to_string() + " : applied settings\n");

		files.saveSettingsFile("path", pathentry.get_text());
		files.saveSettingsFile("revealer", "false");
		files.saveSettingsFile("labels", closeswitch.get_selected().to_string());

		var content = "";

		for (
			var child = tagsbox.get_first_child();
			child != null;
		) {
			var next = child.get_next_sibling();

			if (!(child is Gtk.Label)) {
				var entry = (Gtk.Entry) child.get_first_child();

				if (entry.text.strip() != "") {
					content += entry.text;
					if (next != null)
						content += "\n";
				} else {
					tagsbox.remove(child);

					if (tagsbox.get_first_child() == null)
						addTagsSectionMessage(tagsbox);
				}
			}

			child = next;
		}

		files.saveTagsFile(content);

		clickedbutton = true;
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

		Gtk.Button pathbutton;

		#if WINDOWS
			var pathicon = new Gtk.Image.from_resource(
				"/io/ricol03/gifpicker/icons/icons/hicolor/scalable/actions/win/Gnome-document-open.svg"
			);

			pathbutton = new Gtk.Button();
			pathbutton.set_child(pathicon);
		#else
			pathbutton = new Gtk.Button.from_icon_name("folder-open-symbolic");
		#endif
		pathbutton.add_css_class("linked");
		pathbutton.set_tooltip_markup("Select path using File Explorer");

		File? newfile = null;
		pathbutton.clicked.connect(() => {
			dialogs.openFolderDialog.begin(window, (obj, res) => {
				try {
					newfile = dialogs.openFolderDialog.end(res);
					if (newfile != null) {
						pathentry.set_text(newfile.get_path());
						files.writeToLog(new datetime.now_local().to_string() + " : new path -> " + newfile.get_path() + "\n");
					}
				} catch (Error e) {
					files.writeToLog(new datetime.now_local().to_string() + " : (settings) " + e.message + "\n");
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

			if (num != null)
				closeswitch.set_selected(int.parse(num));
			else
				closeswitch.set_selected(int.parse("0"));
		}

		var closerow = makeRow("Label presentation", closeswitch);

		generalbox.append(pathentryrow);
		generalbox.append(closerow);

		generalframe.set_child(generalbox);
	}

	private void createTagsSection(Window window, Gtk.Frame tagsframe, Gtk.Box tagsbox) {

		File file = files.checkFile("tags.conf");

		string content;

		try {
			FileUtils.get_contents(file.get_path(), out content);

			if (content == "") {
				addTagsSectionMessage(tagsbox);
			} else {
				foreach (string line in content.split("\n")) {
					tagsbox.append(addTag(tagsbox, line));
				}
			}

		} catch (Error e) {
			files.writeToLog(new datetime.now_local().to_string() + " : " + e.message + "\n");
		}

		tagsframe.set_child(tagsbox);
	}

	private void addTagsSectionMessage(Gtk.Box tagsbox) {
		tagsinfo = new Gtk.Label("No tags available, click the \"+\" button to add one."); 
		tagsbox.append(tagsinfo);
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

	private Gtk.Widget addTag(Gtk.Box tagsbox, string? name) {

		string tempname = "";

		var row = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12);
		row.set_hexpand(true);

		Gtk.Entry tagname = new Gtk.Entry();
		tagname.set_placeholder_text("Tag name");
		tagname.set_sensitive(false);

		if (name != null && name != "") 
			tagname.set_text(name);

		Gtk.Button deletebutton;

		#if WINDOWS
			var deleteicon = new Gtk.Image.from_resource(
				"/io/ricol03/gifpicker/icons/icons/hicolor/scalable/actions/win/User-trash.svg"
			);

			deletebutton = new Gtk.Button();
			deletebutton.set_child(deleteicon);
		#else
			deletebutton = new Gtk.Button.from_icon_name("delete-symbolic");
		#endif
		deletebutton.set_data<string> ("action", "delete");
		deletebutton.add_css_class("linked");
		deletebutton.set_tooltip_markup("Delete tag");

		#if WINDOWS
			var editicon = new Gtk.Image.from_resource(
				"/io/ricol03/gifpicker/icons/icons/hicolor/scalable/actions/win/Gnome-edit.svg"
			);

			editbutton = new Gtk.Button();
			editbutton.set_child(editicon);
			
		#else
			editbutton = new Gtk.Button.from_icon_name("edit-symbolic");
		#endif
		editbutton.set_data<string> ("action", "edit");
		editbutton.add_css_class("linked");
		editbutton.set_tooltip_markup("Edit tag name");

		deletebutton.clicked.connect(() => {
			if (deletebutton.get_data<string> ("action") == "delete") {
				tagsbox.remove(row);

				if (tagsbox.get_first_child() == null) {
					tagsinfo = new Gtk.Label("No tags available, click the \"+\" button to add one."); 
					tagsbox.append(tagsinfo);
				}

			} else {
				editbutton.set_data<string> ("action", "edit");
				deletebutton.set_data<string> ("action", "delete");

				tagname.set_text(tempname);
				tagname.set_sensitive(false);
				editbutton.set_tooltip_markup("Edit tag name");
				deletebutton.set_tooltip_markup("Delete tag");


				#if WINDOWS
					deletebutton.set_child(deleteicon);
					editbutton.set_child(editicon);
				#else
					deletebutton.set_icon_name("delete-symbolic");
					editbutton.set_icon_name("edit-symbolic");
				#endif

			}
		});

		editbutton.clicked.connect(() => {
			if (editbutton.get_data<string> ("action") == "edit") {
				editbutton.set_data<string> ("action", "check");
				deletebutton.set_data<string> ("action", "cancel");

				editbutton.set_tooltip_markup("Confirm changes");
				deletebutton.set_tooltip_markup("Cancel changes");

				tempname = tagname.get_text();

				tagname.set_sensitive(true);
				tagname.grab_focus();

				#if WINDOWS
					var cancelicon = new Gtk.Image.from_resource(
						"/io/ricol03/gifpicker/icons/icons/hicolor/scalable/actions/win/Edit-delete.svg"
					);
					var checkmarkicon = new Gtk.Image.from_resource(
						"/io/ricol03/gifpicker/icons/icons/hicolor/scalable/actions/win/Dialog-apply.svg"
					);

					deletebutton.set_child(cancelicon);
					editbutton.set_child(checkmarkicon);
				#else
					deletebutton.set_icon_name("cancel-symbolic");
					editbutton.set_icon_name("checkmark-symbolic");
				#endif
			} else {
				editbutton.set_data<string> ("action", "edit");
				deletebutton.set_data<string> ("action", "delete");

				editbutton.set_tooltip_markup("Confirm changes");
				deletebutton.set_tooltip_markup("Cancel changes");

				tagname.set_sensitive(false);

				#if WINDOWS
					deleteicon = new Gtk.Image.from_resource(
						"/io/ricol03/gifpicker/icons/icons/hicolor/scalable/actions/win/User-trash.svg"
					);

					editicon = new Gtk.Image.from_resource(
						"/io/ricol03/gifpicker/icons/icons/hicolor/scalable/actions/win/Gnome-edit.svg"
					);

					deletebutton.set_child(deleteicon);
					editbutton.set_child(editicon);
				#else
					editbutton.set_tooltip_markup("Edit tag name");
					deletebutton.set_tooltip_markup("Delete tag");
					
					deletebutton.set_icon_name("delete-symbolic");
					editbutton.set_icon_name("edit-symbolic");
				#endif
			}
		});

		tagname.set_hexpand(true);

		row.append(tagname);
		row.append(editbutton);
		row.append(deletebutton);

		return row;
	}
}