package mapMatching;

import Lambda.*;
import Math.*;
import prim.Network;
import prim.Path;
import prim.Point;
import prim.Track;

class BlueSwiss
implements MapMatchingAlgo {

	// the idea is to weight arcs by their "distance" to the current gps point
	// and that's it, nothing more!

	public
	var algorithmName(default,null):String;

	public
	function new() {
		algorithmName = "BlueSwiss";
	}

	public
	function matchPath( network:Network, track:Track ):Path {
		var g = prepareGraph( network );
		var points = array( track.points );
		
		traverseGraph( g, points );
		var path = rebuildPath( g, points );

		return path;
	}

	function prepareGraph( network:Network ):Graph {
		// prepare storage
		var vertices = new Array<Vertex>();
		var arcs = new Map<Node,Arc>();

		// create initial state for all nodes and links
		for ( link in network.links ) {
			var from = arcs[link.from];
			if ( from == null )
				arcs[link.from] = from = { node:link.from, inc:[], out:[] };
			var to = arcs[link.to];
			if ( to == null )
				arcs[ link.to ] = to = { node:link.to, inc:[], out:[] };
			switch ( link.direction ) {
			case OneWay:
				var arc = { link:link, fit:Math.POSITIVE_INFINITY, cost:0., parent:[] };
				vertices.push( arc );
				from.out.push( arc );
				to.inc.push( arc );
			case OneWayReversed:
				var revArc = { link:link, fit:Math.POSITIVE_INFINITY, cost:0., parent:[] };
				vertices.push( revArc );
				to.out.push( revArc );
				from.inc.push( revArc );
			case TwoWay:
				var arc = { link:link, fit:Math.POSITIVE_INFINITY, cost:0., parent:[] };
				vertices.push( arc );
				from.out.push( arc );
				to.inc.push( arc );
				var revArc = { link:link, fit:Math.POSITIVE_INFINITY, cost:0., parent:[] };
				vertices.push( revArc );
				to.out.push( revArc );
				from.inc.push( revArc );
			}
		}

		return { vertices:vertices, arcs:array( arcs ) };
	}

	function traverseGraph( g:Graph, points:Array<Point> ) {
		for ( pos in 0...points.length ) {
			var point = points[pos];

			// link fit and point to link penalty
			for ( vertex in g.vertices ) {
				vertex.fit = linkFit( vertex.link, point );
				vertex.cost += vertex.fit;
			}
			
			// shortest-path on graph
			// Bellman-Ford relaxation for simplicity
			var relaxed = false;
			do {
				relaxed = false;
				for ( arc in g.arcs )
					for ( inc in arc.inc )
						for ( out in arc.out ) {
							if ( out.cost > inc.cost ) {
								relaxed = true;
								out.cost = inc.cost;
								out.parent[pos] = inc;
							}
						}
			} while ( relaxed );
		}
	}

	function rebuildPath( g:Graph, points:Array<Point> ) {
		// find the best path final (vertex)
		var to = null;
		var bestCost = Math.POSITIVE_INFINITY;
		for ( vertex in g.vertices ) {
			if ( vertex.cost < bestCost ) {
				to = vertex;
				bestCost = vertex.cost;
			}
		}

		// rebuild the path (on the graph) from precedence data
		var gp = gpath( g, to );

		// transform into `:Path` (`Iterable<Link>`)
		var p = gp.map( function ( arc ) return arc.link );

		return p;
	}

	function gpath( g:Graph, to:Vertex ) {
		var path = new List();
		var pos = to.parent.length;
		while ( --pos >= 0 ) {
			while ( to.parent[pos] != null ) {
				path.push( to.parent[pos] );
				to = to.parent[pos];
			}
		}
		return path;
	}

	function dist( a:Point, b:Point ):Float {
		return sqrt( (a.x-b.x)*(a.x-b.x) + (a.y-b.y)*(a.y-b.y) );
	}

	// simplified link distance to point
	function linkFit( link:Link, point:Point ) {
		var bestDist = Math.POSITIVE_INFINITY;
		var pre:Point = link.from;
		for ( infl in link.inflections ) {
			bestDist = Math.min( dist( pre, point ), bestDist );
		}
		bestDist = Math.min( dist( link.to, point ), bestDist );
		return bestDist;
	}

}

// a link
private
typedef Vertex = {
	var link:Link;
	var fit:Float;
	var cost:Float;
	var parent:Array<Vertex>;
}

// a node, connecting several links
private
typedef Arc = {
	var node:Node;
	var inc:Array<Vertex>;
	var out:Array<Vertex>;
}

private
typedef Graph = {
	var vertices:Iterable<Vertex>;
	var arcs:Iterable<Arc>;
}
