extends TimestampedData
class_name PlayerSnapshot

var player_position: Vector3
var player_angle: float
var head_angle: float

# Based on http://www.kehomsforge.com/tutorials/multi/gdMoreNetworking/part03
func encode():
	var encoded = PackedByteArray()
	
	encoded.append_array(NetEncoding.encode_4bytes(tick))
	encoded.append_array(NetEncoding.encode_12bytes(player_position))
	encoded.append_array(NetEncoding.encode_4bytes(player_angle))
	encoded.append_array(NetEncoding.encode_4bytes(head_angle))
	
	return encoded

func decode(data: PackedByteArray):
	self.tick = bytes_to_var(NetEncoding.HEADERS.int + data.subarray(0, 3))
	self.player_position = bytes_to_var(NetEncoding.HEADERS.vec3 + data.subarray(4, 15))
	self.player_angle = bytes_to_var(NetEncoding.HEADERS.float + data.subarray(16, 19))
	self.head_angle = bytes_to_var(NetEncoding.HEADERS.float + data.subarray(20, 23))
	return self
