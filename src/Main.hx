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

class Main {
	static var from:ChartFile = {};
	static var to:ChartFile = {};

	static var oldChartFile:String;
	static var oldMetadataFile:String;

	static var newChartFile:String = 'converted-chart';
	static var newMetadataFile:String = 'converted-metadata';

	public static function main() {
		FormatDetector.getList();

		// grab the chart
		Sys.println('Chart file:');
		var chart:String = waitForInput();

		if (chart.length == 0) {
			close('No chart file was specified.');
		}

		// grab the metadata
		Sys.println('Metadata file: (leave blank if there\'s none)');
		var metadata:String = waitForInput();

		// grab the old format
		Sys.println('Format to parse from:');
		var parseFrom:String = waitForInput();

		if (parseFrom.length == 0) {
			close('No format to parse from was specified.');
		}

		from.formatData = FormatDetector.getFormatData(parseFrom);
		if (from.formatData == null) {
			close('Format "$parseFrom" doesn\'t exist.');
		}

		// do file checks after we grab the old format
		// because of file extensions
		oldChartFile = '$chart.${from.formatData.extension}';
		
		if (!FileSystem.exists(oldChartFile)) {
			close('The chart file "$oldChartFile" doesn\'t exist.');
		}

		oldMetadataFile = metadata.length == 0 ? null : '$metadata.${from.formatData.metaFileExtension}';
		if (from.formatData.hasMetaFile == TRUE) {
			if (oldMetadataFile == null) {
				close('The format you\'re parsing from requires a metadata file, please specify one.');
			}

			if (!FileSystem.exists(oldMetadataFile)) {
				close('The metadata file "$oldMetadataFile" doesn\'t exist.');
			}
		}

		// grab the format to convert to
		Sys.println('Format to convert to:');
		var convertTo:String = waitForInput();

		if (convertTo.length == 0) {
			close('No format to convert to was specified.');
		}

		to.formatData = FormatDetector.getFormatData(convertTo);
		if (to.formatData == null) {
			close('Format "$convertTo" doesn\'t exist.');
		}

		// set the new file's extensions
		newChartFile += '.${to.formatData.extension}';
		newMetadataFile += '.${to.formatData.metaFileExtension}';

		// grab the difficulty
		Sys.println('Difficulty:');
		var difficulty:String = waitForInput();

		if (difficulty.length == 0) {
			close('No difficulty was specified.');
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

		} catch(e:haxe.Exception) Sys.println('Error occured while processing chart:\n\n$e');
		
		close();
	}

	inline static function waitForInput():String {
		final input:String = Sys.stdin().readLine().toString();
		Sys.println('');
		return input;
	}

	static function close(?output:String) {
		if (output != null) Sys.println(output);
		Sys.sleep(5);
		Sys.exit(0);
	}
}