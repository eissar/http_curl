package h2

import "base:runtime"
import "core:fmt"

H2_PREFACE :: "PRI * HTTP/2.0\r\n\r\nSM\r\n\r\n" // len 24

// RFC 9113 4.1: frame header is 9 bytes (length 24, type 8, flags 8, stream id 31+1)
FRAME_HEADER_SIZE :: 9

// RFC 9113 6.5.2: SETTINGS_MAX_FRAME_SIZE defaults to 2^14 and may range 2^14 .. 2^24-1
SETTINGS_MAX_FRAME_SIZE_DEFAULT :: 16384
SETTINGS_MAX_FRAME_SIZE_MIN :: 16384
SETTINGS_MAX_FRAME_SIZE_MAX :: 16777215

// RFC 9113 6.9.2: default initial flow-control window is 2^16-1; window max is 2^31-1
DEFAULT_INITIAL_WINDOW_SIZE :: 65535
MAX_WINDOW_SIZE :: 2147483647

// RFC 7541 4.2: default HPACK dynamic table size is 4096 octets
DEFAULT_HEADER_TABLE_SIZE :: 4096

// RFC 9113 3.4: client connection preface length
H2_PREFACE_LEN :: 24

// RFC 9113 11.2: frame types
Frame_Type :: enum u8 {
	DATA          = 0x0,
	HEADERS       = 0x1,
	PRIORITY      = 0x2,
	RST_STREAM    = 0x3,
	SETTINGS      = 0x4,
	PUSH_PROMISE  = 0x5,
	PING          = 0x6,
	GOAWAY        = 0x7,
	WINDOW_UPDATE = 0x8,
	CONTINUATION  = 0x9,
}

// Frame flag bit positions; END_STREAM and ACK share bit 0 (per-frame meaning, RFC 9113 11.2)
Frame_Flag :: enum u8 {
	END_STREAM  = 0, // 0x1 (DATA/HEADERS)
	ACK         = 0, // 0x1 (SETTINGS/PING)
	END_HEADERS = 2, // 0x4 (HEADERS/PUSH_PROMISE/CONTINUATION)
	PADDED      = 3, // 0x8 (DATA/HEADERS/PUSH_PROMISE)
	PRIORITY    = 5, // 0x20 (HEADERS)
}

Frame_Flags :: bit_set[Frame_Flag;u8]

// RFC 9113 11.3 / RFC 8441 / RFC 9218: settings identifiers
Settings_Id :: enum u16 {
	HEADER_TABLE_SIZE       = 0x1,
	ENABLE_PUSH             = 0x2,
	MAX_CONCURRENT_STREAMS  = 0x3,
	INITIAL_WINDOW_SIZE     = 0x4,
	MAX_FRAME_SIZE          = 0x5,
	MAX_HEADER_LIST_SIZE    = 0x6,
	ENABLE_CONNECT_PROTOCOL = 0x8, // RFC 8441
	NO_RFC7540_PRIORITIES   = 0x9, // RFC 9218
}

// RFC 9113 11.4 / RFC 7541 6.1: error codes
Error_Code :: enum u32 {
	NO_ERROR            = 0x0,
	PROTOCOL_ERROR      = 0x1,
	INTERNAL_ERROR      = 0x2,
	FLOW_CONTROL_ERROR  = 0x3,
	SETTINGS_TIMEOUT    = 0x4,
	STREAM_CLOSED       = 0x5,
	FRAME_SIZE_ERROR    = 0x6,
	REFUSED_STREAM      = 0x7,
	CANCEL              = 0x8,
	COMPRESSION_ERROR   = 0x9,
	CONNECT_ERROR       = 0xa,
	ENHANCE_YOUR_CALM   = 0xb,
	INADEQUATE_SECURITY = 0xc,
	HTTP_1_1_REQUIRED   = 0xd,
}

// RFC 9113 4.1: stream identifier is 31 bits, high bit reserved
STREAM_ID_MASK :: 0x7fffffff

// [24]u8 len
// [8]u8 type = 0x01


read_frame :: proc() {

}

U24 :: distinct [3]u8

when ODIN_DEBUG {
	formatters: map[typeid]fmt.User_Formatter

	@(init)
	register_formatters :: proc "contextless" () {
		context = runtime.default_context()
		formatters = make(map[typeid]fmt.User_Formatter)
		fmt.set_user_formatters(&formatters)
		fmt.register_user_formatter(U24, proc(fi: ^fmt.Info, arg: any, verb: rune) -> bool {
			l := (^U24)(arg.data)^
			fmt.fmt_int(fi, u64(u32(l[0]) << 16 | u32(l[1]) << 8 | u32(l[2])), false, 64, verb)
			return true
		})
	}
}


// first 9 bytes
Frame_Header :: struct #packed {
	length:    U24, // 0-2  (no u24 type in Odin)
	type:      Frame_Type, // 3
	flags:     Frame_Flags, // 4
	stream_id: u32be, // 5-8
}
#assert(size_of(Frame_Header) == 9)

// Frame :: struct #all_or_none {
// 	_: Frame_Header,
// }

// just_read_headers :: proc(raw: ^[]u8) {
// 	fmt.println("try read headers")
// 	// for {
// 	// 	h := (^Frame_Header)(raw)^ // take the pointer?
// 	// }
// }
