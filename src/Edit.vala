/****
 * Edit.vala - contains the edit window logic
 * ricol03, 2026
 ****/

public class Edit {
    private GLib.DateTime datetime = new GLib.DateTime.now_local();

	private Gtk.ApplicationWindow mainwindow;
    private Files files = new Files();

    public Edit(Gtk.Application app, Window window, 
        string filepath, string filename, string datetime, Gif gif, Gifs gifs) {

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

        var datetimeentry = new Gtk.Entry();
        
        DateTime? date = new DateTime.from_iso8601(datetime, null);

        datetimeentry.set_placeholder_text(date.format("%Y-%m-%d %H:%M:%S"));

        if (date == null) {
            datetimeentry.set_placeholder_text("(no date and time available)");
        }
       
        datetimeentry.set_sensitive(false);

        box.append(makeRow("Date and time", datetimeentry));

        File file = files.checkFile("tags.conf");

        string content = "";

        var tagsbutton = new Gtk.MenuButton();
        tagsbutton.label = "Select tags";
        var tagsswitch = new Gtk.Popover();
        var tagsswitchbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 1);
        tagsswitch.set_child(tagsswitchbox);

        try {
            FileUtils.get_contents(file.get_path(), out content);

            if (content != "") {
                foreach (string line in content.split("\n")) {
                    if (line.strip() == "")
                        continue;

                    var newcheck = new Gtk.CheckButton.with_label(line.strip());

                    newcheck.toggled.connect(() => {
                        var selected = 0;

                        var child = tagsswitchbox.get_first_child();

                        while (child != null) {
                            if (child is Gtk.CheckButton) {
                                if (((Gtk.CheckButton)child).active)
                                    selected++;
                            }

                            child = child.get_next_sibling();
                        }

                        tagsbutton.label = "%d selected".printf(selected);
                    });

                    tagsswitchbox.append(newcheck);
                }
            }


            // Checks the tags defined in the gif and checks them
            string[] giftags = checkGifTags(filepath, gifs);

            if (giftags != null) {
                var sibling = tagsswitchbox.get_first_child();

                while (sibling != null) {

                    Gtk.CheckButton button = (Gtk.CheckButton)sibling;
                    
                    foreach (var tag in giftags) {
                        if (button.get_label() == tag) {
                            button.set_active(true);
                        }
                    }

                    sibling = sibling.get_next_sibling();
                }
            }
        } catch (Error e) {
            warning (e.message);
        }

        tagsbutton.popover = tagsswitch;

        var buttonsbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 2);
		buttonsbox.set_halign(Gtk.Align.END);
        var cancelbutton = new Gtk.Button();
		cancelbutton.set_label("Cancel");

		cancelbutton.clicked.connect(() => {
			mainwindow.destroy();
		});

		var applybutton = new Gtk.Button();
		applybutton.set_label("Apply");

		applybutton.clicked.connect(() => {

            string[] tags = {};

            var vamoslaver = tagsswitch.get_first_child();
            var aiai = vamoslaver.get_first_child();

            warning(vamoslaver.get_class().get_type().to_string());
            warning(aiai.get_class().get_type().to_string());

            var child = (Gtk.CheckButton)aiai.get_first_child();
            var iterator = aiai.get_first_child();
            
            while (iterator != null) {
                if (child is Gtk.CheckButton) {
                    if (((Gtk.CheckButton) child).active) {
                        tags += child.label;
                        warning(child.label);
                    }
                        
                }

                child = (Gtk.CheckButton)iterator.get_next_sibling();
                iterator = (Gtk.Widget)child;
            }

            gif.updateData(tags, gif.fileName, gifs.getFilePath());

			/*var content = "";

			for (
				var child = tagsbox.get_first_child(); 
				child != null; 
				child = child.get_next_sibling()
			) {
				var aux = child.get_next_sibling();
				if (!(child is Gtk.Label)) {
					var entry = child.get_first_child();

					if (entry is Gtk.Entry) {
						content += entry.get_text();
						if (aux != null)
							content += "\n";
					}
				}
			}

			files.saveTagsFile(content);*/

		});

        buttonsbox.append(cancelbutton);
		buttonsbox.append(applybutton);

        box.append(makeRow("Tags", tagsbutton));

        var spacer = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		spacer.vexpand = true;
		box.append (spacer);

        box.append(buttonsbox);

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

    private string[]? checkGifTags(string gifPath, Gifs gifs) {
        try {
			Json.Object? targetObject = null;

			// Read the existing JSON file
			var parser = new Json.Parser();
			parser.load_from_file(gifs.getFilePath());

			var node = parser.get_root();
			var files = node.get_array();

			// Find the object matching the filename
			for (uint i = 0; i < files.get_length(); i++) {
				var item = files.get_object_element(i);

                warning("gifname : " + gifPath);

				if (item.has_member("filePath") &&
					item.get_string_member("filePath") == gifPath) {
					targetObject = item;
					break;
				}
			}

			if (targetObject != null) {
				Json.Array tags;

				if (targetObject.has_member("tags") &&
					targetObject.get_member("tags").get_node_type() == Json.NodeType.ARRAY) {
					tags = targetObject.get_array_member("tags");

                    string[] result = {};

                    for (uint i = 0; i < tags.get_length(); i++) {
                        result += tags.get_string_element(i);
                    }

                    return result;
				}

			} else {
				print("File not found in JSON: %s\n", gifPath);
			}

		} catch (Error e) {
			print("Failed to update JSON: %s\n", e.message);
		}

        return null;
    }
}

