/****
 * Window.vala - contains the main window logic
 * ricol03, 2026
 ****/

using Gee;

public class Window : Gtk.ApplicationWindow {

	#if WINDOWS
		[CCode (cname = "setWindowsClipboard", cheader_filename = "windows/WinClipboard.h")]
		private extern static int setWindowsClipboardNative(string filepath);
	#endif

	private Gtk.Application application;
	private Dialogs dialog;
	private Gifs gifs;
	private Files files;
	private string[] filePaths;
	private Gif[] gifList;
	private Gtk.ApplicationWindow mainwindow;
	private string windowtitle = "GIF Picker";
	//private Gtk.IconTheme theme;
	private Gtk.Stack stack = new Gtk.Stack();
	private Gtk.Overlay overlay = new Gtk.Overlay();
	private Gtk.Spinner spinner;
	private Gtk.Box mainbox;
	private Gtk.CenterBox centerbox;
	private Gtk.ScrolledWindow scrolled = new Gtk.ScrolledWindow();

	private bool hasindex = false;
	private bool hasjson = false;

	private Gdk.Cursor cursorHand = new Gdk.Cursor.from_name("pointer", null);
	private Gdk.Cursor cursorDefault = new Gdk.Cursor.from_name("default", null);
	//private Gdk.Cursor cursorProhibited = new Gdk.Cursor.from_name("not-allowed", null);
	public ListStore model = new ListStore(typeof(Gif));

	private uint visibleStart = 0;
	private uint totalitems = 0;

	private Gtk.SliceListModel slice = null;
    private int offset = 0;
    private int sliceSize = 12;

	private Gtk.MenuButton menubtn = null;
	private Gtk.Button refreshbtn = null;
	private Gtk.MenuButton filterbtn = null;
	private Gtk.Button backbtn = null;
	private Gtk.Button nextbtn = null;
	private Gtk.ToggleButton searchbtn = null;
	private Gtk.ToggleButton favoritebtn = null;
	private Gtk.GridView grid = null;
	private Gtk.SignalListItemFactory factory = null;
	private Gtk.FilterListModel filtered = null;
	private Gtk.FilterListModel favoritesfiltered = null;
	private Gtk.FilterListModel tagsfiltered = null;
	private Gtk.SingleSelection selection = null;
	private Gtk.SingleSelection favoritesselection = null;
	private Gtk.SingleSelection tagsselection = null;
	private Gtk.CustomFilter defaultfilter = null;
	private Gtk.CustomFilter favoritesfilter = null;
	private Gtk.CustomFilter tagsfilter = null;

	private Gtk.Popover filterpopup = null;
	private Gtk.Box filterpopupbox = null;

	private Gtk.SearchBar search = new Gtk.SearchBar();

	private Gtk.HeaderBar headerbar = null;
	private string filter = "";
	private Gtk.Revealer revealer = null;

	private string convertedName;

	private string env = null;

	private ArrayList<string> filterArray = new ArrayList<string>();

	// main window logic
    public Window(Gtk.Application app, Files files) {
		application = app;
		this.files = files;
		this.dialog = new Dialogs(files);

		loadingFromFile();

		runMonitor();

		#if WINDOWS
		GLib.Environment.set_variable("GTK_CSD", "0", false);
		GLib.Environment.set_variable("GSK_RENDERER", "cairo", false);
		//GLib.Environment.set_variable("GSETTINGS_SCHEMAS_DIR", , false);
		#endif

		var css = new Gtk.CssProvider();
		css.load_from_resource("/io/ricol03/gifpicker/style/style.css");

		Gtk.StyleContext.add_provider_for_display(
			Gdk.Display.get_default(),
			css,
			Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
		);

		//var icontheme = Gtk.IconTheme.get_for_display(Gdk.Display.get_default());

		// env = GLib.Environment.get_variable("XDG_CURRENT_DESKTOP");
		// if (env != "GNOME")
		// 	createSysTrayIcon();

		// #if WINDOWS
		// var image = new Gtk.Image.from_resource(
		// 	"/io/ricol03/gifpicker/icons/icons/hicolor/scalable/actions/gifpicker-small.svg"
		// );

		// Gtk.Window.set_default_icon(image);

		// #else
		Gtk.Window.set_default_icon_name("gifpicker-small");
		//#endif

		createMenuOptions();
		refreshState();

		mainbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		mainbox.append(centerbox);

		stack.set_transition_type(Gtk.StackTransitionType.SLIDE_UP_DOWN);
		stack.set_transition_duration(250);

		stack.set_hexpand(true);
		stack.set_vexpand(true);

		stack.add_named(mainbox, "main");

		var panel = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		panel.add_css_class("panel");
		stack.add_named(panel, "panel");

		stack.set_visible_child_name("main");

		overlay.set_child(stack);

		spinner = new Gtk.Spinner();

		spinner.set_size_request(50, 50);

		spinner.set_halign(Gtk.Align.CENTER);
		spinner.set_valign(Gtk.Align.CENTER);

		spinner.set_visible(false);

		overlay.add_overlay(spinner);

		mainwindow = new Gtk.ApplicationWindow(app) {
			child = overlay,
			titlebar = headerbar,
			default_height = 480,
			default_width = 640,
			title = windowtitle
		};
		
		mainwindow.set_decorated(true);

		var entry = new Gtk.SearchEntry();
		search.set_child(entry);
		search.connect_entry(entry);
		search.set_key_capture_widget(mainwindow);

		mainwindow.present();

		var messagebox = new Gtk.CenterBox();


		// when the user searches
		entry.changed.connect(() => {
			returnToFirstPage();
			filter = entry.get_text().down().strip();

			if (filter == "")
				defaultfilter.changed(Gtk.FilterChange.LESS_STRICT);
			else
				defaultfilter.changed(Gtk.FilterChange.DIFFERENT);

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

			files.writeToLog("Filter changed -> " + filter + "\n");
		});

		// TODO: after having a global tray icon / keyboard shortcut working
		mainwindow.close_request.connect(() => {
			//gifs.saveGifs(gifList);
			files.writeToLog("Closed app\n");

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

	public void runMonitor() {
		
		string? path = files.getSetting ("path");

		if (path == null || path.strip () == "") {
			files.writeToLog ("No folder path is set");
			return;
		}

		File monitorFolder = File.new_for_path (path);
		
		files.checkFolderChanges(monitorFolder, this);
	}

	public string convertedFileName() {
		string? path = files.getSetting("path");
		
		if (path == null || path.strip() == "")
			return "";

		string fileName = Path.get_basename(path);
		convertedName = fileName.down();

		if (convertedName.contains(" "))
			convertedName = convertedName.replace(" ", "-");

		gifs = new Gifs(files, convertedName);

		return gifs.createDirs(convertedName);
	}

	// loads the gif list and other information from file
    public void loadingFromFile() {
        string filePath = convertedFileName();

        if (files.getFile(filePath) != null) {
            if (files.hasFileContent(filePath)) {
                gifList = gifs.loadGifs();
                hasjson = true;
            }
        }
    }

	// refreshes the window state, according to the path setting
	// if path has a valid folder path, it shows the gifs in a list
	// else it shows a message for the user to add a folder
    public void refreshState() {
        string path = files.getSetting("path");
        string filePath = convertedFileName();

        if (filePath == null || filePath.strip() == "") {
			hasindex = false;
            setWindowContent();
			return;
		} else {
			hasindex = true;
			files.setFolder(files.getFile(filePath));
		}

        if (hasindex) {
			setSpinner(true);

            files.getIndex.begin(path, (obj, res) => {
				filePaths = files.getIndex.end(res);
				totalitems = filePaths.length;

				var map = new HashTable<string, Gif>(str_hash, str_equal);
				foreach (var gif in gifList) {
					if (gif.fileName != null)
						map.set(gif.fileName, gif);
				}

				totalitems = filePaths.length;
				gifList = new Gif[totalitems];

				for (int i = 0; i < filePaths.length; i++) {
					string filepath = filePaths[i];
					string fileName = Path.get_basename(filepath);

					if (map.contains(fileName)) {
						// existing → reuse (keeps favorite + displayName)
						gifList[i] = map.get(fileName);
						gifList[i].filePath = filepath; // update path if necessary
					} else {
						// new file → create default
						var gif = new Gif();
						gif.filePath = filepath;
						gif.fileName = fileName;
						gif.displayName = fileName;
						gif.dateTime = gif.getDate(filepath);
						gif.isFavorite = false;
						gif.tags = null;
						gifList[i] = gif;
					}
				}

				// Only save if there are changes to avoid overwriting user modifications
				if (gifList.length > 0) {
					gifs.saveGifs(gifList);
				}

				setModel();
				setFactory();
				setGifList();
            });
        } else
            setWindowContent();

        files.writeToLog("Window state refreshed\n");
    }

	// sets the actual gif list in the main window
    public void setGifList() {
		setSpinner(false);

		searchbtn.set_action_name("app.search");
		backbtn.set_action_name("app.back");
		nextbtn.set_action_name("app.next");
		refreshbtn.set_action_name("app.refresh");
		favoritebtn.set_action_name("app.favorite");

		checkBackButton();
		checkNextButton((int)totalitems);

		if (mainbox.get_last_child() != null)
			if (mainbox.get_last_child().get_name() != null)
				mainbox.remove(mainbox.get_last_child());

		mainbox.append(search);

		/*string status = files.getSetting("revealer");
		if (status == null || status == "true" ) {
			setRevealer();
		}*/

		grid = new Gtk.GridView(
			selection, 
			factory
		);

		grid.set_min_columns(2);
		grid.set_max_columns(2);

		// grid.activate.connect((position) => {
		// 	var item = selection.get_model().get_item(position) as Gtk.StringObject;
		// 	var filename = item.get_string();

		// 	files.writeToLog("gif clicked -> " + filename + "\n");

		// 	setClipboard(filename);
		// });

		scrolled.set_hexpand(true);
		scrolled.set_vexpand(true);
		scrolled.set_child(grid);

		if (revealer != null)
			mainbox.append(revealer);

		mainbox.append(scrolled);

		files.writeToLog("GIF list set\n");
	}

	private bool isInsideWidget(Gtk.Widget? child, Gtk.Widget parent) {
		while (child != null) {
		    if (child == parent)
		        return true;

		    child = child.get_parent();
		}

		return false;
	}

	// creates the list factory
    public void setFactory() {
		factory = new Gtk.SignalListItemFactory();

		string labelMode = files.getSetting("labels");

		factory.setup.connect((obj) => {
			var listitem = (Gtk.ListItem)obj;

			var overlay = new Gtk.Overlay();

			var picture = new Gtk.Picture();
			picture.set_size_request(150, 200);
			picture.set_content_fit(Gtk.ContentFit.CONTAIN);
			picture.set_hexpand(true);
			picture.set_vexpand(true);

			overlay.set_child(picture);

			var buttonBox = new Gtk.Box(Gtk.Orientation.VERTICAL, 2);

			var favoriteButton = new Gtk.Button();
			favoriteButton.add_css_class("gif-button");

			buttonBox.set_halign(Gtk.Align.START);
			buttonBox.set_valign(Gtk.Align.START);

			var editButton = new Gtk.Button();
			editButton.add_css_class("gif-button");
			#if WINDOWS
				var image = new Gtk.Image.from_resource(
					"/io/ricol03/gifpicker/icons/icons/hicolor/scalable/actions/document-edit-symbolic.svg"
				);

				editButton.set_child(image);
			#else
				editButton.set_icon_name("document-edit-symbolic");
			#endif
			//editButton.set_sensitive(false);

			editButton.set_halign(Gtk.Align.START);
			editButton.set_valign(Gtk.Align.START);

			buttonBox.append(favoriteButton);
			buttonBox.append(editButton);

			overlay.add_overlay(buttonBox);

			var label = new Gtk.Label("") {
				margin_top = 10
			};

			var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
			box.set_halign(Gtk.Align.CENTER);
			box.set_size_request(150, 250);

			box.append(overlay);
			box.append(label);

			listitem.set_data("picture", picture);
			listitem.set_data("favoritebutton", favoriteButton);
			listitem.set_data("editbutton", editButton);
			listitem.set_data("label", label);
			listitem.set_child(box);
		});

		factory.bind.connect((obj) => {
			var listitem = (Gtk.ListItem)obj;

			var gif = (Gif)listitem.get_item();

			string filepath = gif.filePath;
			string filename = gif.fileName;
			string filedatetime = gif.dateTime.to_string();
			var box = (Gtk.Box) listitem.get_child();
			box.set_focusable(true);

			//var overlay = (Gtk.Overlay)box.get_first_child();
			var picture = listitem.get_data<Gtk.Picture>("picture");

			var state = new GifState(filepath);

			var gridmotion = new Gtk.EventControllerMotion();
			gridmotion.enter.connect(() => {
				mainwindow.set_cursor(cursorHand);				
				gifs.startGifAnimation(picture, state);
			});

			gridmotion.leave.connect(() => {
				mainwindow.set_cursor(cursorDefault);
				gifs.stopGifAnimation(picture, state);
			});
			box.add_controller(gridmotion);

			var favoriteButton  = listitem.get_data<Gtk.Button>("favoritebutton");
			var editButton  = listitem.get_data<Gtk.Button>("editbutton");
			var label = listitem.get_data<Gtk.Label>("label");
			gifs.makeGifsSmall(picture, filepath);

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
			
			updateFavoriteButton(favoriteButton, gif);

			ulong notify_id = gif.notify["isFavorite"].connect (() => {
				updateFavoriteButton(favoriteButton, gif);
			});

			ulong clicked_id = favoriteButton.clicked.connect(() => {
			  	gif.isFavorite = !gif.isFavorite;
				updateFavoriteButton(favoriteButton, gif);

			  	gifs.saveModel(model);
			});

			listitem.set_data("favorite-notify-id", notify_id);
			listitem.set_data("favorite-clicked-id", clicked_id);

			editButton.clicked.connect(() => {
				var edit = new Edit(application, this, filepath, filename, filedatetime, gif, gifs, files);

				edit.closed.connect(() => {
					gifList = gifs.loadGifs();
				});
			});

			var gesture = new Gtk.GestureClick();
			gesture.set_propagation_phase(Gtk.PropagationPhase.BUBBLE);
			gesture.pressed.connect((n_press, x, y) => {
				var picked = box.pick(x, y, Gtk.PickFlags.DEFAULT);

				if (isInsideWidget(picked, favoriteButton) ||
					isInsideWidget(picked, editButton)) {
					return;
				}

				files.writeToLog("GIF clicked -> " + filename + "\n");
				#if WINDOWS
					filepath = filepath.replace("/", "\\");
				#endif
				setClipboard(filepath);

				showNotification();
			});
			box.add_controller(gesture);

			box.set_hexpand(true);
			box.set_vexpand(true);
			box.set_halign(Gtk.Align.FILL);
			box.set_valign(Gtk.Align.FILL);
		});

		factory.unbind.connect((obj) => {

			var listitem = (Gtk.ListItem)obj;

			var gif = (Gif)listitem.get_item();

			var box = (Gtk.Box)listitem.get_child();

			var overlay = (Gtk.Overlay)box.get_first_child();

			var picture = (Gtk.Picture)overlay.get_child();

			uint player = picture.get_data("gif-timeout");

			if (player != 0) {
				Source.remove(player);
			}

			var favoriteButton =
				listitem.get_data<Gtk.Button>("favoritebutton");

			ulong notify_id =
				listitem.get_data<ulong>("favorite-notify-id");

			ulong clicked_id =
				listitem.get_data<ulong>("favorite-clicked-id");

			if (gif != null && notify_id != 0) {
				gif.disconnect(notify_id);
			}

			if (clicked_id != 0) {
				favoriteButton.disconnect(clicked_id);
			}

			picture.set_paintable(null);
		});

		files.writeToLog("Factory set\n");
	}

	public void setClipboard(string filename) {
		#if WINDOWS
		    int ok = setWindowsClipboardNative(filename);
			files.writeToLog("Clipboard return code -> " + ok.to_string() + "\n");
		#else
			var file = File.new_for_path(filename);

			try {
				string? etag;
		    	Bytes bytes = file.load_bytes (null, out etag);

				var provider = new Gdk.ContentProvider.union ({
					new Gdk.ContentProvider.for_bytes("image/gif", bytes),
					new Gdk.ContentProvider.for_value(file)
				});

				var display = Gdk.Display.get_default();
				var clipboard = display.get_clipboard();
				clipboard.set_content(provider);
			} catch (Error e) {
				files.writeToLog(e.message + "\n");	
			}
		#endif
			
		files.writeToLog("Clipboard set -> " + filename + "\n");
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
				new Settings(application, this, files);
				revealer.set_reveal_child(false);
				files.saveSettingsFile("revealer", "false");
			}
			return true;
		});

		var closeButton = new Gtk.Button.from_icon_name("window-close-symbolic");
		closeButton.clicked.connect(() => {
			revealer.set_reveal_child(false);
			files.saveSettingsFile("revealer", "false");
		});

		banner.append(label);
		banner.append(closeButton);

		revealer.set_child(banner);

		mainbox.append(revealer);

		revealer.set_reveal_child(true);
	}

	public void setSpinner(bool status) {
		if (status) {
			spinner.set_visible(true);
			spinner.start();

		} else {
			spinner.stop();
			spinner.set_visible(false);
		}
	}

	public void createDefaultFilter() {
		defaultfilter = new Gtk.CustomFilter((obj) => {
			var gif = obj as Gif;

			if (filter == "")
				return true;

			return gif.fileName.down().contains(filter);
		});

		filtered = new Gtk.FilterListModel(model, defaultfilter);

		filtered.items_changed.connect((position, removed, added) => {
			totalitems = filtered.get_n_items();
		});
	}

	public void createFavoriteFilter() {

		favoritesfilter = new Gtk.CustomFilter((obj) => {
			var gif = obj as Gif;
			return gif.isFavorite;
		});

		favoritesfiltered = new Gtk.FilterListModel(model, favoritesfilter);

		/*var favoritesslice = new Gtk.SliceListModel(
			favoritesfiltered,
			0,
			sliceSize
		);*/

		favoritesselection = new Gtk.SingleSelection(favoritesfiltered);
	}

	private void updateFavoriteButton(Gtk.Button button, Gif gif) {
		#if WINDOWS
			var image = new Gtk.Image.from_resource(
				gif.isFavorite
					? "/io/ricol03/gifpicker/icons/icons/hicolor/scalable/actions/starred-symbolic.svg"
					: "/io/ricol03/gifpicker/icons/icons/hicolor/scalable/actions/non-starred-symbolic.svg"
			);

			button.set_child(image);
		#else
			button.set_icon_name(
				gif.isFavorite
					? "starred-symbolic"
					: "non-starred-symbolic"
			);
		#endif
	}

	public void createTagsFilter() {

		tagsfilter = new Gtk.CustomFilter((obj) => {
			var gif = obj as Gif;

			if (gif == null)
				return false;
			
			bool matched = false;

			foreach (string tag in gif.tags) {
				foreach (string filtered in filterArray) {
					if (tag == filtered) {
						matched = true;
					}
				}
			}

			return matched;
		});

		tagsfiltered = new Gtk.FilterListModel(model, tagsfilter);

		/*var tagsslice = new Gtk.SliceListModel(
			tagsfiltered,
			0,
			sliceSize
		);*/

		tagsselection = new Gtk.SingleSelection(tagsfiltered);
	}

    public void setModel() {
		model.remove_all();

		foreach (var gif in gifList) {
			model.append(gif);
		}

		createDefaultFilter();
		createFavoriteFilter();
		createTagsFilter();

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

		files.writeToLog("Model set\n");
	}

    public void setWindowContent() {
		while(mainbox.get_last_child() != null)
			mainbox.remove(mainbox.get_last_child());

		searchbtn.set_sensitive(false);
		refreshbtn.set_sensitive(false);
		favoritebtn.set_sensitive(false);

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

		button.clicked.connect(() => {
			getFolder.begin();
	    });

		contentbox.set_valign(Gtk.Align.CENTER);

		contentbox.append(image);
		contentbox.append(text);
		contentbox.append(button);
		centerbox.set_center_widget(contentbox);

		mainbox.append(centerbox);

		files.writeToLog("window content set\n");
	}

    public async void getFolder() {
		files.setFolder(yield dialog.openFolderDialog(mainwindow));
		if (files.getFolder() != null) {
			hasindex = true;
			files.saveSettingsFile("path", files.getFolder().get_path());

			loadingFromFile();

			runMonitor();

			refreshState();
			refreshChecks();
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

		files.writeToLog("return to first page\n");
	}

	public void backPage() {
		offset -= sliceSize;
        slice.set_offset(offset);
 		grid.scroll_to(0, Gtk.ListScrollFlags.NONE, null);

		checkBackButton();
		checkNextButton((int)totalitems);

		files.writeToLog("back page\n");
	}

	public void nextPage() {
		offset += sliceSize;
        slice.set_offset(offset);
 		grid.scroll_to(0, Gtk.ListScrollFlags.NONE, null);

		checkBackButton();
		checkNextButton((int)totalitems);

		files.writeToLog("next page\n");
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
		if (searchbtn.get_active()) {
			search.set_search_mode(false);
			searchbtn.set_active(false);

			files.writeToLog("search mode inactive\n");
		} else {
			search.set_search_mode(true);
			searchbtn.set_active(true);

			files.writeToLog("search mode active\n");
		}
	}

	public void refreshFavoritePanel() {
		favoritesfilter.changed(Gtk.FilterChange.DIFFERENT);

		var panel = (Gtk.Box)stack.get_child_by_name("panel");

		if (panel.get_first_child() != null)
		    panel.remove(panel.get_first_child());

		if (favoritesselection.get_n_items() == 0) {
		    var label = new Gtk.Label(
		        "No favourites to show. Please, add favourite GIFs."
		    );

		    var messagebox = new Gtk.CenterBox();
		    messagebox.set_hexpand(true);
		    messagebox.set_vexpand(true);

		    var contentbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		    contentbox.set_valign(Gtk.Align.CENTER);

		    contentbox.append(label);

		    messagebox.set_center_widget(contentbox);

		    panel.append(messagebox);

		} else {
		    var favoritesview = new Gtk.GridView(
		        favoritesselection,
		        factory
		    );

		    favoritesview.set_min_columns(2);
		    favoritesview.set_max_columns(2);

		    var scrolled = new Gtk.ScrolledWindow();
		    scrolled.set_hexpand(true);
		    scrolled.set_vexpand(true);

		    scrolled.set_child(favoritesview);

		    panel.append(scrolled);
		}
	}

	public void toggleFavoritePanel() {
		if (favoritebtn.get_active()) {
		    stack.set_visible_child_name("main");

		    favoritebtn.set_active(false);

		    mainwindow.set_title("GIF Picker");

		    checkBackButton();
		    checkNextButton((int)totalitems);

		    searchbtn.set_sensitive(true);
		    refreshbtn.set_sensitive(true);
			filterbtn.set_sensitive(true);
		    menubtn.set_sensitive(true);
		} else {
		    stack.set_visible_child_name("panel");

		    favoritebtn.set_active(true);

		    mainwindow.set_title("Favourite list");

		    backbtn.set_sensitive(false);
		    nextbtn.set_sensitive(false);
		    searchbtn.set_sensitive(false);
		    refreshbtn.set_sensitive(false);
			filterbtn.set_sensitive(false);
		    menubtn.set_sensitive(false);

		    refreshFavoritePanel();
		}
	}

	// changes between the normal list mode and the filtered variant
	public void toggleTagsPanel(bool isActive) {
		if (!isActive) {
		    stack.set_visible_child_name("main");
			favoritebtn.set_sensitive(true);
			searchbtn.set_sensitive(true);

		    checkBackButton();
		    checkNextButton((int)totalitems);

		} else {
		    stack.set_visible_child_name("panel");
			favoritebtn.set_sensitive(false);
			searchbtn.set_sensitive(false);

			checkBackButton();
		    checkNextButton((int)totalitems);

		    refreshTagsPanel();
		}
	}

	// appends the fresh tag view to the main window
	public void refreshTagsPanel() {
		tagsfilter.changed(Gtk.FilterChange.DIFFERENT);

		var panel = (Gtk.Box)stack.get_child_by_name("panel");

		if (panel.get_first_child() != null)
		    panel.remove(panel.get_first_child());

		if (tagsselection.get_n_items() == 0) {
		    var label = new Gtk.Label(
		        "No filtered GIFs to show. Please, try a different tag query."
		    );

		    var messagebox = new Gtk.CenterBox();
		    messagebox.set_hexpand(true);
		    messagebox.set_vexpand(true);

		    var contentbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		    contentbox.set_valign(Gtk.Align.CENTER);

		    contentbox.append(label);

		    messagebox.set_center_widget(contentbox);

		    panel.append(messagebox);

		} else {
		    var tagsview = new Gtk.GridView(
		        tagsselection,
		        factory
		    );

		    tagsview.set_min_columns(2);
		    tagsview.set_max_columns(2);

		    var scrolled = new Gtk.ScrolledWindow();
		    scrolled.set_hexpand(true);
		    scrolled.set_vexpand(true);

		    scrolled.set_child(tagsview);

		    panel.append(scrolled);
		}
	}

	public void showNotification() {
		var notification = new Notification("GIF Picker");
		notification.set_body("GIF copied to clipboard.");

		application.send_notification(null, notification);
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
	// 		files.writeToLog("(createSysTrayIcon)" + e.message + "\n");
	// 	}
	// }

	public void createMenuOptions() {
		var menubox = new Menu();

		menubox.append("Settings", "app.settings");
		menubox.append("About", "app.about");
		menubox.append("Quit", "app.quit");

		menubtn = new Gtk.MenuButton() {
			icon_name = "open-menu-symbolic",
			primary = true,
		};
		menubtn.set_menu_model(menubox);
		menubtn.set_tooltip_markup("Menu");

		#if WINDOWS
			var refreshicon = new Gtk.Image.from_resource(
				"/io/ricol03/gifpicker/icons/icons/hicolor/scalable/actions/win/Gnome-view-refresh.svg"
			);

			refreshbtn = new Gtk.Button();
			refreshbtn.set_child(refreshicon);
		#else
			refreshbtn = new Gtk.Button() {
				icon_name = "reload-symbolic",
			};
		#endif
		refreshbtn.set_tooltip_markup("Refresh <span alpha='70%'>(Ctrl+R)</span>");

		#if WINDOWS
			var filtericon = new Gtk.Image.from_resource(
				"/io/ricol03/gifpicker/icons/icons/hicolor/scalable/actions/win/Gnome-emblem-documents.svg"
			);

			filterbtn = new Gtk.MenuButton();
			filterbtn.set_child(filtericon);

		#else
			filterbtn = new Gtk.MenuButton() {
				icon_name = "filter-symbolic",
			};
		#endif
		filterbtn.set_tooltip_markup("Filter <span alpha='70%'>(Alt+F)</span>");

		filterpopup = new Gtk.Popover();
		filterpopupbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 1);

		var scrolled = new Gtk.ScrolledWindow();
		scrolled.set_child(filterpopupbox);
		scrolled.set_max_content_height(145);
		scrolled.set_propagate_natural_height(true);
		scrolled.set_policy(
			Gtk.PolicyType.NEVER,
			Gtk.PolicyType.AUTOMATIC
		);

		filterpopup.set_child(scrolled);

		refreshChecks();

		filterbtn.popover = filterpopup;


		#if WINDOWS
			var searchicon = new Gtk.Image.from_resource(
				"/io/ricol03/gifpicker/icons/icons/hicolor/scalable/actions/win/System-search.svg"
			);

			searchbtn = new Gtk.ToggleButton();
			searchbtn.set_child(searchicon);

		#else
			searchbtn = new Gtk.ToggleButton() {
				icon_name = "search-symbolic",
			};
		#endif
		searchbtn.set_tooltip_markup("Search <span alpha='70%'>(Ctrl+S)</span>");


		#if WINDOWS
			var backicon = new Gtk.Image.from_resource(
				"/io/ricol03/gifpicker/icons/icons/hicolor/scalable/actions/win/Gnome-go-previous.svg"
			);

			backbtn = new Gtk.Button();
			backbtn.set_child(backicon);

		#else
			backbtn = new Gtk.Button() {
				icon_name = "back-symbolic",
			};
		#endif
		backbtn.set_tooltip_markup("Back <span alpha='70%'>(Alt+B)</span>");


		#if WINDOWS
			var nexticon = new Gtk.Image.from_resource(
				"/io/ricol03/gifpicker/icons/icons/hicolor/scalable/actions/win/Gnome-go-next.svg"
			);

			nextbtn = new Gtk.Button();
			nextbtn.set_child(nexticon);

		#else
			nextbtn = new Gtk.Button() {
				icon_name = "next-symbolic",
			};
		#endif
		nextbtn.set_tooltip_markup("Next <span alpha='70%'>(Alt+N)</span>");

		#if WINDOWS
			var favoriteicon = new Gtk.Image.from_resource(
				"/io/ricol03/gifpicker/icons/icons/hicolor/scalable/actions/win/Emblem-star.svg"
			);

			favoritebtn = new Gtk.ToggleButton();
			favoritebtn.set_child(favoriteicon);

		#else
			favoritebtn = new Gtk.ToggleButton() {
				icon_name = "starred-symbolic",
			};
		#endif
		favoritebtn.set_tooltip_markup("Favourite <span alpha='70%'>(Ctrl+F)</span>");

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

		files.writeToLog("menu options created\n");
	}

	public void refreshChecks() {

		string content = "";

		try {
			File file = files.checkFile("tags.conf");

			FileUtils.get_contents(file.get_path(), out content);

			// Remove all existing checkboxes
			var child = filterpopupbox.get_first_child();

			while (child != null) {
				Gtk.Widget? next = child.get_next_sibling();
				filterpopupbox.remove(child);
				child = next;
			}

			// Add the updated checkboxes
			if (content != "") {
				foreach (string line in content.split("\n")) {
					if (line.strip() == "")
						continue;

					var newcheck = new Gtk.CheckButton.with_label(line);

					newcheck.toggled.connect(() => {
						if (newcheck.active == true) {
							filterArray.add(newcheck.get_label());

							toggleTagsPanel(true);
						} else {
							filterArray.remove(newcheck.get_label());

							if (filterArray.is_empty)
								toggleTagsPanel(false);
							else
								toggleTagsPanel(true);
						}
                    });

					filterpopupbox.append(newcheck);
				}
			} else {
				var text = new Gtk.Label("  No tags defined. Define them in \"Settings\".  ");
					
				filterpopupbox.append(text);
				filterpopupbox.set_halign(Gtk.Align.CENTER);
				filterpopupbox.set_valign(Gtk.Align.CENTER);
			}

			files.writeToLog("Refreshed popup\n");

		} catch (Error e) {
			files.writeToLog(e.message);
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

	public Gtk.MenuButton getFilterBtn() {
		return filterbtn;
	}

	public string getConvertedName() {
		return convertedName;
	}
}