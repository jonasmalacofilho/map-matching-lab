typedef GJFeatureCol = {
	var features:Array<GJFeature>;
}

typedef GJFeature = {
	var geometry:Null<GJGeometry>;
	var properties:Null<Dynamic>;
	var id:Null<Dynamic>;
}

enum GJGeometry {
	GJPoint( point:GJGeoPoint );
	// multipoint
	GJLineString( points:Array<GJGeoPoint> );
	// multilinestring
	// polygon
	// multipolygon
	// geometrycollection
}

typedef GJGeoPoint = {
	var x:Float;
	var y:Float;
	var etc:Null<Array<Float>>;
}

class GeoJsonTools {

	public static
	function toGeoJsonText( col:GJFeatureCol ) {
		var json = writeFeatureCollection( col );
		return haxe.Json.stringify( json );
	}

	public static
	function parseGeoJsonText( jsonText:String ):GJFeatureCol {
		var x = haxe.Json.parse( jsonText );
		var obj:GJFeatureCol = parseObject( x );
		return obj;
	}

	static
	function parseObject( x:Dynamic ):Dynamic {
		var type:String = x.type;
		return switch ( type ) {
		case "Point":
			var pt:Array<Float> = x.coordinates;
			GJPoint( parsePointCoordinates( pt ) );
		case "LineString":
			var pts:Array<Array<Float>> = x.coordinates;
			GJLineString( pts.map( parsePointCoordinates ) );
		case "Feature":
			var id = null;
			try {
				id = x.id;
			}
			catch ( e:Dynamic ) {}
			{ geometry:parseObject( x.geometry ), properties:x.properties, id:id };
		case "FeatureCollection":
			var features:Array<Dynamic> = x.features;
			{ features:features.map( parseObject ) };
		case all:
			throw all;
		};
	}

	static
	function parsePointCoordinates( pt:Array<Float> ) {
		var point = { x:pt[0], y:pt[1], etc:( pt.length > 2 ? pt.slice(2) : null ) };
		return point;
	}

	static
	function writeFeatureCollection( col:GJFeatureCol ) {
		return {
			type:"FeatureCollection",
			features:col.features.map( writeFeature )
		};
	}

	static
	function writeFeature( feature:GJFeature ) {
		return {
			type:"Feature",
			geometry:writeGeometry( feature.geometry ),
			properties:feature.properties,
			id:feature.id,
		};
	}

	static
	function writeGeometry( geometry:GJGeometry ):Dynamic {
		return switch( geometry ) {
		case GJPoint( point ):
			{ type:"Point", coordinates:writeGJGeoPoint( point ) };
		case GJLineString( points ):
			{ type:"LineString", coordinates:points.map( writeGJGeoPoint ) };
		};
	}

	static
	function writeGJGeoPoint( point:GJGeoPoint ) {
		var basic = [ point.x, point.y ];
		if ( point.etc != null && point.etc.length > 0 )
			basic = basic.concat( point.etc );
		return basic;
	}

}
