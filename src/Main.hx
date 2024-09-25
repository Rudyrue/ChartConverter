import moonchart.backend.FormatDetector;
import moonchart.backend.FormatData;
import moonchart.formats.BasicFormat;

import sys.io.File;
import sys.FileSystem;

using StringTools;

typedef ChartFile = {
	var ?formatData:FormatData;
	var ?parser:BasicFormat<{}, {}>;
}

class Main extends mcli.CommandLine {
	var from:ChartFile = {};
	var to:ChartFile = {};

	var oldChartFile:String;
	var oldMetadataFile:String;

	var newChartFile:String = 'converted-chart';
	var newMetadataFile:String = 'converted-metadata';

	public function runDefault() {
		FormatDetector.getList();

		// grab the chart
		Sys.println('Chart file:');
		var chart:String = waitForInput();

		if (chart.length == 0) {
			Sys.println('No chart file was specified.');
			return;
		}

		// grab the metadata
		Sys.println('Metadata file: (leave blank if there\'s none)');
		var metadata:String = waitForInput();

		// grab the old format
		Sys.println('Format to parse from:');
		var parseFrom:String = waitForInput();

		if (parseFrom.length == 0) {
			Sys.println('No format to parse from was specified.');
			return;
		}

		from.formatData = FormatDetector.getFormatData(parseFrom);
		if (from.formatData == null) {
			Sys.println('Format "$parseFrom" doesn\'t exist.');
			return;
		}

		// do file checks after we grab the old format
		// because of file extensions
		oldChartFile = '$chart.${from.formatData.extension}';
		
		if (!FileSystem.exists(oldChartFile)) {
			Sys.println('The chart file "$oldChartFile" doesn\'t exist.');
			return;
		}

		oldMetadataFile = metadata.length == 0 ? null : '$metadata.${from.formatData.metaFileExtension}';
		if (from.formatData.hasMetaFile == TRUE) {
			if (oldMetadataFile == null) {
				Sys.println('The format you\'re parsing from requires a metadata file, please specify one.');
				return;
			}

			if (!FileSystem.exists(oldMetadataFile)) {
				Sys.println('The metadata file "$oldMetadataFile" doesn\'t exist.');
				return;
			}
		}

		// grab the format to convert to
		Sys.println('Format to convert to:');
		var convertTo:String = waitForInput();

		if (convertTo.length == 0) {
			Sys.println('No format to convert to was specified.');
			return;
		}

		to.formatData = FormatDetector.getFormatData(convertTo);
		if (to.formatData == null) {
			Sys.println('Format "$convertTo" doesn\'t exist.');
			return;
		}

		// set the new file's extensions
		newChartFile += '.${to.formatData.extension}';
		newMetadataFile += '.${to.formatData.metaFileExtension}';

		// grab the difficulty
		Sys.println('Difficulty:');
		var difficulty:String = waitForInput();

		if (difficulty.length == 0) {
			Sys.println('No difficulty was specified.');
			return;
		}

		// finally start converting
		try {
			Sys.println('Converting...');

			from.parser = Type.createInstance(from.formatData.handler, []).fromFile(oldChartFile, oldMetadataFile, difficulty);
			to.parser = Type.createInstance(to.formatData.handler, []).fromFormat(from.parser, difficulty);

			final converted:FormatStringify = to.parser.stringify();

			// save the chart
			File.saveContent(newChartFile, converted.data);
			Sys.println('Chart saved! "$newChartFile"');

			// save the metadata if the format supports it
			if (to.formatData.hasMetaFile == TRUE || to.formatData.hasMetaFile == POSSIBLE) {
				File.saveContent(newMetadataFile, converted.meta);
				Sys.println('Metadata saved! "$newMetadataFile"');
			}

			// keep the window open for 3 seconds
			// so that the user can see the file names
			Sys.sleep(2);
		} catch(e:haxe.Exception) {
			Sys.println('Error occured while processing chart:\n\n$e');
			Sys.exit(0);
		}
	}

	inline static function waitForInput():String {
		final input:String = Sys.stdin().readLine().toString();
		Sys.println('');
		return input;
	}

	static public function main():Void new mcli.Dispatch(Sys.args()).dispatch(new Main());
}