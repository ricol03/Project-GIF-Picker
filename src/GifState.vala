/****
 * GifState.vala - contains the logic for gif frame states
 * ricol03, 2026
 ****/

public class GifState : Object {
    public uint timeout_id = 0;
    public Gdk.PixbufAnimation? animation = null;
    public Gdk.PixbufAnimationIter? iter = null;
    public string? filepath = null;

	public GifState(string aFilePath) {
		filepath = aFilePath;
	}
}