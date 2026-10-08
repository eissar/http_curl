package hpack

// RFC 7541 6.1-6.3: first bits of each header in an HPACK block.
// The remaining low bits of that byte start a number (row or size).
Continuation_Frame_Type :: enum u8 {
	INDEXED               = 0x80, // 1xxxxxxx  whole header = table row (7 bits)
	LITERAL_ADD_TO_TABLE  = 0x40, // 01xxxxxx  name row or 0 (6 bits), then value; save to dynamic table
	TABLE_SIZE_UPDATE     = 0x20, // 001xxxxx  new dynamic table size (5 bits)
	LITERAL_NEVER_INDEXED = 0x10, // 0001xxxx  name row or 0 (4 bits), then value; never save (secrets)
	LITERAL               = 0x00, // 0000xxxx  name row or 0 (4 bits), then value; don't save
}

// RFC 7541 5.2: huffman flag on the string length octet's high bit
HPACK_HUFFMAN_FLAG :: 0x80

// RFC 7541 4.1: size of an entry is name+value+32
HPACK_ENTRY_OVERHEAD :: 32

// RFC 7541 Appendix A: 61-entry static table
HPACK_STATIC_TABLE_LEN :: 61

// RFC 7541 Appendix A: HPACK static table, {name, value} pairs indexed from 1
HPACK_STATIC_TABLE :: [61][2]string {
	{":authority", ""},
	{":method", "GET"},
	{":method", "POST"},
	{":path", "/"},
	{":path", "/index.html"},
	{":scheme", "http"},
	{":scheme", "https"},
	{":status", "200"},
	{":status", "204"},
	{":status", "206"},
	{":status", "304"},
	{":status", "400"},
	{":status", "404"},
	{":status", "500"},
	{"accept-charset", ""},
	{"accept-encoding", "gzip, deflate"},
	{"accept-language", ""},
	{"accept-ranges", ""},
	{"accept", ""},
	{"access-control-allow-origin", ""},
	{"age", ""},
	{"allow", ""},
	{"authorization", ""},
	{"cache-control", ""},
	{"content-disposition", ""},
	{"content-encoding", ""},
	{"content-language", ""},
	{"content-length", ""},
	{"content-location", ""},
	{"content-range", ""},
	{"content-type", ""},
	{"cookie", ""},
	{"date", ""},
	{"etag", ""},
	{"expect", ""},
	{"expires", ""},
	{"from", ""},
	{"host", ""},
	{"if-match", ""},
	{"if-modified-since", ""},
	{"if-none-match", ""},
	{"if-range", ""},
	{"if-unmodified-since", ""},
	{"last-modified", ""},
	{"link", ""},
	{"location", ""},
	{"max-forwards", ""},
	{"proxy-authenticate", ""},
	{"proxy-authorization", ""},
	{"range", ""},
	{"referer", ""},
	{"refresh", ""},
	{"retry-after", ""},
	{"server", ""},
	{"set-cookie", ""},
	{"strict-transport-security", ""},
	{"transfer-encoding", ""},
	{"user-agent", ""},
	{"vary", ""},
	{"via", ""},
	{"www-authenticate", ""},
}
