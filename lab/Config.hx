typedef Config = {
	var algorithms:Null<Array<String>>; // null -> all
	var networks:Array<NetworkSpecs>;
}

typedef NetworkSpecs = {
	var name:String;
	var files:Array<String>; // paths to geojson files
	var problemSets:Array<ProblemSetSpecs>;
}

typedef ProblemSetSpecs = {
	var name:String;
	var trackFile:String; // path to geojson file
	var answerFile:String; // path to json file
}
