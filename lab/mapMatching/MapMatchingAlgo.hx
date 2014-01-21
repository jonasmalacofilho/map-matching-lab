package mapMatching;

import def.io.Path;
import def.io.PathLog;
import def.network.Network;

interface MapMatchingAlgo {

	public
	function matchPath( network:Network, pathLog:PathLog ):Path;

}
