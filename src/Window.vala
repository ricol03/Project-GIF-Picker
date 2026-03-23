/****
 * Window.vala - contains the main window logic
 * ricol03, 2026
 ****/

[GtkTemplate (ui = "/io/ricol03/gifpicker/window.ui")]
public class Window : Gtk.ApplicationWindow {
	private Gtk.Application application = new Application();
	private Dialogs dialog = new Dialogs();
	private Gif gif = new Gif();
	private Files files = new Files();
	private File folder;
	private string[] filePaths;
	private Gtk.ApplicationWindow mainwindow;
	private string windowtitle = "GIF Picker";
	private Gtk.Box mainbox;
	private Gtk.CenterBox centerbox;
	private bool hasindex = false;
	private Gdk.Cursor cursorHand = new Gdk.Cursor.from_name("pointer", null);
	private Gdk.Cursor cursorDefault = new Gdk.Cursor.from_name("default", null);
	private Gtk.StringList model = new Gtk.StringList(null);

	private int visibleStart = 0;

	private Gtk.SliceListModel slice = null;
    private int offset = 0;
    private int sliceSize = 8;

	private Gtk.Button refreshbtn = null;
	private Gtk.Button filterbtn = null;
	private Gtk.Button backbtn = null;
	private Gtk.Button nextbtn = null;
	private Gtk.Button searchbtn = null;
	private Gtk.GridView grid = null;
	private Gtk.SignalListItemFactory factory = null;
	private Gtk.SingleSelection selection = null;
	private Gtk.CustomFilter customfilter = null;

	private Gtk.SearchBar search = new Gtk.SearchBar();
	private bool isSearchActive = false;

	private Gtk.HeaderBar headerbar = null;
	private string filter = "";
	private Gtk.Revealer revealer = null;

	private string env = null;

    public Window(Gtk.Application app, bool index, File? fileFolder) {
		application = app;
		hasindex = index;
		folder = fileFolder;

		env = GLib.Environment.get_variable("XDG_CURRENT_DESKTOP");
		if (env != "GNOME")
			createSysTrayIcon();

		createMenuOptions();
		setWindowState();

		mainbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		mainbox.append(centerbox);

		mainwindow = new Gtk.ApplicationWindow(app) {
			child = mainbox,
			titlebar = headerbar,
			default_height = 480,
			default_width = 640,
			title = windowtitle
		};
		mainwindow.set_resizable(false);

		var entry = new Gtk.SearchEntry();
		search.set_child(entry);
		search.connect_entry(entry);
		search.set_key_capture_widget(mainwindow);

		mainwindow.present();

		entry.search_changed.connect(() => {
			filter = entry.get_text().down().strip();

			if (filter == "")
				customfilter.changed(Gtk.FilterChange.LESS_STRICT);
			else
				customfilter.changed(Gtk.FilterChange.DIFFERENT);

			slice.set_offset(0);
		});

		mainwindow.close_request.connect(() => {
			mainwindow.hide();
			return true;
		});
    }

    public void setWindowState() {
		if (hasindex) {
			files.getIndex(folder.get_path());

			files.index_ready.connect((paths) => {
				filePaths = paths;
				setModel();
				setFactory();
				setGifList();
			});
		} else
			setWindowContent();
	}

    public void setGifList() {
		setSpinner(false);

		searchbtn.set_action_name("app.search");
		backbtn.set_action_name("app.back");
		nextbtn.set_action_name("app.next");
		refreshbtn.set_action_name("app.refresh");

		checkBackButton();

		if (mainbox.get_last_child() != null)
			if (mainbox.get_last_child().get_name() != null)
				mainbox.remove(mainbox.get_last_child());

		mainbox.append(search);

		string status = files.getRevealerStatus();
		if (status == null || status == "true" ) {
			setRevealer();
		}

		grid = new Gtk.GridView(selection, factory);
		grid.set_min_columns(2);
		grid.set_max_columns(2);

		var scrolled = new Gtk.ScrolledWindow();
		scrolled.set_min_content_height(200);
		scrolled.set_hexpand(true);
		scrolled.set_vexpand(true);
		scrolled.set_child(grid);

		if (revealer != null)
			mainbox.append(revealer);

		mainbox.append(scrolled);
	}

    public void setFactory() {
		factory.setup.connect((obj) => {
			var listitem = (Gtk.ListItem)obj;
			var picture = new Gtk.Picture();
			picture.set_size_request(150, 200);
			picture.set_content_fit(Gtk.ContentFit.CONTAIN);
			picture.set_hexpand(true);
			picture.set_vexpand(true);

			var label = new Gtk.Label("") {
				margin_top = 10
			};

			var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
			box.set_halign(Gtk.Align.CENTER);
			box.set_size_request(150, 250);

			box.append(picture);
			box.append(label);

			var motion = new Gtk.EventControllerMotion();
			motion.enter.connect(() => {
				mainwindow.set_cursor(cursorHand);
			});

			motion.leave.connect(() => {
				mainwindow.set_cursor(cursorDefault);
			});
			box.add_controller(motion);

			listitem.set_child(box);
		});

		factory.bind.connect((obj) => {
			var listitem = (Gtk.ListItem)obj;
			var stringitem = (Gtk.StringObject)listitem.get_item();
			var filename = stringitem.get_string();

			var box = (Gtk.Box)listitem.get_child();

			var picture = (Gtk.Picture)box.get_first_child();
			var label = (Gtk.Label)box.get_last_child();

			uint id = gif.makeGifsSmall(picture, folder.get_path() + "/" + filename);

			picture.set_data("gif-timeout", id);

			label.set_label(filename);

			var gesture = new Gtk.GestureClick();
			gesture.pressed.connect((n_press, x, y) => {
				var file = File.new_for_path(folder.get_path() + "/" + filename);

				string? etag;
				Bytes bytes = file.load_bytes(null, out etag);

				var provider = new Gdk.ContentProvider.union({
					new Gdk.ContentProvider.for_bytes("image/gif", bytes),
					new Gdk.ContentProvider.for_bytes("application/octet-stream", bytes),
					new Gdk.ContentProvider.for_value(file)
				});

				var display = Gdk.Display.get_default();
				var clipboard = display.get_clipboard();
				clipboard.set_content(provider);
			});
			box.add_controller(gesture);

			box.set_hexpand(true);
			box.set_vexpand(true);
			box.set_halign(Gtk.Align.FILL);
			box.set_valign(Gtk.Align.FILL);
		});

		factory.unbind.connect((obj) => {
			var listitem = (Gtk.ListItem)obj;
			var box = (Gtk.Box)listitem.get_child();
			var picture = (Gtk.Picture)box.get_first_child();

			uint player = picture.get_data("gif-timeout");

			if (player != 0) {
				Source.remove(player);
			}

			picture.set_paintable(null);
		});
	}

	public void setRevealer() {
		files.setRevealerStatus("true");
		revealer = new Gtk.Revealer();
		revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN);
		revealer.set_reveal_child(false);

		var banner = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
		banner.add_css_class("notification");

		var label = new Gtk.Label("");
		label.set_hexpand(true);
		label.set_halign(Gtk.Align.CENTER);
		label.set_use_markup(true);

		if (env == "GNOME")
			label.set_markup("A keyboard shortcut needs to be set to show/hide the window. <a href='openwindow'>Click here.</a>");
		else
			label.set_markup("A different keyboard shortcut can be set to show/hide the window. <a href='openwindow'>Click here.</a>");

		label.activate_link.connect((uri) => {
			if (uri == "openwindow")
				warning("settings window here");

			return true;
		});

		var close_btn = new Gtk.Button.from_icon_name("window-close-symbolic");
		close_btn.clicked.connect(() => {
			revealer.set_reveal_child(false);
			files.setRevealerStatus("false");
		});

		banner.append(label);
		banner.append(close_btn);

		revealer.set_child(banner);

		mainbox.append(revealer);

		revealer.set_reveal_child(true);
	}

	public void setSpinner(bool status) {
		if (status) {
			var spinner = new Gtk.Spinner();
			spinner.set_size_request(50, 50);
			spinner.start();
			mainbox.append(spinner);
		} else {
			var spinner = (Gtk.Spinner)mainbox.get_first_child();
			spinner.stop();
			mainbox.remove(spinner);
		}
	}

    public void setModel() {
		for (int i = 0; i < filePaths.length; i++)
			model.append(filePaths[i]);

		customfilter = new Gtk.CustomFilter((obj) => {
			var item = obj as Gtk.StringObject;

			if (filter == "")
				return true;

			if (item.get_string().down().contains(filter))
				warning(item.get_string());

			return item.get_string().down().contains(filter);
		});

		var filtered = new Gtk.FilterListModel(model, customfilter);

		slice = new Gtk.SliceListModel(
			filtered,
			visibleStart,
			sliceSize
		);

		selection = new Gtk.SingleSelection(slice);

		factory = new Gtk.SignalListItemFactory();
	}

    public void setWindowContent() {
		searchbtn.set_sensitive(false);
		refreshbtn.set_sensitive(false);
		filterbtn.set_sensitive(false);
		backbtn.set_sensitive(false);
		nextbtn.set_sensitive(false);

		centerbox = new Gtk.CenterBox();
		centerbox.set_hexpand(true);
		centerbox.set_vexpand(true);

		var contentbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 3);
		var image = new Gtk.Image.from_icon_name("close");
		image.set_icon_size(2);
		var text = new Gtk.Label("GIF list not available. Please select a location.");

		var button = new Gtk.Button.with_label("Select location...") {
			margin_top = 10,
			margin_bottom = 2,
			margin_start = 160,
			margin_end = 160
		};
		button.add_css_class("suggested-action");

		button.clicked.connect (() => {
			getFolder.begin();
	    });

		contentbox.set_valign(Gtk.Align.CENTER);

		contentbox.append(image);
		contentbox.append(text);
		contentbox.append(button);
		centerbox.set_center_widget(contentbox);

		mainbox.append(centerbox);
	}

    public async void getFolder() {
		try {
		    folder = yield dialog.openFolderDialog(mainwindow);
			if (folder != null) {
				hasindex = true;
				files.saveSettingsFile(folder.get_path());
				setWindowState();
			}
		} catch (Error e) {
		    warning("No folder selected");
		}
	}

	public void backPage() {
		offset -= sliceSize;
        slice.set_offset(offset);
 		grid.scroll_to(0, Gtk.ListScrollFlags.NONE, null);

		checkBackButton();
		checkNextButton();
	}

	public void nextPage() {
		offset += sliceSize;
        slice.set_offset(offset);
 		grid.scroll_to(0, Gtk.ListScrollFlags.NONE, null);

		checkBackButton();
		checkNextButton();
	}

	public void checkBackButton() {
		var action = (SimpleAction)application.lookup_action("back");
		if (offset - sliceSize < 0) {
			backbtn.set_sensitive(false);
			action.set_enabled(false);
		} else {
			backbtn.set_sensitive(true);
			action.set_enabled(true);
		}
	}

	public void checkNextButton() {
		var action = (SimpleAction)application.lookup_action("next");
		if (offset + sliceSize > filePaths.length) {
			nextbtn.set_sensitive(false);
			action.set_enabled(false);
		} else {
			nextbtn.set_sensitive(true);
			action.set_enabled(true);
		}
	}

	public void toggleSearchBar() {
		if (isSearchActive) {
			search.set_search_mode(false);
			isSearchActive = false;
		} else {
			search.set_search_mode(true);
			isSearchActive = true;
		}
	}

	private void createSysTrayIcon() {
		try {
			var bus = Bus.get_sync(BusType.SESSION);
			var tray = new Tray(mainwindow);

			Bus.own_name(
				BusType.SESSION,
				"io.ricol03.gifpicker",
				BusNameOwnerFlags.NONE,
				(conn, name) => { print("Bus acquired\n"); },
				(conn, name) => {
					print("Name acquired\n");

					conn.register_object("/StatusNotifierItem", tray);

					var proxy = new DBusProxy.sync(
						conn,
						DBusProxyFlags.NONE,
						null,
						"org.kde.StatusNotifierWatcher",
						"/StatusNotifierWatcher",
						"org.kde.StatusNotifierWatcher",
						null
					);

					proxy.call_sync(
						"RegisterStatusNotifierItem",
						new Variant("(s)", "/StatusNotifierItem"),
						DBusCallFlags.NONE,
						-1
					);
				},
				(conn, name) => { print("Name lost\n"); }
			);

		} catch (Error e) {
			warning(e.message);
		}
	}

	private void createMenuOptions() {
		var menubox = new Menu();

		menubox.append("Open File...", "app.open");
		menubox.append("Save File...", "app.save");
		menubox.append("Quit", "app.quit");

		refreshbtn = new Gtk.Button() {
			icon_name = "reload-symbolic",
		};
		refreshbtn.set_tooltip_markup("Refresh");

		filterbtn = new Gtk.Button() {
			icon_name = "filter-symbolic",
		};
		filterbtn.set_tooltip_markup("Filter");

		searchbtn = new Gtk.Button() {
			icon_name = "search-symbolic",
		};
		searchbtn.set_tooltip_markup("Search");

		backbtn = new Gtk.Button() {
			icon_name = "back-symbolic",
		};
		backbtn.set_tooltip_markup("Back");

		nextbtn = new Gtk.Button() {
			icon_name = "next-symbolic",
		};
		nextbtn.set_tooltip_markup("Next");

		var menubtn = new Gtk.MenuButton() {
			icon_name = "open-menu-symbolic",
			primary = true,
		};
		menubtn.set_menu_model(menubox);
		menubtn.set_tooltip_markup("Menu");

		headerbar = new Gtk.HeaderBar() {
			show_title_buttons = true
		};

		headerbar.pack_start(backbtn);
		headerbar.pack_start(nextbtn);
		headerbar.pack_start(searchbtn);

		headerbar.pack_end(menubtn);
		headerbar.pack_end(filterbtn);
		headerbar.pack_end(refreshbtn);
	}

	public void messagebox() {
		var message = new Gtk.MessageDialog (
            mainwindow,
            Gtk.DialogFlags.MODAL,
            Gtk.MessageType.INFO,
            Gtk.ButtonsType.OK,
            "You selected:\n%s".printf (folder.get_path() ?? "(unknown)")
        );

        message.title = "File Selected";

        message.response.connect ((_) => {
            message.destroy ();
        });

		message.present();

		if (folder.get_basename() != null) {
			hasindex = true;
		}
	}

	public void filterFiles(string filter) {
		string[] newFilePaths = null;
		int count = 0;
		for (int i = 0; i < filePaths.length; i++)
			if (filePaths[i].contains(filter)) {
				newFilePaths[count] = filePaths[i];
				count++;
			}

		filePaths = newFilePaths;
	}
}