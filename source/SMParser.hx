package;
using StringTools;
import haxe.ds.StringMap;
typedef SMNote = {
	time: Float,
	column: Int,
	length: Float,
	type: String,
	quant: Int,
	row: Float,
    beat: Float
}

typedef SMFile = {
	metadata: StringMap<String>,
	notes:StringMap<SMNoteData>,
	difficulties: Array<String>,
    bpmChanges:Array<BPMChange>
}

typedef SMNoteData = {
    difficulty: String,
    type:String,
    subtitle:String,
    radar: Array<Float>,
    chartmeter:Float,
    notes: Array<SMNote>,
}

class BPMChange {
    public var beat: Float = 0;
    public var time:Float = 0;
    public var bpm: Float = 0;
    public function new(beat:Float, bpm:Float){
        this.beat = beat;
        this.bpm = bpm;
    }
    public function getCrotchet()return 60 / bpm;
    public function getCrotchetMS()return getCrotchet() * 1000;
    public function getBeat(time:Float):Float{
        return time / getCrotchetMS();
    }
}

class Timings
{
    var timings:Array<BPMChange> = [];
    
    public function new(timings:Array<BPMChange>){
        timings.sort((a,b)->Std.int(a.beat - b.beat));
		this.timings.push(new BPMChange(timings[0].beat, timings[0].bpm));
		for (idx in 1...timings.length){
            var change = new BPMChange(timings[idx].beat, timings[idx].bpm);
            var lastChange = this.timings[idx - 1];
			change.time = lastChange.time + ((change.beat - lastChange.beat) * lastChange.getCrotchetMS());
			this.timings.push(change);
        }
    }
    
    public function getTiming(index:Int)return timings[index];
    public function removeTiming(index:Int)return timings.splice(index, 1);
    public function shiftTiming()return timings.shift();
    public function getTimingAtBeat(beat:Float){
        var lastChange = timings[0];
        for(timing in timings){
			if (beat >= timing.beat)
                lastChange = timing;
        }   

		return lastChange;
    }
	public function getTimingAtTime(time:Float) {
		var lastChange = timings[0];
		for (timing in timings) {
			if (time >= timing.time)
				lastChange = timing;
		}

		return lastChange;
	}
	public function getBeatForTime(time:Float) {
        var timing = getTimingAtTime(time);
		return timing.beat + ((time - timing.time) / timing.getCrotchetMS());
    }
    
}

class SMParser
{
	static function readNoteData(noteData:Array<String>, timings:Timings, ?offset:Float=0){
		var currentSection:Array<Array<String>> = [];
		var timeOffset:Float = 0;
		var holds:Array<Int> = [-1,-1,-1,-1];
		var exportedNotes:Array<SMNote> = [];
        var currentTiming = timings.shiftTiming();
		
        var stepCrotchet = currentTiming.getCrotchetMS() / 4;
		var sectionIndex:Int = 0;

		for(noteRow in noteData){
			if(noteRow == ',' || noteRow == ';'){
				var snap = currentSection.length;
				var snapTime = (stepCrotchet / (snap / 16));
				var lengthInRows = 192 / (snap - 1);
                var rowIndex:Int = 0;
				
				for(idx in 0...currentSection.length){
					var row:Float = (sectionIndex * 192) + (lengthInRows * rowIndex);
					var beat = row / 48;
					if (timings.getTiming(0) != null) {
						while (timings.getTiming(0) != null && beat >= timings.getTiming(0).beat) {
							currentTiming = timings.shiftTiming();
							stepCrotchet = currentTiming.getCrotchetMS() / 4;
							snapTime = (stepCrotchet / (snap / 16));
						}
					}
					var notes = currentSection[idx];
                    
					var beatOffset:Float = currentTiming.getBeat(offset);
					row -= beatOffset * 48;
					beat -= beatOffset;
                    
					var time = timeOffset + snapTime; // can prob do crotchet / (snap / 4)???
					timeOffset += snapTime;
					time -= offset;
					for(column in 0...notes.length){
						var note = notes[column];
						if(note == '1'){
							exportedNotes.push({
								time: time,
								column: column,
								length: 0,
								type: "tap",
								quant: snap,
								row: row,
                                beat: beat
							});
						} else if (note == '2'){
							exportedNotes.push({
								time: time,
								column: column,
								length: 0,
								type: "head", // dis shit a hold
								quant: snap,
								row: row,
                                beat: beat
							});
							holds[column] = exportedNotes.length - 1;
						} else if (note == '4') {
							exportedNotes.push({
								time: time,
								column: column,
								length: 0,
								type: "rollhead", // dis shit a roll
								quant: snap,
								row: row,
								beat: beat
							});
							holds[column] = exportedNotes.length - 1;
						}else if(note == '3'){
							if(holds[column] != -1){
								var noteData = exportedNotes[holds[column]];
								noteData.length = Math.abs(time - noteData.time);
								exportedNotes[holds[column]] = noteData;
								holds[column] = -1;
							}
						} else if (note == 'M') {
							exportedNotes.push({
								time: time,
								column: column,
								length: 0,
								type: "mine", // dis shit a MINE
								quant: snap,
								row: row,
                                beat: beat
							});
                        }
					}
					rowIndex++;
				}
				//timeOffset += snapTime * snap;
				sectionIndex++;
				currentSection = [];
			}else
				currentSection.push(noteRow.split(""));
		}
		return exportedNotes;

	}

	public static function readSM(file:String, adjustForOffset:Bool = true){
		var smFile:SMFile = {
			metadata: new StringMap<String>(),
			notes: new StringMap<SMNoteData>(),
            bpmChanges: [],
			difficulties: []
		}
		var readingNoteData = false;
		var noteFieldIndex = 0;
		var metaTitle:String = '';
		var metaValue:String = '';
		var isReadingMetadata:Bool = false;
		var rawData:Array<Dynamic> = [];

		var rawNoteData:StringMap<Array<Dynamic>> = new StringMap<Array<Dynamic>>();

		var noteData:Array<String> = [];
		var regex = ~/(\/\/).+/;
		for(data in file.split("\n")){
			data = regex.replace(data, "").trim();
			if(readingNoteData){
				
				var colon = data.split(":");
                if(noteFieldIndex >= 5)
					noteData.push(data);
                else
					rawData[noteFieldIndex] = colon[0];
                
				noteFieldIndex++;
                if(data == ';'){
					rawNoteData.set(rawData[2], rawData);
					smFile.difficulties.push(rawData[2]);
					rawData[5] = noteData;
					rawData = [];

                    readingNoteData = false;
                    noteFieldIndex = 0;
                    noteData = [];
                }
			}else if(isReadingMetadata){
				metaValue += data;
				if(metaValue.charAt(metaValue.length - 1) == ';'){
					isReadingMetadata = false;
					smFile.metadata.set(metaTitle, metaValue.substr(0, metaValue.length - 1));
					metaTitle = '';
					metaValue = '';
				}else
					metaValue += "\n";

			}else{
				var prefix = data.charAt(0);
				if(prefix == '#'){
                    var split = data.split(":");
					var name = split[0].substr(1);
					var data = split[1];
					if(name == 'NOTES')
						readingNoteData = true;
					else{
						metaTitle = name;
						if(data.charAt(data.length - 1) == ';'){
							smFile.metadata.set(name, data.substr(0, data.length - 1));
                        }else{
                            metaValue += data;
                            isReadingMetadata = true;
                        }
					}
				}
			}
		}
		var timingData:Array<BPMChange> = [];

        var bpmChanges = smFile.metadata.get("BPMS");
        for(str in bpmChanges.split(",")){
            var data = str.split("=");
            var beat:Float = Std.parseFloat(data[0]);
			var bpm:Float = Std.parseFloat(data[1]);
            timingData.push(new BPMChange(beat, bpm));
        }
		
        smFile.bpmChanges = timingData;
        var offset:Float = 0;
		if (adjustForOffset){
            offset = smFile.metadata.exists("OFFSET") ? Std.parseFloat(smFile.metadata.get("OFFSET")) * 1000 : 0;
            if(Math.isNaN(offset))
                offset = 0;
        }
        for(key in rawNoteData.keys()){
            var timings:Timings = new Timings(timingData);
			var daData = rawNoteData.get(key);
			var notes = readNoteData(daData[5], timings, offset);
            var radar:Array<Float> = [];
			var rawdar:Array<String> = daData[4].split(",");
			for (shit in rawdar){
                var r = Std.parseFloat(shit);
                if(!Math.isNaN(r))radar.push(r);
            }
			smFile.notes.set(key, {
				difficulty: key,
				type: daData[0],
                subtitle: daData[1],
				radar: radar,
				chartmeter: daData[3],
                notes: notes
            });
        }
		return smFile;
		
	}
}