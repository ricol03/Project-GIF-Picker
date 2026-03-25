 /****
 * About.vala - contains the about window
 * ricol03, 2026
 ****/

public class About {
	private Gtk.AboutDialog about;

	public About() {}

	public void createWindow(Gtk.ApplicationWindow window) {
		about = new Gtk.AboutDialog();
		about.set_transient_for(window);
		about.set_modal(true);

		about.set_program_name("GIF Picker");
		about.set_version("0.1");
		about.set_comments("Easily accessible GIF picker for your local library");
		about.set_website("https://github.com/ricol03/Project-GIF-Picker");

		about.set_authors({ "ricol03" });

		about.present();
	}
}