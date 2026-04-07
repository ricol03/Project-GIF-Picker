/****
 * Gif.vala - contains the logic for gif showing
 * ricol03, 2026
 ****/

public class Gif {
	
	public Gif() {}
	
	public uint makeGifsSmall(Gtk.Picture picture, string filePath) {
		warning(filePath);
		var animation = new Gdk.PixbufAnimation.from_file(filePath);
		var iter = animation.get_iter(null);

		uint id = Timeout.add(iter.get_delay_time(), () => {
			if (iter.advance(null)) {
				var texture = Gdk.Texture.for_pixbuf(iter.get_pixbuf());
				picture.set_paintable(texture);
			}

			return true;
		});

		return id;
	}
}