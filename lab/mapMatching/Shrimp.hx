package mapMatching;

import haxe.unit.TestCase;
import Lambda.*;
import Math.*;
import prim.Network;
import prim.Path;
import prim.Point;
import prim.Track;

/**
	Shrimp - Simplified TrImp3 map-matching algorithm
	Original TrImp algorithm (versions 0.x-3.x) by Jonas Malaco Filho, 2013.
**/
class Shrimp
implements MapMatchingAlgo {

	public
	var algorithmName(default,null):String;

	public
	function new() {
		algorithmName = "Shrimp";
	}

	public
	function matchPath( network:Network, track:Track ):Path {
		var g = prepareGraph( network );
		var points = array( track.points );
		
		traverseGraph( g, points );
		var path = rebuildPath( g, points );

		return path;
	}

	function prepareGraph( network:Network ) {
		// prepare storage
		var vertices = new Map<Node,Vertex>();
		var arcs = new Array<Arc>();

		// create initial state for all nodes and links
		for ( link in network.links ) {
			var from = vertices[link.from];
			if ( from == null )
				vertices[link.from] = from = { node:link.from, cost:0., parent:[] };
			var to = vertices[link.to];
			if ( to == null )
				vertices[ link.to ] = to = { node:link.to, cost:0., parent:[] };
			switch ( link.direction ) {
			case OneWay:
				arcs.push( { link:link, from:from, to:to, cost:linkLen( link ) } );
			case OneWayReversed:
				arcs.push( { link:link, from:to, to:from, cost:linkLen( link ) } );
			case TwoWay:
				arcs.push( { link:link, from:from, to:to, cost:linkLen( link ) } );
				arcs.push( { link:link, from:to, to:from, cost:linkLen( link ) } );
			}
		}

		return { vertices:vertices, arcs:arcs };
	}

	function traverseGraph( g:Graph, points:Array<Point> ) {
		for ( pos in 0...points.length ) {
			var point = points[pos];

			// point to node penalty
			var penFactor = ( pos == 0 || pos == points.length - 1 ) ? 1 : 2;
			// initial or last point
			for ( vertex in g.vertices )
				vertex.cost += penFactor*dist( vertex.node, point );
			
			// shortest-path on network
			// Bellman-Ford relaxation for simplicity
			var relaxed = false;
			do {
				relaxed = false;
				for ( arc in g.arcs ) {
					var tentative = arc.from.cost + arc.cost;
					if ( arc.to.cost > tentative ) {
						relaxed = true;
						arc.to.cost = tentative;
						arc.to.parent[pos] = arc;
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
				to = to.parent[pos].from;
			}
		}
		return path;
	}

	function dist( a:Point, b:Point ):Float {
		return sqrt( (a.x-b.x)*(a.x-b.x) + (a.y-b.y)*(a.y-b.y) );
	}

	function linkLen( link:Link ) {
		var len = 0.;
		var pre:Point = link.from;
		for ( infl in link.inflections ) {
			len += dist( pre, infl );
			pre = infl;
		}
		len += dist( pre, link.to );
		return len;
	}

}

private
typedef Vertex = {
	var node:Node;
	var cost:Float;
	var parent:Array<Arc>;
}

private
typedef Arc = {
	var link:Link;
	var from:Vertex;
	var to:Vertex;
	var cost:Float;
}

private
typedef Graph = {
	var vertices:Map<Node,Vertex>;
	var arcs:Array<Arc>;
}

@:access( mapMatching.Shrimp )
class TestShrimp
extends TestCase {

	var instance:Shrimp;

	override
	function setup() {
		instance = new Shrimp();
	}

	public
	function testPathReconstruction0() {
		var expected = [ 11, 12, 21, 22, 31, 32 ];
		var precedence =
		[
			// node id, link precedence list (by level)
			// each link has the id its .from vertex
			[33,null,null,32],
			[32,null,null,31],
			[31,null,null,22],
			[22,null,21,null],
			[21,null,12,null],
			[12,11,null,null],
			[11,null,null,null]
		];
		assertEquals( str( expected ), str( path( precedence, 33 ) ) );
	}

	public
	function testPathReconstruction1() {
		var expected = [ 11, 21, 31 ];
		var precedence =
		[
			// node id, link precedence list (by level)
			// each link has the id its .from vertex
			[32,null,null,31],
			[31,null,null,21],
			[21,11,null,null],
			[11,null,null,null]
		];
		assertEquals( str( expected ), str( path( precedence, 32 ) ) );
	}

	function graphIt( precedence:Array<Array<Null<Int>>> ) {
		// vertices
		var vs = new Map<Int,Vertex>();
		for ( v in precedence ) {
			var node = new Node( 0., 0. );
			var cost:Float = v[0]; // "id" saved in the cost
			vs[v[0]] = { node:node, cost:cost, parent:[] };
		}
		// arcs
		var arcs = new Array<Arc>();
		for ( v in precedence ) {
			for ( p in v.slice( 1 ) ) {
				if ( p == null )
					continue;
				var link = new Link( p, null, null, null, null );
				var arc = { link:link, from:vs[p], to:vs[v[0]], cost:0. };
				arcs.push( arc );
				vs[v[0]].parent.push( arc );
			}
		}
		// trace( arcs.map( function ( arc ) return '${arc.link.id} ${arc.from.cost} ${arc.to.cost}' ) );
		var vertices = new Map<Node,Vertex>();
		for ( v in vs )
			vertices[v.node] = v;
		return { vertices:vertices, arcs:arcs };
	}

	function path( precedence:Array<Array<Null<Int>>>, end:Int ) {
		var g = graphIt( precedence );
		var to = null;
		for ( v in g.vertices )
			if ( Math.abs( v.cost - end ) < .01 )
				to = v;
		if ( to == null )
			throw "Ops!";
		return array( instance.gpath( g, to ) ).map( function ( arc ) return arc.link.id );
	}

	function str( d:Dynamic ) {
		return Std.string( d );
	}

}
