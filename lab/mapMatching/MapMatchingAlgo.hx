package mapMatching;

import prim.Path;
import prim.Track;
import prim.Network;

interface MapMatchingAlgo {

	public
	function matchPath( network:Network, track:Track ):Path;

}
