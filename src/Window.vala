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
	private Gtk.ApplicationWindow mainwindow;
	private string windowtitle = "GIF Picker";
	private Gtk.Box mainbox;
	private Gtk.CenterBox centerbox;
	//private Gtk.Box centerbox2;
	private bool hasindex = false;
	
    public Window(Gtk.Application app) {
		Object (
			application: app
		);
		
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

		var menubtn = new Gtk.MenuButton() {
			icon_name = "open-menu-symbolic",
			primary = true,
		};
		menubtn.set_menu_model(menubox);
		menubtn.set_tooltip_markup("Menu");
		
		var searchbtn = new Gtk.MenuButton() {
			icon_name = "search-symbolic",
			primary = true,
		};
		searchbtn.set_tooltip_markup("Search");

		var headerbar = new Gtk.HeaderBar() {
			show_title_buttons = true
		};
		headerbar.pack_start(searchbtn);
		headerbar.pack_end(menubtn);

		mainbox 	= new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		
		setWindowContent();

		mainwindow = new Gtk.ApplicationWindow(app) {
			child = mainbox,
			titlebar = headerbar,
			default_height = 500,
			default_width = 600,
			title = windowtitle
		};

		mainwindow.present();
    }
    
    public void setWindowContent() {
		if (hasindex) {
			mainbox.remove(mainbox.get_first_child());
			var content  = gif.makeGifs(mainwindow, folder.get_path() + "/1682466693678.gif", folder.get_path() + "/731142877979082823-1.gif");
			var contentbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
			
			content.set_vexpand(true);
			content.set_hexpand(true);
			contentbox.append(content);
			contentbox.set_hexpand(true);
			contentbox.set_vexpand(true);
			
			var scrolled = new Gtk.ScrolledWindow();
			scrolled.set_min_content_height(200);
			scrolled.set_hexpand(true);
			scrolled.set_vexpand(true);
			scrolled.set_child(contentbox);
			
			mainwindow.set_child(scrolled);
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
		    	folder = File.new_build_filename ("/home/ricol03/Imagens/GIFs");
				hasindex = true;
				setWindowContent();
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
				setWindowContent();
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