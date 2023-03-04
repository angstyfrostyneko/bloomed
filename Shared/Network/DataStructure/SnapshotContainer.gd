extends RefCounted
class_name SnapshotContainer

var snapshots := []

func push_snapshot(snapshot: TimestampedData):
	if snapshots.size() == 0:
		snapshots.append(snapshot)
	else:
		var index = snapshots.bsearch_custom(snapshot,
			TimestampedData, 'earlier_than')
		if snapshots[index].tick == snapshot.tick:
			snapshots[index] = snapshot
		else:
			snapshots.insert(index, snapshot)

func pull_snapshot():
	if snapshots.size() == 0:
		return null
	var snapshot = snapshots.pop_front()
	return snapshot
