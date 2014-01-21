package def.network;

import def.*;

class Network {

	public
	var links(default,null):Map<Id,Link>;

	public
	function new() {
		links = new Map();
	}
	
}
