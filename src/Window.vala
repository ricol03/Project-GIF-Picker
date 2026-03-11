/****
 * Window.vala - contains the main window logic
 * ricol03, 2026
 ****/

[GtkTemplate (ui = "/io/ricol03/gifpicker/window.ui")]
public class Window : Gtk.ApplicationWindow {
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
	Gdk.Cursor cursor = new Gdk.Cursor.from_name("pointer", null);
	private Gtk.StringList model = new Gtk.StringList(null);
	int currentCount = 0;
	
    public Window(Gtk.Application app) {
		Object (
			application: app
		);
		
		files.createFileIndex.begin("/home/ricol03/Imagens/GIFs", (obj, res) => {
			try {
				filePaths = files.createFileIndex.end(res);
			} catch (Error e) {
				warning(e.message);
			}
		});

		try {
			var bus = Bus.get_sync(BusType.SESSION);
			var tray = new Tray();
			
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
						new Variant("(s)", "io.ricol03.gifpicker"),
						DBusCallFlags.NONE,
						-1
					);
				},
				(conn, name) => { print("Name lost\n"); }
			);
			
		} catch (Error e) {
			warning(e.message);
		}

		var menubox = new Menu();

		menubox.append("Open File...", "app.open");
		menubox.append("Save File...", "app.save");
		menubox.append("Quit", "app.quit");

		var refreshbtn = new Gtk.Button() {
			icon_name = "reload-symbolic",
		};
		refreshbtn.set_tooltip_markup("Refresh");

		var filterbtn = new Gtk.Button() {
			icon_name = "filter-symbolic",
		};
		filterbtn.set_tooltip_markup("Filter");

		var searchbtn = new Gtk.MenuButton() {
			icon_name = "search-symbolic",
			primary = true,
		};
		searchbtn.set_tooltip_markup("Search");

		var menubtn = new Gtk.MenuButton() {
			icon_name = "open-menu-symbolic",
			primary = true,
		};
		menubtn.set_menu_model(menubox);
		menubtn.set_tooltip_markup("Menu");
		
		if (hasindex) {
			refreshbtn.set_action_name("app.refresh");
		} else {
			refreshbtn.set_sensitive(false);
			filterbtn.set_sensitive(false);
		}

		var headerbar = new Gtk.HeaderBar() {
			show_title_buttons = true
		};
		headerbar.pack_start(searchbtn);
		headerbar.pack_end(menubtn);
		headerbar.pack_end(filterbtn);
		headerbar.pack_end(refreshbtn);

		mainbox 	= new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		
		setWindowContent(null);

		mainwindow = new Gtk.ApplicationWindow(app) {
			child = mainbox,
			titlebar = headerbar,
			default_height = 500,
			default_width = 600,
			title = windowtitle
		};

		mainwindow.present();
    }

    public void setWindowContent(string[]? newfilepaths) {

		if (newfilepaths != null)
			filePaths = newfilepaths;

		if (hasindex) {
			warning(mainbox.get_first_child().get_name());
			mainbox.remove(mainbox.get_first_child());

			for (currentCount = 0; currentCount < 8; currentCount++) {
				model.append(filePaths[currentCount]);
			}

			var selection = new Gtk.SingleSelection(model);
			var factory = new Gtk.SignalListItemFactory();

			Gtk.Box content = null;

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

				listitem.set_child(box);
			});

			factory.bind.connect((obj) => {
				var listitem = (Gtk.ListItem)obj;
				var stringitem = (Gtk.StringObject)listitem.get_item();
				var filename = stringitem.get_string();

				var box = (Gtk.Box)listitem.get_child();

				var picture = (Gtk.Picture)box.get_first_child();
				var label = (Gtk.Label)box.get_last_child();

				gif.makeGifsSmall(picture, folder.get_path() + "/" + filename);

				label.set_label(filename);

				var gesture = new Gtk.GestureClick();
				gesture.pressed.connect((n_press, x, y) => {
					var file = File.new_for_path(folder.get_path() + "/" + filename);
					mainwindow.set_cursor(cursor);

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

				box.set_hexpand (true);
				box.set_vexpand (true);
				box.set_halign (Gtk.Align.FILL);
				box.set_valign (Gtk.Align.FILL);
			});

			factory.unbind.connect((obj) => {
				var listitem = (Gtk.ListItem)obj;
				var box = (Gtk.Box)listitem.get_child();
				var picture = (Gtk.Picture)box.get_first_child();

				picture.set_paintable(null);
				model.remove(0);
			});

			var grid = new Gtk.GridView (selection, factory);
			grid.set_min_columns (2);
			grid.set_max_columns (2);
			
			var scrolled = new Gtk.ScrolledWindow();
			scrolled.set_min_content_height(200);
			scrolled.set_hexpand(true);
			scrolled.set_vexpand(true);
			scrolled.set_child(grid);
			
			mainbox.append(scrolled);

			getAdjustment(scrolled);
		} else {
			centerbox 	= new Gtk.CenterBox();
			
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
				//getFolder.begin();

				// dev logic
				folder = File.new_build_filename("/home/ricol03/Imagens/GIFs");
				hasindex = true;
				setWindowContent(null);
		    });
						
			contentbox.set_valign(Gtk.Align.CENTER);
			
			contentbox.append(image);
			contentbox.append(text);
			contentbox.append(button);
			centerbox.set_center_widget(contentbox);
			
			mainbox.append(centerbox);
			
		}		
	}
	
    public async void getFolder() {
		try {
		    folder = yield dialog.openFolderDialog(mainwindow);
			if (folder != null) {
				hasindex = true;
				setWindowContent(null);
			}
		    messagebox();
		} catch (Error e) {
		    warning("No folder selected");
		}
	}

	public void getAdjustment(Gtk.ScrolledWindow scroll) {
		var adjustment = scroll.get_vadjustment();

		adjustment.value_changed.connect((obj) => {
			double value = adjustment.get_value();
			double upper = adjustment.get_upper();
			double page = adjustment.get_page_size();

			if (value + page >= upper - 200) {
				int current = currentCount;
				int end = current + 6;
				for (int i = current; i < end; i++) {
				    model.append(filePaths[i]);
				}

				currentCount = end;
			}
		});
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
		
		if (folder.get_basename () != null) {
			hasindex = true;
		}	
	}
}