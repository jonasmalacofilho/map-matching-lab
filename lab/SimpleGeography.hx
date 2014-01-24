private
typedef Container<A> = Array<A>;

typedef Point = {
	// x coordinate (or longitude)
	var x:Float;
	
	// y coordinate (or latitude)
	var y:Float;
	
	// more coordinates (z, ...)
	@:optional
	var zs:Container<Float>;
}

enum Geometry {
	// a point
	SinglePoint( point:Point );

	// a sequence of line segments
	LineString( points:Container<Point> );
}

typedef GeographyFeature = {
	// geometry
	var geometry:Geometry;
	
	// optional properties
	@:optional
	var properties:Dynamic;

	// optional style guidelines	
	@:optional
	var style:Dynamic;
}

enum CRS {
	// WGS84 CRS; x and y in decimal degrees and ?z in meters
	WGS84;
}

typedef GeographySet = {
	// feature set
	var features:Container<GeographyFeature>;

	// CRS
	// null -> WGS84
	// unused so far, only WGS84 supported
	@:optional
	var crs:CRS;
}

class SimpleGeography {

	public static
	function fromGeoJson( obj:Dynamic ):GeographySet {
		return readGeoJsonObject( obj );
	}

	public static
	function toGeoJson( set:GeographySet ):Dynamic {
		return geoJsonSet( set );
	}

	// GeoJson input helpers

	static
	function readGeoJsonObject( obj:Dynamic ):Dynamic {
		switch ( obj.type ) {
		case "FeatureCollection":
			return {
				features:obj.features.map( readGeoJsonObject ),
				set:WGS84
			};
		case "Feature":
			var feature = {
				geometry:readGeoJsonObject( obj.geometry ),
				properties:obj.properties,
			};
			if ( obj.id != null ) {
				feature.properties.GeoJsonId = obj.id;
			}
			return feature;
		case "Point":
			return SinglePoint( readGeoJsonPoint( obj.coordinates ) );
		case "LineString":
			return LineString( obj.coordinates.map( readGeoJsonPoint ) );
		case all:
			throw 'Unsupported GeoJson object $all';
		};
	}

	static
	function readGeoJsonPoint( xs:Array<Float> ):Point {
		if ( xs.length > 2 )
			return { x:xs[0], y:xs[1] };
		else
			return { x:xs[0], y:xs[1], zs:xs.slice( 2 ) };
	}

	// GeoJson output helpers

	static inline
	function geoJsonSet( set:GeographySet ):Dynamic {
		return {
			type:"FeatureCollection",
			features:set.features.map( geoJsonFeature )
		};
	}

	static
	function geoJsonFeature( feature:GeographyFeature ):Dynamic {
		return {
			type:"Feature",
			properties:feature.properties,
			geometry:geoJsonGeometry(feature.geometry)
		};
	}

	static
	function geoJsonGeometry( geometry:Geometry ):Dynamic {
		switch ( geometry ) {
		case SinglePoint( p ):
			return {
				type:"Point",
				coordinates:geoJsonPoint( p )
			};
		case LineString( ps ):
			return {
				type:"LineString",
				coordinates:ps.map( geoJsonPoint )
			};
		}
	}

	static
	function geoJsonPoint( point:Point ):Array<Float> {
		if ( point.zs != null )
			return [ point.x, point.y ].concat( point.zs );
		else
			return [ point.x, point.y ];
	}

}
