package prim;

import prim.Network;

typedef Path = Iterable<PathSegment>;

typedef PathSegment = {
	var direction:PathSegmentDirection;
	var link:Link;
}

enum PathSegmentDirection {
	FromTo;
	ToFrom;
}
