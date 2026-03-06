/****
 * Gif.vala - contains the logic for gif showing
 * ricol03, 2026
 ****/

public class Gif {
	private Gtk.Picture picture;
	private Gtk.Picture picture2;
	private File file;
	
	public Gif() {}
	
	public Gtk.Box makeGifs(string filePath1, string filePath2) {
		picture = new Gtk.Picture () {
			margin_start = 5,
			margin_end	 = 5	
		};
		picture2 = new Gtk.Picture () {
			margin_end	 = 5
		};
		
		var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 2);
		var animation = new Gdk.PixbufAnimation.from_file(filePath1);
		var animation2 = new Gdk.PixbufAnimation.from_file(filePath2);
		
		picture.set_paintable (Gdk.Texture.for_pixbuf (
			animation.get_static_image()
	    ));
	    	
	    picture2.set_paintable (Gdk.Texture.for_pixbuf (
			animation2.get_static_image()
	    ));
	
		box.append(picture);
		box.append(picture2);
		
		return box;
	}

}