package mapMatching;

import prim.Path;
import prim.Track;
import prim.Network;

interface MapMatchingAlgo {

	public
	var algorithmName(default,null):String;

	public
	function matchPath( network:Network, track:Track ):Path;

}
