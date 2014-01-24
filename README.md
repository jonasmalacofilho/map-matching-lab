Map-matching lab
================
_A lab for developing and testing map-matching algorithms_


The problem
-----------

Retrace the path on a network from GPS tracks or other sources. Can also be used for retracing paths between alternative networks (for the same region).


Steps towards a solution
------------------------

### Path comparison and errors

We want to measure the error between a matched path and the expected result. For this we use the Levenstein distance between the two (align both paths and weight each missed or wrong link with 1).

### Checking if a solution is optimal

For this, we could use the area of the **complex** polygon formed by the two curves: input track and (reversed) matched path. But be careful, computing this area as if it was of a simple polygon will reduce how effective the check is and will only assert how "centered" the matched path to the input.

### Map-matching algorithms

#### TrImp3 and Shrimp

TrImp3 solves map-matching problems by computing multiple shortest paths between each input point. Shrimp is a simplified TrImp3 map-matching algorithm for testing purposes.

#### BlueSwiss

Map-matching with multiple shortest paths on the graphs of link fit to each input point.

The weird (temporary) codename comes from what I was eating at time I had the idea: a sandwich with blue cheese and a box of Lindt chocolates.

