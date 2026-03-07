/****
 * Files.vala - contains the logic for file indexing and management
 * ricol03, 2026
 ****/

public class Files {

	public Files() {}
	
	public async string[] createFileIndex(string folderPath) {
		
		File file = File.new_for_path(folderPath);
		string[] filePaths = null;

		try {
			var e = yield file.enumerate_children_async(FileAttribute.STANDARD_NAME, 0, Priority.DEFAULT);
			while (true) {
		        var files = yield e.next_files_async (10, Priority.DEFAULT);

		        if (files == null || files.length() == 0)
		            break;

		        foreach (var info in files)
		            filePaths += info.get_name();
		    }

        	yield e.close_async();

		} catch (Error e) {
			warning(e.message);
		}

		return filePaths;
	}
	
	public void getFiles(string filePath) {
		//var path = File.get_path(filePath);
		
		
	}
}