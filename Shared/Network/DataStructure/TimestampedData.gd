extends Reference
class_name TimestampedData

var tick: int
var data

static func earlier_than(a, b):
	return a.tick < b.tick
