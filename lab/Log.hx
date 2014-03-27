import haxe.PosInfos;

class Log {

	static
	var logFile:haxe.io.Output;

	static
	function getLog() {
		if ( logFile == null )
			logFile = sys.io.File.write("map_matching_lab.log", false);
		return logFile;
	}

	static
	function writeString(s:String) {
		getLog().writeString(s);
	}

	public static
	function debug(msg:Dynamic, ?pos:PosInfos) {
		writeString('$$$$  Debug...  from ${pos.fileName}:${pos.lineNumber}  $$$$\n\n$msg\n\n');
	}

	public static
	function warning(msg:Dynamic, ?pos:PosInfos) {
		writeString('$$$$  Warning!  from ${pos.fileName}:${pos.lineNumber}  $$$$\n\n$msg\n\n');
	}

}
