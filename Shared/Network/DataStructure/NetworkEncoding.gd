extends Object
class_name NetEncoding

# Based on http://www.kehomsforge.com/tutorials/multi/gdMoreNetworking/part03

const HEADERS = {}

static func init_headers():
	HEADERS.bool = PoolByteArray(var2bytes(bool(false)).subarray(0, 6))
	HEADERS.int = PoolByteArray(var2bytes(int(0)).subarray(0, 3))
	HEADERS.float = PoolByteArray(var2bytes(float(0)).subarray(0, 3))
	HEADERS.vec3 = PoolByteArray(var2bytes(Vector3()).subarray(0, 3))
	HEADERS.col = PoolByteArray(var2bytes(Color()).subarray(0, 3))
	HEADERS.quat = PoolByteArray(var2bytes(Quat()).subarray(0, 3))

static func encode_4bytes(val):
	return var2bytes(val).subarray(4, 7)

# Encode a variable that uses 8 bytes (vector2)
static func encode_8bytes(val):
	return var2bytes(val).subarray(4, 11)

# Encode a variable that uses 12 bytes (vector3...)
static func encode_12bytes(val):
	return var2bytes(val).subarray(4, 15)

# Encode a variable that uses 16 bytes (quaternion, color...)
static func encode_16bytes(val):
	return var2bytes(val).subarray(4, 19)
