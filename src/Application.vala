/****
 * Application.vala - contains the application structure
 * ricol03, 2026
 ****/

using Gdk;

public class Application : Gtk.Application {
	private Dialogs dialog = new Dialogs();
 	private Gtk.ApplicationWindow window; 
    
    public Application() {
		Object (
			application_id: "io.ricol03.gif-picker",
			flags: ApplicationFlags.DEFAULT_FLAGS
		);
    }

    protected override void startup() {
		base.startup();

		var quit_action = new SimpleAction ("quit", null);

		add_action(quit_action);
		set_accels_for_action("app.quit", new string[] {"<Control>q", "<Control>w"});
		quit_action.activate.connect(quit);

		// var save_action = new SimpleAction ("save", null);

		// add_action(save_action);
		// set_accels_for_action("app.save", new string[] {"<Control>s"});
		// save_action.activate.connect(() => {
		// 	dialog.saveFileDialog(main_window, text_view);
		// });

		var open_action = new SimpleAction ("open", null);

		add_action(open_action);
		set_accels_for_action("app.open", new string[] {"<Control>o"});
		open_action.activate.connect(() => {
			dialog.openFolderDialog(window);
		});
    }

    protected override void activate() {
		base.activate();
 		window = new Window(this);
 	}
}