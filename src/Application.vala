/****
 * Application.vala - contains the application structure
 * ricol03, 2026
 ****/

using Gdk;

public class Application : Gtk.Application {
	private Dialogs dialog = new Dialogs();
	private Files files = new Files();
	private string[] filePaths = null;
 	private Window window;
    
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

		var refresh_action = new SimpleAction ("refresh", null);

		add_action(refresh_action);
		set_accels_for_action("app.refresh", new string[] {"<Control>r"});
		refresh_action.activate.connect(() => {
			files.createFileIndex.begin("/home/ricol03/Imagens/GIFs", (obj, res) => {
				try {
					filePaths = files.createFileIndex.end(res);
					window.setWindowContent(filePaths);
				} catch (Error e) {
					warning(e.message);
				}
			});
		});

		var back_action = new SimpleAction ("back", null);

		add_action(back_action);
		set_accels_for_action("app.back", new string[] {"<Control>b"});
		back_action.activate.connect(() => {
			window.backPage();
		});

		var next_action = new SimpleAction ("next", null);

		add_action(next_action);
		set_accels_for_action("app.next", new string[] {"<Control>n"});
		next_action.activate.connect(() => {
			window.nextPage();
		});

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