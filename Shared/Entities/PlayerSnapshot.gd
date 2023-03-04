extends TimestampedData
class_name PlayerSnapshot

var player_position: Vector3
var player_angle: float
var head_angle: float

# Based on http://www.kehomsforge.com/tutorials/multi/gdMoreNetworking/part03
func encode():
	var encoded = PackedByteArray()
	encoded.resize(24)
	encoded.encode_u32(0, tick)
	encoded.encode_float(4, player_position.x)
	encoded.encode_float(8, player_position.y)
	encoded.encode_float(12, player_position.z)
	encoded.encode_float(16, player_angle)
	encoded.encode_float(20, head_angle)
	
	return encoded

func decode(data: PackedByteArray):
	self.tick = data.decode_u32(0)
	self.player_position.x = data.decode_float(4)
	self.player_position.y = data.decode_float(8)
	self.player_position.z = data.decode_float(12)
	self.player_angle = data.decode_float(16)
	self.head_angle = data.decode_float(20)
	return self
