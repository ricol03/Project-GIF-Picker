/****
 * Gif.vala - contains the logic for gif showing
 * ricol03, 2026
 ****/

public class Gif {
	
	public Gif() {}
	
	public Gtk.Box makeGifs(Gtk.ApplicationWindow mainwindow, string filePath1, string filePath2) {
		var file = File.new_for_path(filePath1);
		var file2 = File.new_for_path(filePath2);
		
		var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 2);
		
		if (file.query_exists()) {
			Gtk.Picture picture = new Gtk.Picture.for_file(file) {
				margin_top 	 = 5,
				margin_start = 5,
				margin_end	 = 5		
			};
			var animation = new Gdk.PixbufAnimation.from_file(filePath1);
			var iter = animation.get_iter(null);

			Timeout.add(iter.get_delay_time(), () => {
				if (iter.advance(null)) {
					picture.set_pixbuf(iter.get_pixbuf());
					return true;
				} else
					iter = animation.get_iter(null);
					
				return true;
			});
			
			box.append(picture);
		} else {
			return null;	
		}
		
		if (file2.query_exists()) {
			Gtk.Picture picture2 = new Gtk.Picture.for_file(file) {
				margin_top 	 = 5,
				margin_end	 = 5
			};

			var animation2 = new Gdk.PixbufAnimation.from_file(filePath2);
			var iter = animation2.get_iter(null);

			Timeout.add(iter.get_delay_time(), () => {
				if (iter.advance(null)) {
					picture2.set_pixbuf(iter.get_pixbuf());
					return true;
				} else
					iter = animation2.get_iter(null);
				
				return true;
			});
			
			box.append(picture2);
		} else {
			//box.set_size_request(mainwindow.get_size(Gtk.Orientation.HORIZONTAL) / 2, -1);
		}
			
		box.set_halign(Gtk.Align.CENTER);
		box.set_size_request(-1, 200);
		return box;
	}
}