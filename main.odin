package main

import "core:fmt"
import "core:mem"
import "core:net"

import "h2"

u24_as_u32 :: proc(n: h2.U24) -> (out: u32) {
	return u32(transmute(u32be)[4]u8{0, n[0], n[1], n[2]})
}


main :: proc() {
	LISTEN_ADDR, ok := net.parse_endpoint("[::]:8084")
	if !ok {panic("ERROR")}

	backing := make([]u8, 2 * mem.Megabyte)
	recv_arena: mem.Arena
	mem.arena_init(&recv_arena, backing)
	recv_alloc := mem.arena_allocator(&recv_arena)

	listen_sock, err := net.listen_tcp(LISTEN_ADDR)
	if err != nil {
		panic(fmt.aprintf("%v", err))
	}

	current_frame_header: ^h2.Frame_Header
	conn_preface_present: bool
	conn_total_bytes_read: int
	conn_offset: int
	// client's SETTINGS values, indexed by ID; RFC 9113 6.5.2 defaults until the client sends its own
	conn_settings := #sparse[h2.Settings_Id]u32 {
		.HEADER_TABLE_SIZE       = h2.DEFAULT_HEADER_TABLE_SIZE, // 4096
		.ENABLE_PUSH             = 1,
		.MAX_CONCURRENT_STREAMS  = max(u32), // unlimited
		.INITIAL_WINDOW_SIZE     = h2.DEFAULT_INITIAL_WINDOW_SIZE, // 65535
		.MAX_FRAME_SIZE          = h2.SETTINGS_MAX_FRAME_SIZE_DEFAULT, // 16384
		.MAX_HEADER_LIST_SIZE    = max(u32), // unlimited
		.ENABLE_CONNECT_PROTOCOL = 0, // RFC 8441
		.NO_RFC7540_PRIORITIES   = 0, // RFC 9218
	}
	raw := make_slice([]u8, 2 * mem.Megabyte, recv_alloc)

	for {
		//   H2_PREFACE                  (24 bytes)
		//
		//   Frame_Header                (9 bytes)   type = .SETTINGS
		//     length     U24            (3)         = 18
		//     type       Frame_Type     (1)
		//     flags      Frame_Flags    (1)
		//     stream_id  u32be          (4)         = 0
		//   Settings payload            (18 bytes)  3 × { Settings_Id (2), value u32be (4) }
		//
		//   Frame_Header                (9 bytes)   type = .WINDOW_UPDATE, stream_id = 0
		//   Window_Update payload       (4 bytes)   increment u32be (top bit reserved, mask with STREAM_ID_MASK)
		//
		//   Frame_Header                (9 bytes)   type = .HEADERS, flags = {.END_STREAM, .END_HEADERS},
		// stream_id = 1
		//   Headers payload             (30 bytes)  HPACK block (length from Frame_Header)

		fmt.println("listen")
		conn, from, err := net.accept_tcp(listen_sock)
		if err != nil {
			panic(fmt.aprintf("%v", err))
		}

		bytes_read, recv_err := net.recv_tcp(conn, raw[conn_total_bytes_read:])
		conn_total_bytes_read += bytes_read

		if (!conn_preface_present && conn_total_bytes_read < 24) {
			continue
		}

		if (!conn_preface_present) {
			if h2.H2_PREFACE == string(raw[:24]) {
				conn_offset += 24
				conn_preface_present = true
			}
			if !conn_preface_present {panic("nah not h2")}
		}


		// loop over other frames
		for {
			if conn_offset == conn_total_bytes_read {break}
			if conn_offset > conn_total_bytes_read {panic("")}
			// read len(h2.Frame_Header) from ^sl[24]
			// equiv to raw[24:33]
			frame_head := (^h2.Frame_Header)(&raw[conn_offset]) // 9 bytes
			conn_offset += 9

			frame_head_len := int(u24_as_u32(frame_head.length))
			fmt.println(frame_head_len)
			frame_payload := raw[conn_offset:conn_offset + frame_head_len]
			conn_offset += frame_head_len

			when ODIN_DEBUG {fmt.println(frame_head)}
			when ODIN_DEBUG {fmt.println(frame_payload)}

			if frame_head.type == .SETTINGS {
				// we need to update the settings and send them in our response I think
				// count_settings := frame_head_len / 6
				// idx := 0
				// for {
				// 	if count_settings >= 0 {break}
				//
				//              frame_payload :=
				//
				// 	count_settings -= 1
				// }
				continue
			}
			if frame_head.type == .HEADERS {
				fmt.println("HEADERS")
				// HPACK-encoded headers. Continues in CONTINUATION frames unless END_HEADERS is set.


			}
			if frame_head.type == .WINDOW_UPDATE {
				fmt.println("window update (ignored)")
			}
			// if frame_head
		}


		if recv_err != nil {panic(fmt.aprintf("%v", err))}


		net.send_tcp(conn, transmute([]u8)OK_BODY)

		// fmt.println(transmute(string)raw)

		net.close(conn)
		mem.arena_free_all(&recv_arena)
	}

}
