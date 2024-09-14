package;

import haxe.display.Display.Literal;
import haxe.ds.StringMap;
import SMParser;

typedef FNFEvent = {
    t:Float,
    e:String,
    v: StringMap<Dynamic>
}

typedef FNFNoteData = {
	t:Float,
	d:Int,
	l:Float,
    ?k:String
}

typedef FNFChart = {
    version:String,
    scrollSpeed:StringMap<Float>,
    events: Array<FNFEvent>,
	notes:StringMap<Array<FNFNoteData>>,
	?generatedBy:String
}

typedef FNFBPMChange = {
    t:Float, // time
    bpm:Float, // bpm 
    ?n:Float, // time sig numerator
    ?d:Float, // time sig denominator
    ?bt:Array<Int> // beat tuplets
}

typedef FNFPlayData = {
    album:String,
	stage: String,
	characters: StringMap<String>,
    songVariations:Array<String>,
	difficulties:Array<String> ,
	noteStyle: String
}

typedef FNFMetaData = {
    version:String,
    songName:String,
    artist:String,
    timeFormat:String,
    timeChanges: Array<FNFBPMChange>,
    looped: Bool,
    playData: FNFPlayData,
	?offsets: StringMap<Dynamic>,
    ?generatedBy:String
}

class SMToFNF {
    static final DEFAULT_PLAY_DATA:FNFPlayData = {
        album: "volume1",
        songVariations: [],
        difficulties: ["normal"],
        characters: [
            "player" => "bf",
            "opponent" => "dad",
            "girlfriend" => "gf"
        ],
        stage: "mainStage",
        noteStyle: "funkin"
    }
	public static function convert(smData:SMFile, ?difficulty:String) {
		// if difficulty is defined then we should only convert that difficulty and put into "normal"
        // otherwise just throw every difficulty in
        // maybe map Easy, Medium and Hard to the existing FNF difficulties
		var changes:Array<FNFBPMChange> = [];
        var difficulties = [];
		if (difficulty != null)
			difficulties = ['normal'];
		else{
			for (i in smData.difficulties){
				var diff = i.toLowerCase();
				if(diff == 'medium')diff='normal';
				difficulties.push(diff);
			}
		}

		var chart:FNFChart = {
            version: "2.0.0",
            scrollSpeed: new StringMap<Float>(),
            events: [],
			notes: new StringMap<Array<FNFNoteData>>(),
            generatedBy: Constants.generatedBy
        }

		for (d in difficulties)chart.scrollSpeed.set(d, smData.bpmChanges[0].bpm * Constants.CMOD_TO_FNF);

        var timings = new Timings(smData.bpmChanges);
        while(timings.getTiming(0) != null) {
			var timing = timings.shiftTiming();
            changes.push({
                t: timing.time,
                bpm: timing.bpm
            });
        }

		if(difficulty != null){
			var fnfNotes:Array<FNFNoteData> = [];
			for (note in smData.notes.get(difficulty).notes) {
				fnfNotes.push({
					t: note.time,
					d: note.column,
					l: note.length
				});
			}
			difficulty = difficulty.toLowerCase();

			chart.notes.set('normal', fnfNotes);
		}else{
			for (difficulty => noteData in smData.notes) {
				var fnfNotes:Array<FNFNoteData> = [];
				difficulty = difficulty.toLowerCase();
				if (difficulty == 'medium')
					difficulty = 'normal';
				for (note in noteData.notes) {
					fnfNotes.push({
						t: note.time,
						d: note.column,
						l: note.length
					});
				}
				chart.notes.set(difficulty, fnfNotes);
			}
		}
    


		var offset = smData.metadata.exists("OFFSET") ? Std.parseFloat(smData.metadata.get("OFFSET")) * 1000 : 0;
        if (Math.isNaN(offset))
            offset = 0;

		var offsets:Map<String, Dynamic> = [
            "instrumental" => offset,
            "altInstrumentals" => {},
            "vocals" => {}
		];
        return {
            metadata: {
                version: "2.2.1",
                songName: smData.metadata.get("TITLE"),
				artist: smData.metadata.exists("ARTIST") ? smData.metadata.get("ARTIST") : "Unknown",
                timeFormat: "ms",
                timeChanges: changes,
                looped: false,
				offsets: offsets,
				playData: {
					album: DEFAULT_PLAY_DATA.album,
					songVariations: DEFAULT_PLAY_DATA.songVariations,
					difficulties: difficulties,
					characters: DEFAULT_PLAY_DATA.characters,
					stage: DEFAULT_PLAY_DATA.stage,
					noteStyle: DEFAULT_PLAY_DATA.noteStyle
				},
				generatedBy: Constants.generatedBy
            },
            chart: chart
        }
    }
    
}
