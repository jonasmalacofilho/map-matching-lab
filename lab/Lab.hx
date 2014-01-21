import def.*;
import def.io.*;
import def.network.*;
import def.network.LinkDirection;
import GeoJson;
import haxe.unit.TestRunner;
import mapMatching.*;
import sys.FileSystem;
import test.TestMatch;
import sys.io.File;

import Lambda.*;
import Math.*;

class Lab {

	static
	function main() {
		var args = Sys.args();
		var path = args.length > 0 ? args.pop() : '.';

		var algos:Array<MapMatchingAlgo> = [ new Shrimp() ];

		var tests = [];
		var testRunner = new TestRunner();

		function discover( path ) {
			var nodesLocation = path + "/nodes.geojson";
			var linksLocation = path + "/links.geojson";
			var pathLogsLocation = path + "/pathLogs.geojson";
			var expectedResultsLocation = path + "/expectedResults.json";

			if ( FileSystem.exists( nodesLocation ) && FileSystem.exists( linksLocation ) ) {
				var network = readNetwork( [ nodesLocation, linksLocation ] );

				if ( FileSystem.exists( pathLogsLocation ) ) {
					var pathLogs = readPathLogs( pathLogsLocation );
					var expectedResults = null;

					if ( FileSystem.exists( expectedResultsLocation ) ) {
						expectedResults = readExpectedResults( expectedResultsLocation );
					}

					for ( input in pathLogs ) {
						for ( algo in algos ) {
							var expected = expectedResults[input.id];
							if ( expected == null )
								expected = [];

							var test = new TestMatch( algo, network, input.pathLog, expected.map( network.links.get ) );
							test.networkName = path;
							test.inputName = Std.string( input.id );
							test.algoName = Type.getClassName( Type.getClass( algo ) );
							tests.push( test );
							testRunner.add( test );
						}
					}
					
				}
			}

			for ( item in FileSystem.readDirectory( path ) )
				if ( FileSystem.isDirectory( path + "/" + item ) )
					discover( path + "/" + item );
		}

		discover( path );

		testRunner.run();

		for ( test in tests ) {
			function linkId( link ) return link.id;
			trace( "network: " + test.networkName + " input: " + test.inputName + " algo: " + test.algoName );
			trace( "expected: " + Lambda.map( test.expectedPath, linkId ) );
			trace( "matched: " + Lambda.map( test.matchedPath, linkId ) );

			var name = test.networkName + "/" + test.inputName + "_" + test.algoName;
			File.saveContent( name + "_matchedPath.json", GeoJsonTools.toGeoJsonText( test.debugInformation.matchedMap ) );
			File.saveContent( name + "_expectedPath.json", GeoJsonTools.toGeoJsonText( test.debugInformation.expectedMap ) );
		}

	}

	static
	function readNetwork( paths:Array<String> ) {
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
			var jsonText = File.getContent( path );
			var geojson = GeoJsonTools.parseGeoJsonText( jsonText );
			for ( feature in geojson.features ) {
				switch ( feature.geometry ) {
				case GJPoint( point ):
					addNode( point.x, point.y );
				case GJLineString( points ):
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
		var pathLogs:Array<{ id:Int, pathLog:Array<Point> }> = [];
		var jsonText = File.getContent( path );
		var geojson = GeoJsonTools.parseGeoJsonText( jsonText );
		for ( feature in geojson.features ) {
			switch ( feature.geometry ) {
			case GJLineString( points ):
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
	function toPoint( point:GJGeoPoint ) {
		return new Point( point.x, point.y );
	}

}
