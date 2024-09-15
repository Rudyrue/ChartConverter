import moonchart.backend.FormatDetector;
import moonchart.backend.FormatData;
import moonchart.formats.BasicFormat;

import sys.io.File;
import sys.FileSystem;

using StringTools;

class Main extends mcli.CommandLine {
	final defaultDiff:String = 'normal';
	public function runDefault(?file:String, ?from:String, ?to:String, ?diff:String) {
		// basic error handling
		if (file == null) {
			Sys.println('No file specified.');
			return;
		}

		if (from == null) {
			Sys.println('No format to parse from was specified.');
			return;
		}

		if (to == null) {
			Sys.println('No format to parse to was specified.');
			return;
		}

		if (diff == null) {
			Sys.println('No difficulty was specified, defaulting to "$defaultDiff".');
			diff = defaultDiff;
		}

		Sys.println(FormatDetector.getList());

		// get the formats
		var oldFormatData:FormatData = FormatDetector.getFormatData(from);
		var newFormatData:FormatData = FormatDetector.getFormatData(to);

		var metadata:String = null;
		var files:Array<String> = [null, null];

		// most likely has a metadata file connected to it
		if (file.contains(',')) files = file.split(',');
		else files[0] = file;

		// more error handling
		if (!FileSystem.exists(files[0])) {
			Sys.println('Chart "${files[0]}" does not exist.');
			return;
		}

		if (oldFormatData.hasMetaFile == TRUE && files[1] == null) {
			Sys.println('Old format requires a metadata file, please specify one.');
			return;
		}

		if (files[1] != null && !FileSystem.exists(files[1])) {
			Sys.println('Metadata "${files[1]}" does not exist.');
			return;
		}

		// finally start converting
		Sys.println('Converting...');

		var fromFile:BasicFormat<{}, {}> = Type.createInstance(oldFormatData.handler, []).fromFile(files[0], files[1], diff);
		var toFile:BasicFormat<{}, {}> = Type.createInstance(newFormatData.handler, []).fromFormat(fromFile, diff);

		final converted:FormatStringify = toFile.stringify();

		final chartFilename:String = 'converted-chart.${newFormatData.extension}';
		final metadataFilename:String = 'converted-metadata.${newFormatData.metaFileExtension}';

		// save the chart
		File.saveContent(chartFilename, converted.data);
		Sys.println('Chart saved! "$chartFilename"');

		// save the metadata if there is one
		if (newFormatData.hasMetaFile == TRUE) {
			File.saveContent(metadataFilename, converted.meta);
			Sys.println('Metadata saved! "$metadataFilename"');
		}
	}

	static public function main():Void {
		FormatDetector.getList();
		new mcli.Dispatch(Sys.args()).dispatch(new Main());
	}
}