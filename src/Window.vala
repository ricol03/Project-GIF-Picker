/****
 * Window.vala - contains the main window logic
 * ricol03, 2026
 ****/

[GtkTemplate (ui = "/io/ricol03/gifpicker/window.ui")]
public class Window : Gtk.ApplicationWindow {
	private Dialogs dialog = new Dialogs();
	private Gif gif = new Gif();
	private Files files = new Files();
	private Gtk.ApplicationWindow main_window;
	private string windowtitle = "GIF Picker";
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

		var box = new Gtk.CenterBox();
		
		if (hasindex) {
			var content = gif.makeGifs("test", "test2");
		} else {
			var centerbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 3);
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
			
			centerbox.set_valign(Gtk.Align.CENTER);
			
			centerbox.append(image);
			centerbox.append(text);
			centerbox.append(button);
			box.set_center_widget(centerbox);
			
		}

		var scrolled = new Gtk.ScrolledWindow();
		scrolled.set_child(box);

		main_window = new Gtk.ApplicationWindow(app) {
			child = scrolled,
			titlebar = headerbar,
			default_height = 500,
			default_width = 600,
			title = windowtitle
		};

		main_window.present();
    }
}