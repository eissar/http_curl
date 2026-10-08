package main
// HTTP/2 "200 OK, content-length: 7, TESTING" on stream 1, as raw frames.
// Each frame: length (3 bytes), type (1), flags (1), stream id (4), payload.
OK_BODY := []u8 {
	// SETTINGS (type 4), no flags, stream 0, empty: server preface
	0x00,
	0x00,
	0x00,
	0x04,
	0x00,
	0x00,
	0x00,
	0x00,
	0x00,
	// SETTINGS (type 4), ACK (flag 1), stream 0, empty: acknowledge client's SETTINGS
	0x00,
	0x00,
	0x00,
	0x04,
	0x01,
	0x00,
	0x00,
	0x00,
	0x00,
	// HEADERS (type 1), END_HEADERS (flag 4), stream 1, 5-byte HPACK block
	0x00,
	0x00,
	0x05,
	0x01,
	0x04,
	0x00,
	0x00,
	0x00,
	0x01,
	0x88, // indexed 8: :status: 200
	0x0F,
	0x0D,
	0x01,
	0x37, // literal, not indexed, name 28 (content-length), value "7"
	// DATA (type 0), END_STREAM (flag 1), stream 1, 7 bytes
	0x00,
	0x00,
	0x07,
	0x00,
	0x01,
	0x00,
	0x00,
	0x00,
	0x01,
	'T',
	'E',
	'S',
	'T',
	'I',
	'N',
	'G',
}
