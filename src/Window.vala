/****
 * Window.vala - contains the main window logic
 * ricol03, 2026
 ****/

public class Window : Gtk.ApplicationWindow {

	#if WINDOWS
		[CCode (cname = "setWindowsClipboard", cheader_filename = "windows/WinClipboard.h")]
		private extern static int setWindowsClipboardNative(string filepath);
	#endif

	private Logs logs = new Logs();
	private GLib.DateTime datetime = new GLib.DateTime.now_local();

	private Gtk.Application application = new Application();
	private Dialogs dialog = new Dialogs();
	private Gifs gifs;
	private Files files = new Files();
	private File folder;
	private string[] filePaths;
	private Gif gif;
	private Gif[] gifList;
	private Gtk.ApplicationWindow mainwindow;
	private string windowtitle = "GIF Picker";
	private Gtk.IconTheme theme;
	private Gtk.Box mainbox;
	private Gtk.CenterBox centerbox;
	private Gtk.ScrolledWindow scrolled = new Gtk.ScrolledWindow();

	private bool hasindex = false;
	private bool hasjson = false;

	private Gdk.Cursor cursorHand = new Gdk.Cursor.from_name("pointer", null);
	private Gdk.Cursor cursorDefault = new Gdk.Cursor.from_name("default", null);
	private Gtk.StringList model = new Gtk.StringList(null);

	private uint visibleStart = 0;
	private uint totalitems = 0;

	private Gtk.SliceListModel slice = null;
    private int offset = 0;
    private int sliceSize = 8;

	private Gtk.Button refreshbtn = null;
	private Gtk.Button filterbtn = null;
	private Gtk.Button backbtn = null;
	private Gtk.Button nextbtn = null;
	private Gtk.Button searchbtn = null;
	private Gtk.Button favoritebtn = null;
	private Gtk.GridView grid = null;
	private Gtk.SignalListItemFactory factory = null;
	private Gtk.FilterListModel filtered = null;
	private Gtk.SingleSelection selection = null;
	private Gtk.CustomFilter customfilter = null;

	private Gtk.SearchBar search = new Gtk.SearchBar();
	private bool isSearchActive = false;

	private Gtk.HeaderBar headerbar = null;
	private string filter = "";
	private Gtk.Revealer revealer = null;

	private string env = null;

    public Window(Gtk.Application app) {
		application = app;
		string path = files.getSetting("path");

		if (path != "") {
			string[] splits = path.split("/");

			gifs = new Gifs(splits[splits.length - 1]);
			string? a = gifs.createDirs(splits[splits.length - 1]);

			if (files.getFile(a) != null) {
				if (files.hasFileContent(a)) {
					gifList = gifs.loadGifs();
					warning(gifList[0].getFileName());
					hasjson = true;
				} else
					hasjson = false;
			}
		}

		#if WINDOWS
		GLib.Environment.set_variable("GTK_CSD", "0", false);
		GLib.Environment.set_variable("GSK_RENDERER", "cairo", false);
		//GLib.Environment.set_variable("GSETTINGS_SCHEMAS_DIR", , false);
		#endif

		var css = new Gtk.CssProvider ();
		css.load_from_resource ("/io/ricol03/gifpicker/style/style.css");

		Gtk.StyleContext.add_provider_for_display (
			Gdk.Display.get_default (),
			css,
			Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
		);

		filterbtn.set_sensitive(false);
		var icontheme = Gtk.IconTheme.get_for_display(Gdk.Display.get_default());

		// env = GLib.Environment.get_variable("XDG_CURRENT_DESKTOP");
		// if (env != "GNOME")
		// 	createSysTrayIcon();

		Gtk.Window.set_default_icon_name("gifpicker-small");

		createMenuOptions();
		setWindowState(null);

		mainbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		mainbox.append(centerbox);

		#if WINDOWS
		mainwindow = new Gtk.ApplicationWindow(app) {
			child = mainbox,
			default_height = 480,
			default_width = 640,
			title = windowtitle
		};

		var menubar = new Menu();

		var filemenu = new Menu();
		filemenu.append("Refresh", "app.refresh");
		filemenu.append("Quit", "app.quit");

		var navmenu = new Menu();
		navmenu.append("Back", "app.back");
		navmenu.append("Next", "app.next");

		var searchmenu = new Menu();
		searchmenu.append("Search", "app.search");

		var settingsmenu = new Menu();
		settingsmenu.append("Settings", "app.settings");

		var helpmenu = new Menu();
		helpmenu.append("About", "app.about");

		menubar.append_submenu("File", filemenu);
		menubar.append_submenu("Navigation", navmenu);
		menubar.append_submenu("Search", searchmenu);
		menubar.append_submenu("Settings", settingsmenu);
		menubar.append_submenu("Help", helpmenu);

		application.set_menubar(menubar);

		mainwindow.set_show_menubar(true);

		#else
		mainwindow = new Gtk.ApplicationWindow(app) {
			child = mainbox,
			titlebar = headerbar,
			default_height = 480,
			default_width = 640,
			title = windowtitle
		};
		#endif

		mainwindow.set_resizable(false);
		mainwindow.set_decorated(true);

		var entry = new Gtk.SearchEntry();
		search.set_child(entry);
		search.connect_entry(entry);
		search.set_key_capture_widget(mainwindow);

		mainwindow.present();

		var messagebox = new Gtk.CenterBox();

		entry.changed.connect(() => {
			returnToFirstPage();
			filter = entry.get_text().down().strip();

			if (filter == "")
				customfilter.changed(Gtk.FilterChange.LESS_STRICT);
			else
				customfilter.changed(Gtk.FilterChange.DIFFERENT);

			slice.set_offset(0);

			checkNextButton((int)totalitems);

			bool checkMessage = false;

			if (totalitems == 0) {
				for (var child = mainbox.get_first_child(); child != null; child = child.get_next_sibling()) {
					if (child == messagebox)
						checkMessage = true;
				}

				mainbox.remove(scrolled);

				if (checkMessage == false) {
					var text = new Gtk.Label("No search results available. Try a different query.");

					messagebox.set_hexpand(true);
					messagebox.set_vexpand(true);

					var contentbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
					contentbox.set_valign(Gtk.Align.CENTER);
					contentbox.append(text);

					messagebox.set_center_widget(contentbox);

					mainbox.append(messagebox);
				}

			} else {
				mainbox.remove(messagebox);
				mainbox.append(scrolled);
			}

			logs.writeToLog(new datetime.now_local().to_string() + " : filter changed -> " + filter + "\n");
		});

		// TODO: after having a global tray icon / keyboard shortcut working
		mainwindow.close_request.connect(() => {
			logs.writeToLog( new datetime.now_local().to_string() + " : closed app\n");
			logs.writeToLog("////////////////////////// finished run \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\ \n\n");

		 	//mainwindow.hide();
		 	mainwindow.destroy();
		 	return true;
		});

		//  var shortcuts = new GlobalShortcut(mainwindow);

		//  mainwindow.show.connect (() => {
		//  	var gdk_surface = mainwindow.get_native().get_surface ();
		//  	if (gdk_surface is Gdk.Wayland.Toplevel) {
		//  		((Gdk.Wayland.Toplevel) gdk_surface).export_handle((toplevel, handle) => {
		//  		    string parent_id = "wayland:" + handle;
		//  		    shortcuts.init.begin();
		//  		});
		//  	} else
		//  		shortcuts.init.begin();
		//  });
    }

    public void refreshState() {
		string? filePath = files.getSetting("path");

		gifs.createDirs(filePath);
		if (filePath == null || filePath.strip() == "")
			return;

		folder = files.getFile(filePath);
		hasindex = true;

		if (hasindex) {
			files.getIndex.begin(filePath, (obj, res) => {
				try {
					filePaths = files.getIndex.end(res);
					totalitems = filePaths.length;
					warning(totalitems.to_string());

					var map = new Gee.HashMap<string, Gif>();
					foreach (var gif in gifList) {
						if (gif.getFileName() != null)
							map.set(gif.getFileName(), gif);
					}

					totalitems = filePaths.length;
					gifList = new Gif[totalitems];

					for (int i = 0; i < filePaths.length; i++) {
						string path = filePaths[i];

						if (map.has_key(path)) {
							// existing → reuse (keeps favorite + displayName)
							gifList[i] = map.get(path);
						} else {
							// new file → create default
							var gif = new Gif();
							gif.setFileName(path);
							gif.setDisplayName(Path.get_basename(path));
							gifList[i] = gif;
							//warning(gif.getFileName());
						}
					}

					gifs.saveGifs(gifList);

					setModel();
					setFactory();
					setGifList();

				} catch (Error e) {
					logs.writeToLog(new datetime.now_local().to_string() + " : (setWindowState) " + e.message + "\n");
				}
			});
		} else
			setWindowContent();

		logs.writeToLog(new datetime.now_local().to_string() + " : window state refreshed\n");
	}

    public void setWindowState(string[]? newfilePaths) {
		string filePath = files.getSetting("path");

		if (filePath != null && filePath != "") {
			folder = files.getFile(filePath);
			hasindex = true;
		}

		if (hasindex) {
			files.getIndex.begin(filePath, (obj, res) => {
				try {
					filePaths = files.getIndex.end(res);
					totalitems = filePaths.length;
					warning(totalitems.to_string());

					var map = new Gee.HashMap<string, Gif>();
					foreach (var gif in gifList) {
						if (gif.getFileName() != null)
							map.set(gif.getFileName(), gif);
					}

					totalitems = filePaths.length;
					gifList = new Gif[totalitems];

					for (int i = 0; i < filePaths.length; i++) {
						string path = filePaths[i];

						if (map.has_key(path)) {
							// existing → reuse (keeps favorite + displayName)
							gifList[i] = map.get(path);
						} else {
							// new file → create default
							var gif = new Gif();
							gif.setFileName(path);
							gif.setDisplayName(Path.get_basename(path));
							gifList[i] = gif;
							//warning(gif.getFileName());
						}
					}

					gifs.saveGifs(gifList);

					setModel();
					setFactory();
					setGifList();

				} catch (Error e) {
					logs.writeToLog(new datetime.now_local().to_string() + " : (setWindowState) " + e.message + "\n");
				}
			});
		} else
			setWindowContent();

		logs.writeToLog(new datetime.now_local().to_string() + " : window state set\n");
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

		//string status = files.getSetting("revealer");
		//if (status == null || status == "true" ) {
		//	setRevealer();
		//}

		grid = new Gtk.GridView(selection, factory);
		grid.set_min_columns(2);
		grid.set_max_columns(2);

		// grid.activate.connect((position) => {
		// 	var item = selection.get_model().get_item(position) as Gtk.StringObject;
		// 	var filename = item.get_string();

		// 	logs.writeToLog(new datetime.now_local().to_string() + " : gif clicked -> " + filename + "\n");

		// 	setClipboard(filename);
		// });


		scrolled.set_min_content_height(200);
		scrolled.set_hexpand(true);
		scrolled.set_vexpand(true);
		scrolled.set_child(grid);

		//if (revealer != null)
		//	mainbox.append(revealer);

		mainbox.append(scrolled);

		logs.writeToLog(new datetime.now_local().to_string() + " : gif list set\n");
	}

    public void setFactory() {
		factory = new Gtk.SignalListItemFactory();

		string labelMode = files.getSetting("labels");

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

			var filepath = stringitem.get_string();
			string filename = Path.get_basename(filepath);

			var box = (Gtk.Box)listitem.get_child();
			box.set_focusable(true);

			var picture = (Gtk.Picture)box.get_first_child();
			var label = (Gtk.Label)box.get_last_child();

			uint id = gifs.makeGifsSmall(picture, filepath);

			picture.set_data("gif-timeout", id);

			int length = filename.length;
			if (labelMode == "0") {
				if (length > 32) {
					string newfilename = filename[0:29] + "[...]" + filename[length - 4: length];
					label.set_label(newfilename);
				} else
					label.set_label(filename);
			} else {
				if (length > 36) {
					string newfilename = filename[0:35] + "[...]";
					label.set_label(newfilename);
				} else
					label.set_label(filename[0:length - 4]);
			}

			var gesture = new Gtk.GestureClick();
			gesture.pressed.connect((n_press, x, y) => {
				logs.writeToLog(new datetime.now_local().to_string() + " : gif clicked -> " + filename + "\n");
				#if WINDOWS
					filepath = filepath.replace("/", "\\");
				#endif
				setClipboard(filepath);
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

		logs.writeToLog(new datetime.now_local().to_string() + " : factory set\n");
	}

	public void setClipboard(string filename) {
		#if WINDOWS
		    int ok = setWindowsClipboardNative(filename);
			logs.writeToLog(new datetime.now_local().to_string() + " : clipboard return code -> " + ok.to_string() + "\n");
		#else
		    var file = File.new_for_path (filename);
		    string? etag;
		    Bytes bytes = file.load_bytes (null, out etag);

		    var provider = new Gdk.ContentProvider.union ({
		        new Gdk.ContentProvider.for_bytes("image/gif", bytes),
		        new Gdk.ContentProvider.for_value(file)
		    });

		    var display = Gdk.Display.get_default ();
		    var clipboard = display.get_clipboard ();
		    clipboard.set_content (provider);
		#endif

		logs.writeToLog(new datetime.now_local().to_string() + " : clipboard set -> " + filename + "\n");
	}

	public void setRevealer() {
		files.saveSettingsFile("revealer", "true");
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
			if (uri == "openwindow") {
				var settings = new Settings(application, this);
				revealer.set_reveal_child(false);
				files.saveSettingsFile("revealer", "false");
			}
			return true;
		});

		var close_btn = new Gtk.Button.from_icon_name("window-close-symbolic");
		close_btn.clicked.connect(() => {
			revealer.set_reveal_child(false);
			files.saveSettingsFile("revealer", "false");
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
		string[] empty = {};
		model.splice(0, model.get_n_items(), empty);

		for (int i = 0; i < gifList.length; i++) {
			model.append(gifList[i].getFileName());
			warning("no modelo: " + gifList[i].getFileName());
		}

		customfilter = new Gtk.CustomFilter((obj) => {
			var item = obj as Gtk.StringObject;

			if (filter == "")
				return true;

			return item.get_string().down().contains(filter);
		});

		filtered = new Gtk.FilterListModel(model, customfilter);

		filtered.items_changed.connect((position, removed, added) => {
			totalitems = filtered.get_n_items();
		});

		slice = new Gtk.SliceListModel(
			filtered,
			visibleStart,
			sliceSize
		);

		if (visibleStart >= totalitems && totalitems > 0) {
			visibleStart = ((totalitems - 1) / sliceSize) * sliceSize;
		}

		slice.set_offset(visibleStart);
		slice.set_size((uint) sliceSize);

		selection = new Gtk.SingleSelection(slice);

		logs.writeToLog(new datetime.now_local().to_string() + " : model set\n");
	}

    public void setWindowContent() {
		searchbtn.set_sensitive(false);
		refreshbtn.set_sensitive(false);

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

		logs.writeToLog(new datetime.now_local().to_string() + " : window content set\n");
	}

    public async void getFolder() {
		try {
		    folder = yield dialog.openFolderDialog(mainwindow);
			if (folder != null) {
				hasindex = true;
				files.saveSettingsFile("path", folder.get_path());
				setWindowState(null);
			}
		} catch (Error e) {
		   	logs.writeToLog(new datetime.now_local().to_string() + " : (getFolder) " + e.message + "\n");
		}
	}

	public void returnToFirstPage() {
		while (offset != 0) {
			offset -= sliceSize;
		}

		slice.set_offset(offset);
		grid.scroll_to(0, Gtk.ListScrollFlags.NONE, null);

		checkBackButton();
		checkNextButton((int)totalitems);

		logs.writeToLog(new datetime.now_local().to_string() + " : return to first page\n");
	}

	public void backPage() {
		offset -= sliceSize;
        slice.set_offset(offset);
 		grid.scroll_to(0, Gtk.ListScrollFlags.NONE, null);

		checkBackButton();
		checkNextButton((int)totalitems);

		logs.writeToLog(new datetime.now_local().to_string() + " : back page\n");
	}

	public void nextPage() {
		offset += sliceSize;
        slice.set_offset(offset);
 		grid.scroll_to(0, Gtk.ListScrollFlags.NONE, null);

		checkBackButton();
		checkNextButton((int)totalitems);

		logs.writeToLog(new datetime.now_local().to_string() + " : next page\n");
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

	public void checkNextButton(int length) {
		var action = (SimpleAction)application.lookup_action("next");
		if (offset + sliceSize >= length) {
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

			logs.writeToLog(new datetime.now_local().to_string() + " : search mode inactive\n");
		} else {
			search.set_search_mode(true);
			isSearchActive = true;

			logs.writeToLog(new datetime.now_local().to_string() + " : search mode active\n");
		}
	}

	// private void createSysTrayIcon() {
	// 	try {
	// 		var bus = Bus.get_sync(BusType.SESSION);
	// 		var tray = new Tray(mainwindow);

	// 		Bus.own_name(
	// 			BusType.SESSION,
	// 			"io.ricol03.gifpicker",
	// 			BusNameOwnerFlags.NONE,
	// 			(conn, name) => { print("Bus acquired\n"); },
	// 			(conn, name) => {
	// 				print("Name acquired\n");

	// 				conn.register_object("/StatusNotifierItem", tray);

	// 				var proxy = new DBusProxy.sync(
	// 					conn,
	// 					DBusProxyFlags.NONE,
	// 					null,
	// 					"org.kde.StatusNotifierWatcher",
	// 					"/StatusNotifierWatcher",
	// 					"org.kde.StatusNotifierWatcher",
	// 					null
	// 				);

	// 				proxy.call_sync(
	// 					"RegisterStatusNotifierItem",
	// 					new Variant("(s)", "/StatusNotifierItem"),
	// 					DBusCallFlags.NONE,
	// 					-1
	// 				);
	// 			},
	// 			(conn, name) => { print("Name lost\n"); }
	// 		);

	// 	} catch (Error e) {
	// 		logs.writeToLog(new datetime.now_local().to_string() + " : (createSysTrayIcon)" + e.message + "\n");
	// 	}
	// }

	private void createMenuOptions() {
		var menubox = new Menu();

		menubox.append("Settings", "app.settings");
		menubox.append("About", "app.about");
		menubox.append("Quit", "app.quit");

		refreshbtn = new Gtk.Button() {
			icon_name = "reload-symbolic",
		};
		refreshbtn.set_tooltip_markup("Refresh <span alpha='70%'>(Ctrl+R)</span>");

		filterbtn = new Gtk.Button() {
			icon_name = "filter-symbolic",
		};
		filterbtn.set_tooltip_markup("Filter");
		filterbtn.set_sensitive(false);

		searchbtn = new Gtk.Button() {
			icon_name = "search-symbolic",
		};
		searchbtn.set_tooltip_markup("Search <span alpha='70%'>(Ctrl+S)</span>");

		backbtn = new Gtk.Button() {
			icon_name = "back-symbolic",
		};
		backbtn.set_tooltip_markup("Back <span alpha='70%'>(Alt+B)</span>");

		nextbtn = new Gtk.Button() {
			icon_name = "next-symbolic",
		};
		nextbtn.set_tooltip_markup("Next <span alpha='70%'>(Alt+N)</span>");

		favoritebtn = new Gtk.Button() {
			icon_name = "favorite",
		};
		favoritebtn.set_tooltip_markup("Favourite <span alpha='70%'>(Ctrl+F)</span>");
		favoritebtn.set_sensitive(false);

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
		headerbar.pack_start(favoritebtn);

		headerbar.pack_end(menubtn);
		headerbar.pack_end(filterbtn);
		headerbar.pack_end(refreshbtn);

		logs.writeToLog(new datetime.now_local().to_string() + " : menu options created\n");
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