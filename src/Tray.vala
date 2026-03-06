/****
 * Tray.vala - contains the logic for the tray icon and functionality
 * ricol03, 2026
 ****/

using GLib;

[DBus (name = "org.kde.StatusNotifierItem")]
public class Tray : Object {

    public string Category {
		get { return "ApplicationStatus"; } 
	}
	
	public string Id { 
		get { return "gif-picker"; } 
	}
	
	public string Status { 
		get { return "Active"; } 
	}
	
	public string IconName { 
		get { return "error"; } 
	}
	
	public string Title { 
		get { return "GIF Picker"; } 
	}
	
	public bool ItemIsMenu { 
		get { return false; } 
	}
	
	public ObjectPath Menu { 
		owned get { return new ObjectPath("/"); } 
	}

	public uint WindowId { 
		get { return 0; } 
	}
	
	public Variant ToolTip {
		owned get {
		    return new Variant(
		        "(sa(iiay)ss)",
		        "",
		        null,
		        "GIF Picker",
		        "GIF Picker"
		    );
		}
	}

    public Tray() {}
}