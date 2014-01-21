package test;

import mapMatching.MapMatchingAlgo;
import def.*;
import def.io.*;
import def.network.*;
import haxe.unit.TestCase;
import GeoJson;

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
	var pathLog:PathLog;

	public
	var expectedPath:Path;

	public
	var matchedPath:Null<Path>;

	public
	var levenshteinDistance:Float;

	public
	var debugInformation:{ matchedMap:GJFeatureCol, expectedMap:GJFeatureCol };

	public
	function new( algo:MapMatchingAlgo, network:Network, pathLog:PathLog, expectedPath:Path ) {
		// init
		super();
		networkName = "";
		inputName = "";
		algoName = "";
		this.algo = algo;
		this.network = network;
		this.pathLog = pathLog;
		this.expectedPath = expectedPath;
	}

	override public
	function setup() {
		if ( matchedPath != null )
			return;

		// compute
		matchedPath = algo.matchPath( network, pathLog );

		// analyze
		levenshteinDistance = levenshteinAlign( expectedPath, matchedPath );
		debugInformation = { matchedMap:mapPath( matchedPath ), expectedMap:mapPath( expectedPath ) };

	}

	public
	function testMatch() {
		assertEquals( 0., levenshteinDistance );
	}

	function levenshteinAlign( expected:Path, matched:Null<Path> ) {
		var dist = function ( a, b ) return a==b ? 0 : 1;
		var skip = function ( a, b, c ) return 1;
		var al = NeedlemanWunsch.globalAlignment( array( expected ), ( matched != null ? array( matched ) : [] ), dist, skip );
		return al.distance;
	}

	function mapPath( path:Path ) {
		var col:GJFeatureCol = { features:[] };
		var pos = 0;
		for ( link in path ) {
			var from = { x:link.from.x, y:link.from.y, etc:null };
			var to = { x:link.to.x, y:link.to.y, etc:null };
			var feature = {
				geometry:GJLineString( [ from, to ] ),
				properties:{ linkId:link.id, posInPath:pos },
				id:pos
			}
			col.features.push( feature );
		}
		return col;
	}

}
