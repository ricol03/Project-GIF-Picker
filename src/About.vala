 /****
 * About.vala - contains the about window
 * ricol03, 2026
 ****/

public class About {
	private Gtk.AboutDialog about;
	private Files files;

	private string version = "0.3.1-dev";

	public About(Files files) {
		this.files = files;
	}

	public void createWindow(Gtk.ApplicationWindow window) {
		about = new Gtk.AboutDialog();
		about.set_transient_for(window);
		about.set_modal(true);

		about.set_program_name("GIF Picker");
		about.set_version(version);

		var texture = Gdk.Texture.from_resource(
			"/io/ricol03/gifpicker/icons/icons/hicolor/scalable/actions/gifpicker.png"
		);

		about.set_logo(texture);

		about.set_comments("Easily accessible GIF picker for your local library");
		about.set_website("https://github.com/ricol03/Project-GIF-Picker");

		about.set_authors({ "ricol03" });

		string[] people =
		{"Churo", "Wilhelm II", "Yubiyub", "Coro", "Unrealism", "merrit"};

		about.add_credit_section("Testing by", people);

		about.present();

		files.writeToLog("About window created\n");
	}
}