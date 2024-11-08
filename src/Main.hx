import moonchart.backend.FormatDetector;
import moonchart.backend.FormatData;
import moonchart.formats.BasicFormat;

import sys.io.File;
import haxe.Json;
import sys.FileSystem;

using StringTools;

typedef ChartFile = {
	var ?formatData:FormatData;
	var ?parser:DynamicFormat;
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
		oldChartFile = waitForInput();

		if (oldChartFile.length == 0) {
			close('No chart file was specified.');
		}

		if (!FileSystem.exists(oldChartFile)) {
			close('The chart file "$oldChartFile" doesn\'t exist.');
		}

		// grab the metadata
		Sys.println('Metadata file: (leave blank if there\'s none)');
		oldMetadataFile = waitForInput();

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
		
		if (from.formatData.hasMetaFile == TRUE) {
			if (oldMetadataFile.length == 0) {
				close('The format you\'re parsing from requires a metadata file, please specify one.');
			}

			if (!FileSystem.exists(oldMetadataFile)) {
				close('The metadata file "$oldMetadataFile" doesn\'t exist.');
			}
		} else oldMetadataFile = null;

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

		// grab the difficulty
		Sys.println('Difficulty:');
		var difficulty:String = waitForInput();

		if (difficulty.length == 0) {
			close('No difficulty was specified.');
		}

		// set the new file's extensions
		newChartFile += '.${to.formatData.extension}';
		newMetadataFile += '.${to.formatData.metaFileExtension}';

		var errorOccured:Bool = false;

		// finally start converting
		try {
			Sys.println('Converting...');

			from.parser = Type.createInstance(from.formatData.handler, []).fromFile(oldChartFile, oldMetadataFile, difficulty);
			to.parser = Type.createInstance(to.formatData.handler, []).fromFormat(from.parser, difficulty);

			// using reflect instead
			// because `parser`'s default type is `BasicFormat<{}, {}>`
			// and not `BasicJsonFormat<D, M>`

			// also setting the `formatting` var directly
			// because `beautify` is basically inlined
			// since it's both a getter and a setter inside of an abstract
			// which is why you get the error `Invalid field:beautify` if you try setting it with reflect
			if (to.formatData.extension == 'json') Reflect.setProperty(to.parser, 'formatting', "\t"); //to.parser.beautify = true;

			final converted:FormatStringify = to.parser.stringify();

			// save the chart
			File.saveContent(newChartFile, converted.data);
			Sys.println('Chart saved! "$newChartFile"');

			// save the metadata if the format supports it
			if (to.formatData.hasMetaFile == TRUE || to.formatData.hasMetaFile == POSSIBLE) {
				File.saveContent(newMetadataFile, converted.meta);
				Sys.println('Metadata saved! "$newMetadataFile"');
			}

		} catch(e:haxe.Exception) {
			Sys.println('Error occured while processing chart:\n\n$e');
			errorOccured = true;
		}

		close(errorOccured ? 5 : 2);
	}

	inline static function waitForInput():String {
		final input:String = Sys.stdin().readLine().toString();
		Sys.println('');
		return input;
	}

	static function close(?output:String, ?secondsToWait:Float = 5) {
		if (output != null) Sys.println(output);
		Sys.sleep(secondsToWait);
		Sys.exit(0);
	}
}