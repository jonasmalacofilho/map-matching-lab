import Config;
import haxe.Json;
import haxe.unit.TestRunner;
import Lambda.*;
import mapMatching.*;
import Math.*;
import prim.Network;
import prim.Path;
import prim.Point;
import prim.Track;
import SimpleGeography;
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

		algoTests = config.algorithms.map( prepareAlgoTests );
	}

	public
	function run() {
		algoTests.iter( runTest );
	}

	function prepareAlgoTests( algo:String ) {
		var runner = new TestRunner();
		var tests = [];

		for ( netSpec in config.networks ) {
			var network = readNetwork( netSpec );

			for ( setSpec in netSpec.problemSets ) {
				var tracks = readTracks( setSpec );
				var answers = readAnswers( setSpec );

				for ( track in tracks ) {
					var answer = answers.get( track.id ).map( network.links.get );

					var test = new TestMatch( initAlgo( algo ), network, track, answer );
					tests.push( test );

					runner.add( test );
				}

			}

		}
		return { runner:runner, tests:tests };
	}

	function runTest( algoTest:{ runner:TestRunner, tests:Array<TestMatch> } ) {
		algoTest.runner.run();

		for ( test in algoTest.tests ) {
			function linkId( link ) return link.id;
			var name = test.algo.algorithmName+"_"+test.network.name+"_"+test.track.setName+"_"+test.track.id;

			trace( "problem: " + name );
			trace( "expected: " + Lambda.map( test.expectedPath, linkId ) );
			trace( "matched: " + Lambda.map( test.matchedPath, linkId ) );

			File.saveContent( name + "_matchedPath.json", Json.stringify( SimpleGeography.toGeoJson( test.debugInformation.matchedMap ) ) );
			File.saveContent( name + "_expectedPath.json", Json.stringify( SimpleGeography.toGeoJson( test.debugInformation.expectedMap ) ) );
		}
	}

	function initAlgo( name:String ):MapMatchingAlgo {
		return switch ( name ) {
		case "Shrimp": new Shrimp();
		case all: throw 'Unsupported algorithm $name';
		};
	}

	function readNetwork( specs:NetworkSpecs ) {
		trace( specs );
		var network = new Network( specs.name );
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

		for ( path in specs.files ) {
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

	function readTracks( specs:ProblemSetSpecs ) {
		var tracks:Array<Track> = [];
		var geojson = Json.parse( File.getContent( specs.trackFile ) );
		var set = SimpleGeography.fromGeoJson( geojson );
		for ( feature in set.features ) {
			switch ( feature.geometry ) {
			case LineString( points ):
				var data:{ id:Int } = feature.properties;
				tracks.push( { setName:specs.name, id:data.id, points:points.map( toPoint ) } );
			case all:
				trace( 'ignored feature with geometry of type $all' );
			}
		}
		return tracks;
	}

	function readAnswers( specs:ProblemSetSpecs ) {
		var jsonText = File.getContent( specs.answerFile );
		var data:Array<{ id:Int, path:Array<Int> }> = haxe.Json.parse( jsonText );
		var expectedResults = new Map();
		for ( res in data )
			expectedResults[res.id] = res.path;
		return expectedResults;
	}

	static
	function main() {
		var paths = Sys.args();
		if ( paths.length == 0 )
			paths = [ './lab.json' ];

		var labs = paths.map( File.getContent ).map( Json.parse ).map( Lab.new );

		labs.iter( function ( lab ) lab.run() );
	}

	static
	function toPoint( point:Point ) {
		return new prim.Point( point.x, point.y );
	}

}
