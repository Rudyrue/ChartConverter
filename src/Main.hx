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

	// assumes the end-user won't put `.chartExtension` 
	// when inputting the chart and metadata file
	var assumeFileExtensions:Bool = true;

	public function runDefault(?chart:String, ?parseFrom:String, ?convertTo:String, ?difficulty:String) {
		FormatDetector.getList();

		Sys.println('Converting...\n');

		// in case the user forgets an arg when calling the executable
		// just basic error handling
		if (chart == null) {
			Sys.println('No file(s) specified.');
			return;
		}
	
		// load the format to parse from
		if (parseFrom == null) {
			Sys.println('No format to parse from was specified.');
			return;
		}

		from.formatData = FormatDetector.getFormatData(parseFrom);
		if (from.formatData == null) {
			Sys.println('Format "$parseFrom" doesn\'t exist.');
			return;
		}

		// load the format to convert to
		if (convertTo == null) {
			Sys.println('No format to convert to was specified.');
			return;
		}

		to.formatData = FormatDetector.getFormatData(convertTo);
		if (to.formatData == null) {
			Sys.println('Format "$convertTo" doesn\'t exist.');
			return;
		}

		if (difficulty == null) {
			Sys.println('No difficulty was specified.');
			return;
		}

		/////////////////////////////////////////////////////////////////////////////////////////////

		var files:Array<String> = [];

		// assume that there was a metadata file attached
		if (chart.contains(',')) files = chart.split(',');
		else files = [chart, null];

		if (assumeFileExtensions) {
			files[0] = '${files[0]}.${from.formatData.extension}';

			if (files[1] != null) {
				files[1] = '${files[1]}.${from.formatData.metaFileExtension}';
			}
		}

		// then check if the files exist
		if (!FileSystem.exists(files[0])) {
			Sys.println('The chart file "${files[0]}" doesn\'t exist.');
			return;
		}

		if (from.formatData.hasMetaFile == TRUE) {
			if (files[1] == null) {
				Sys.println('The format you\'re parsing from requires a metadata file, please specify one.');
				return;
			}

			if (!FileSystem.exists(files[1])) {
				Sys.println('The metadata file "${files[1]}" doesn\'t exist.');
				return;
			}
		}

		// finally start converting
		try {
			from.parser = Type.createInstance(from.formatData.handler, []).fromFile(files[0], files[1], difficulty);
			to.parser = Type.createInstance(to.formatData.handler, []).fromFormat(from.parser, difficulty);

			final chartFileName:String = 'converted-chart.${to.formatData.extension}';
			final metadataFileName:String = 'converted-metadata.${to.formatData.metaFileExtension}';
			final converted:FormatStringify = to.parser.stringify();

			// save the chart
			File.saveContent(chartFileName, converted.data);
			Sys.println('Chart saved! "$chartFileName"');

			// save the metadata if the format supports it
			if (to.formatData.hasMetaFile == TRUE || to.formatData.hasMetaFile == POSSIBLE) {
				File.saveContent(metadataFileName, converted.meta);
				Sys.println('Metadata saved! "$metadataFileName"');
			}
		} catch(e:haxe.Exception) {
			Sys.println('Error occured while processing chart:\n$e');
			Sys.exit(0);
		}
	}

	static public function main():Void new mcli.Dispatch(Sys.args()).dispatch(new Main());
}