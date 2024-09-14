package;

import SMParser;
using StringTools;

typedef LegacySection = {
	sectionNotes:Array<Array<Dynamic>>,
	lengthInSteps:Int,
	typeOfSection:Int,
	mustHitSection:Bool,
	bpm:Int,
	changeBPM:Bool,
	altAnim:Bool
}

typedef LegacyChart = {
	song:String,
	notes:Array<LegacySection>,
	bpm:Float,
	needsVoices:Bool,
	speed:Float,
	player1:String,
	player2:String
}

class SMToLegacy {
    public static function convert(smData:SMFile, ?difficulty:String){
		if (difficulty==null)
			difficulty = smData.difficulties[0];

		var theChart:LegacyChart = {
			song: smData.metadata.get("TITLE").toLowerCase().replace(" ", "-"),
			notes: [],
			bpm: smData.bpmChanges[0].bpm,
			needsVoices: false,
			speed: 3.0,
			player1: "bf",
			player2: "dad"
		}

		var timings = new Timings(smData.bpmChanges);
		var lastSex:Int = 0;
		var type = smData.notes.get(difficulty).type;
		var lastBPMChangeBeat = timings.getTiming(0).beat;
		for (note in smData.notes.get(difficulty).notes) {
			var beat = timings.getBeatForTime(note.time);

			var section:Int = Math.floor(beat / 4);
			for (i in lastSex...section + 1) {
				var sectionBeat = i * 4;
				var timing = timings.getTimingAtBeat(sectionBeat);
				if (theChart.notes[i] == null) {
					theChart.notes[i] = {
						sectionNotes: [],
						lengthInSteps: 16,
						typeOfSection: 0,
						mustHitSection: (type == 'dance-single'),
						bpm: Std.int(timing.bpm),
						changeBPM: timing.beat > lastBPMChangeBeat,
						altAnim: false
					}
					lastBPMChangeBeat = timing.beat;
				}
			}

			lastSex = section + 1;

			theChart.notes[section].sectionNotes.push([note.time, note.column, note.length]);
		}
	    	theChart.speed = smData.bpmChanges[0].bpm * Constants.CMOD_TO_FNF;
        return {
            "song": theChart,
			"generatedBy": Constants.generatedBy
        }
    }
}
