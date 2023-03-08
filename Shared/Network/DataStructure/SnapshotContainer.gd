extends RefCounted
class_name SnapshotContainer

var snapshots := []

func push_snapshot(snapshot: TimestampedData):
	if snapshots.size() == 0:
		snapshots.append(snapshot)
	else:
		snapshots.append(snapshot)
		#var index = snapshots.bsearch_custom(snapshot, func(x,y): TimestampedData.earlier_than(x,y))
		#if snapshots[index].tick == snapshot.tick:
		#	snapshots[index] = snapshot
		#else:
		#	snapshots.insert(index+1, snapshot)

func pull_snapshot():
	if snapshots.size() == 0:
		return null
	var snapshot = snapshots.pop_front()
	return snapshot
