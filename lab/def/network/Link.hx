package def.network;

import def.*;

class Link {
	public
	var id:Id;

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
