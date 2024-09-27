// sucks that i have to make a script for this
// but whatever lmao

import sys.FileSystem.*;

class MoveFile {
	static var oldDir:String = 'export';
	static var newDir:String = 'export/bin';

	static var appName:String = 'ChartConverter.exe';

	static var newPath:String = '$newDir/$appName';

	public static function main() {
		if (exists(newDir)) {
			if (exists(newPath)) deleteFile(newPath);
		} else createDirectory('$newDir');

		rename('$oldDir/$appName', newPath);
	}
}