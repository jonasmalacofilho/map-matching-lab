package prim;

class Network {

	public
	var name:String;

	public
	var links(default,null):Map<Int,Link>;

	public
	function new( name:String ) {
		this.name = name;
		links = new Map();
	}
	
}

class Node
extends Point {

}

class Link {
	public
	var id:Int;

	public
	var from:Node;

	public
	var to:Node;

	public
	var direction:LinkDirection;

	public
	var inflections:Iterable<Point>;

	public
	function new( id, from, to, direction, inflections ) {
		this.id = id;
		this.from = from;
		this.to = to;
		this.direction = direction;
		this.inflections = inflections;
	}
}

enum LinkDirection {
	OneWay;
	OneWayReversed;
	TwoWay;
}


