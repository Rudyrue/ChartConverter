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

		// detect the old format
		var oldFormat:Null<String> = null;
		try {
			var files = [oldChartFile];
			if (oldMetadataFile.length > 0)
				files.push(oldMetadataFile);
			oldFormat = FormatDetector.findFormat(files);
		}

		var parseFrom:String;
		if (oldFormat == null) // request manual typing if not found
		{
			Sys.println('Format to parse from:');
			parseFrom = waitForInput();
		}
		else // found a format, make sure its correct
		{
			Sys.println('Detected old format $oldFormat, write a another format if incorrect. (leave blank if correct)');
			var input = waitForInput();
			parseFrom = input.length > 0 ? input : oldFormat;
		}

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

		var errorOccured:Bool = false;

		// finally start converting
		try {
			Sys.println('Converting...');

			from.parser = Type.createInstance(from.formatData.handler, []);
			to.parser = Type.createInstance(to.formatData.handler, []);

			from.parser.fromFile(oldChartFile, oldMetadataFile, difficulty);
			to.parser.fromFormat(from.parser, difficulty);

			if (to.formatData.extension == 'json')
				cast(to.parser, BasicJsonFormat<Dynamic,Dynamic>).beautify = true;

			to.parser.save(newChartFile, newMetadataFile);
			Sys.println('Chart saved! "$newChartFile"');

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