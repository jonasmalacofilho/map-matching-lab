import Config;
import def.io.*;
import def.network.*;
import def.network.LinkDirection;
import SimpleGeography;
import haxe.Json;
import haxe.unit.TestRunner;
import Lambda.*;
import mapMatching.*;
import Math.*;
import sys.FileSystem;
import sys.io.File;
import test.TestMatch;
using Lambda;

class Lab {

	var config:Config;
	var algoTests:Array<{ runner:TestRunner, tests:Array<TestMatch> }>;

	public
	function new( config:Config ) {
		this.config = config;
		if ( config.algorithms == null )
			config.algorithms = [ "Shrimp" ];

		algoTests = config.algorithms.map( initAlgo ).map( prepareAlgoTests );
	}

	public
	function run() {
		algoTests.iter( runTest );
	}

	function prepareAlgoTests( algo:MapMatchingAlgo ) {
		var runner = new TestRunner();
		var tests = [];

		for ( netSpec in config.networks ) {
			var network = readNetwork( netSpec );

			for ( setSpec in netSpec.problemSets ) {
				var tracks = readTracks( setSpec );
				var answers = readAnswers( setSpec );

				for ( track in tracks ) {
					var answer = answers.get( track.id ).map( network.links.get );

					var test = new TestMatch( algo, network, track.pathLog, answer );
					tests.push( test );

					runner.add( test );
				}

			}

		}
		return { runner:runner, tests:tests };
	}

	function runTest( algoTest ) {
		algoTest.runner.run();
		// TODO save debug info
	}

	function initAlgo( name:String ):MapMatchingAlgo {
		return switch ( name ) {
		case "Shrimp": new Shrimp();
		case all: throw 'Unsupported algorithm $name';
		};
	}

	function readNetwork( specs:NetworkSpecs ) {
		return _readNetwork( specs.files );
	}

	function readTracks( specs:ProblemSetSpecs ) {
		return readPathLogs( specs.trackFile );
	}

	function readAnswers( specs:ProblemSetSpecs ) {
		return readExpectedResults( specs.answerFile );
	}

	static
	function main() {
		var paths = Sys.args();
		if ( paths.length == 0 )
			paths = [ './lab.json' ];

		var labs = paths.map( File.getContent ).map( Json.parse ).map( Lab.new );

		labs.iter( function ( lab ) lab.run() );
	}

	// for ( test in tests ) {
	// 	function linkId( link ) return link.id;
	// 	trace( "network: " + test.networkName + " input: " + test.inputName + " algo: " + test.algoName );
	// 	trace( "expected: " + Lambda.map( test.expectedPath, linkId ) );
	// 	trace( "matched: " + Lambda.map( test.matchedPath, linkId ) );

	// 	var name = test.networkName + "/" + test.inputName + "_" + test.algoName;
	// 	File.saveContent( name + "_matchedPath.json", GeoJsonTools.toGeoJsonText( test.debugInformation.matchedMap ) );
	// 	File.saveContent( name + "_expectedPath.json", GeoJsonTools.toGeoJsonText( test.debugInformation.expectedMap ) );
	// }

	static
	function _readNetwork( paths:Array<String> ) {
		var network = new Network();
		var nodes = [];

		function dist( a:Node, b:Node ) {
			return sqrt( (a.x-b.x)*(a.x-b.x) + (a.y-b.y)*(a.y-b.y) );
		}

		function addNode( x:Float, y:Float ) {
			var node = new Node( x, y );
			for ( known in nodes )
				if ( dist( known, node ) < 1e-6 )
					throw "Overlapping nodes";
			nodes.push( node );
			return node;
		}

		function getNode( x:Float, y:Float ) {
			var query = new Node( x, y );
			for ( known in nodes )
				if ( dist( known, query ) < 1e-6 )
					return known;
			throw 'No node found for coordinates $x and $y';
		}

		function addLink( id, from, to, direction, inflections ) {
			if ( network.links.exists( id ) )
				throw 'Repeated link $id';
			var link = new Link( id, from, to, direction, inflections );
			network.links[link.id] = link;
			return link;
		}

		for ( path in paths ) {
			var geojson = Json.parse( File.getContent( path ) );
			var set = SimpleGeography.fromGeoJson( geojson );
			for ( feature in set.features ) {
				switch ( feature.geometry ) {
				case SinglePoint( point ):
					addNode( point.x, point.y );
				case LineString( points ):
					if ( points.length < 2 )
						throw "Bad number of coordinates for link (there should be at least 2 points)";
					var first = points[0];
					var last = points[points.length-1];
					var from = getNode( first.x, first.y );
					var to = getNode( last.x, last.y );
					var properties:{ id:Int, direction:Int } = feature.properties;
					var dir = switch ( properties.direction ) {
					case -1: OneWayReversed;
					case 0: TwoWay;
					case 1: OneWay;
					case all: throw 'Bad direction $all';
					};
					addLink( properties.id, from, to, dir, points.slice(1,points.length-2).map(toPoint) );
				}
			}
		}

		return network;
	}

	static
	function readPathLogs( path:String ) {
		var pathLogs:Array<{ id:Int, pathLog:Array<def.Point> }> = [];
		var geojson = Json.parse( File.getContent( path ) );
		var set = SimpleGeography.fromGeoJson( geojson );
		for ( feature in set.features ) {
			switch ( feature.geometry ) {
			case LineString( points ):
				var data:{ id:Int } = feature.properties;
				pathLogs.push( { id:data.id, pathLog:points.map( toPoint ) } );
			case all:
				trace( 'ignored feature with geometry of type $all' );
			}
		}
		return pathLogs;
	}

	static
	function readExpectedResults( path:String ) {
		var jsonText = File.getContent( path );
		var data:Array<{ id:Int, path:Array<Int> }> = haxe.Json.parse( jsonText );
		var expectedResults = new Map();
		for ( res in data )
			expectedResults[res.id] = res.path;
		return expectedResults;
	}

	static
	function toPoint( point:Point ) {
		return new def.Point( point.x, point.y );
	}

}
