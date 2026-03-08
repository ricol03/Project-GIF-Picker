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
			var contentbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
			
			foreach(var file in filePaths)
				warning("lista deles: " + file.to_string());

			for (int i = 0; i < filePaths.length; i++) {
				//warning(filePaths[i]);
				if (filePaths[i] == null)
					break;

				Gtk.Box content = null;
				if (filePaths[i+1] != null) {
					//warning("1 - " + filePaths[i] + " | " + filePaths[i+1]);
					content = gif.makeGifs(
						mainwindow,
						folder.get_path() + "/" + filePaths[i],
						folder.get_path() + "/" + filePaths[++i]
					);
				} else {
					//warning("2 - " + filePaths[i]);
					content = gif.makeGifs(
						mainwindow,
						folder.get_path() + "/" + filePaths[i],
						null
					);
				}

				//warning(i.to_string());

				content.set_vexpand(true);
				content.set_hexpand(true);
				contentbox.append(content);
			}

			contentbox.set_hexpand(true);
			contentbox.set_vexpand(true);
			
			var scrolled = new Gtk.ScrolledWindow();
			scrolled.set_min_content_height(200);
			scrolled.set_hexpand(true);
			scrolled.set_vexpand(true);
			scrolled.set_child(contentbox);
			
			mainbox.append(scrolled);
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