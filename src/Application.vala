/****
 * Application.vala - contains the application structure
 * ricol03, 2026
 ****/

using Gdk;

public class Application : Gtk.Application {
	private Dialogs dialog = new Dialogs();
	private Files files = new Files();
	private About about = new About();
	private string[] filePaths = null;
 	private Window window = null;
	private File folder;

	const string PORTAL_NAME = "org.freedesktop.portal.Desktop";
	const string PORTAL_PATH = "/org/freedesktop/portal/desktop";
	const string GLOBAL_SHORTCUTS_IFACE = "org.freedesktop.portal.GlobalShortcuts";

	private DBusConnection? bus;
	private string? session_handle;

    public Application() {
		Object (
			application_id: "io.ricol03.gif-picker",
			flags: ApplicationFlags.DEFAULT_FLAGS
		);
    }

    protected override void startup() {
		base.startup();

		var quit_action = new SimpleAction("quit", null);

		add_action(quit_action);
		set_accels_for_action("app.quit", new string[] {"<Control>q", "<Control>w"});
		quit_action.activate.connect(quit);

		var about_action = new SimpleAction("about", null);

		add_action(about_action);
		set_accels_for_action("app.about", new string[] {"<Control>o"});
		about_action.activate.connect(() => {
			about.createWindow(window);
		});

		var settings_action = new SimpleAction("settings", null);

		add_action(settings_action);
		set_accels_for_action("app.settings", new string[] {"<Control>s"});
		settings_action.activate.connect(() => {
			var settings = new Settings(this, window);
		});

		var refresh_action = new SimpleAction("refresh", null);

		add_action(refresh_action);
		set_accels_for_action("app.refresh", new string[] {"<Control>r"});
		refresh_action.activate.connect(() => {
			files.createFileIndex.begin(folder.get_path(), (obj, res) => {
				try {
					filePaths = files.createFileIndex.end(res);
					window.setGifList();
				} catch (Error e) {
					warning(e.message);
				}
			});
		});

		var back_action = new SimpleAction("back", null);

		add_action(back_action);
		set_accels_for_action("app.back", new string[] {"<Alt>b"});
		back_action.activate.connect(() => {
			window.backPage();
		});

		var next_action = new SimpleAction("next", null);

		add_action(next_action);
		set_accels_for_action("app.next", new string[] {"<Alt>n"});
		next_action.activate.connect(() => {
			window.nextPage();
		});

		var search_action = new SimpleAction("search", null);

		add_action(search_action);
		set_accels_for_action("app.search", new string[] {"<Control>s"});
		search_action.activate.connect(() => {
			window.toggleSearchBar();
		});

		//  var toggle_action = new SimpleAction("toggle", null);

		//  add_action(toggle_action);
		//  set_accels_for_action("app.toggle", new string[] {"<Alt>g"});
		//  toggle_action.activate.connect(() => {
		//  	var a = window.get_visible();

		//  	warning(a.to_string());
		//  	if (a)
    	//  		window.hide();
		//  	else
		//  		window.present();
		//  });
    }

    protected override void activate() {
		base.activate();

		files.createSettingsDirectory();
		files.createSettingsFile();

		window = new Window(this);
 	}
}