package test;

import haxe.unit.TestCase;
import mapMatching.MapMatchingAlgo;
import prim.Network;
import prim.Path;
import prim.Track;
import SimpleGeography;

import Lambda.*;

class TestMatch
extends TestCase {

	public
	var networkName:String;

	public
	var inputName:String;

	public
	var algoName:String;

	public
	var algo:MapMatchingAlgo;

	public
	var network:Network;

	public
	var track:Track;

	public
	var expectedPath:Path;

	public
	var matchedPath:Null<Path>;

	public
	var levenshteinDistance:Float;

	public
	var debugInformation:{ matchedMap:GeographySet, expectedMap:GeographySet };

	public
	function new( algo:MapMatchingAlgo, network:Network, track:Track, expectedPath:Path ) {
		// init
		super();
		networkName = "";
		inputName = "";
		algoName = "";
		this.algo = algo;
		this.network = network;
		this.track = track;
		this.expectedPath = expectedPath;
	}

	override public
	function setup() {
		if ( matchedPath != null )
			return;

		// compute
		matchedPath = algo.matchPath( network, track );

		// analyze
		levenshteinDistance = levenshteinAlign( expectedPath, matchedPath );
		debugInformation = { matchedMap:mapPath( matchedPath ), expectedMap:mapPath( expectedPath ) };

	}

	public
	function testMatch() {
		assertEquals( 0., levenshteinDistance );
	}

	function levenshteinAlign( expected:Path, matched:Null<Path> ) {
		var dist = function ( a:PathSegment, b:PathSegment ) return a.link == b.link && a.direction == b.direction ? 0 : 1;
		var skip = function ( a, b, c ) return 1;
		var al = NeedlemanWunsch.globalAlignment( array( expected ), ( matched != null ? array( matched ) : [] ), dist, skip );
		return al.distance;
	}

	function mapPath( path:Path ) {
		var col:GeographySet = { features:[] };
		var pos = 0;
		for ( seg in path ) {
			var from = { x:seg.link.from.x, y:seg.link.from.y, zs:null };
			var to = { x:seg.link.to.x, y:seg.link.to.y, zs:null };
			var shp = switch ( seg.direction ) {
			case FromTo: [ from, to ];
			case ToFrom: [ to, from ];
			};
			var feature = {
				geometry:LineString( shp ),
				properties:{ linkId:seg.link.id, posInPath:pos }
			}
			col.features.push( feature );
		}
		return col;
	}

}
