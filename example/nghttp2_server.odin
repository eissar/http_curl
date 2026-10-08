package example

import nh2 "../nghttp2"
import "base:runtime"
import "core:c"
import "core:fmt"
import "core:net"

on_header :: proc "c" (
	s: ^nh2.nghttp2_session,
	f: ^nh2.nghttp2_frame,
	name: ^u8,
	namelen: c.size_t,
	value: ^u8,
	valuelen: c.size_t,
	flags: u8,
	ud: rawptr,
) -> i32 {
	context = runtime.default_context()
	fmt.printfln("%s: %s", ([^]u8)(name)[:namelen], ([^]u8)(value)[:valuelen])
	return 0
}

on_frame_recv :: proc "c" (s: ^nh2.nghttp2_session, f: ^nh2.nghttp2_frame, ud: rawptr) -> i32 {
	if f.hd.flags & u8(nh2.nghttp2_flag.END_STREAM) == 0 {return 0}
	status, ok := ":status", "200"
	nv := nh2.nghttp2_nv {
		name     = raw_data(status),
		value    = raw_data(ok),
		namelen  = len(status),
		valuelen = len(ok),
	}
	prd := nh2.nghttp2_data_provider {
		read_callback = read_body,
	}
	return nh2.submit_response(s, f.hd.stream_id, &nv, 1, &prd)
}

read_body :: proc "c" (
	s: ^nh2.nghttp2_session,
	id: i32,
	buf: ^u8,
	length: c.size_t,
	flags: ^u32,
	src: ^nh2.nghttp2_data_source,
	ud: rawptr,
) -> c.ssize_t {
	body := "TESTING"
	copy(([^]u8)(buf)[:length], body)
	flags^ |= u32(nh2.nghttp2_data_flag.EOF)
	return c.ssize_t(len(body))
}

main :: proc() {
	endpoint, _ := net.parse_endpoint("[::]:8084")
	listen_sock, _ := net.listen_tcp(endpoint)

	callbacks: ^nh2.nghttp2_session_callbacks
	nh2.session_callbacks_new(&callbacks)
	nh2.session_callbacks_set_on_header_callback(callbacks, on_header)
	nh2.session_callbacks_set_on_frame_recv_callback(callbacks, on_frame_recv)

	for {
		conn, _, _ := net.accept_tcp(listen_sock)
		session: ^nh2.nghttp2_session
		nh2.session_server_new(&session, callbacks, nil)
        // nh2.nghttp2_settings({.
		nh2.submit_settings(session, 0, nil, 0)

		buf: [4096]u8
		for nh2.session_want_read(session) != 0 {
			data: ^u8
			for n := nh2.session_mem_send(session, &data);
			    n > 0;
			    n = nh2.session_mem_send(session, &data) {
				net.send_tcp(conn, ([^]u8)(data)[:n])
			}
			n, _ := net.recv_tcp(conn, buf[:])
			if n <= 0 {break}
			nh2.session_mem_recv(session, &buf[0], uint(n))
		}

		nh2.session_del(session)
		net.close(conn)
	}
}

//  odin run example/nghttp2_server.odin -file
//  curl --http2-prior-knowledge http://localhost:8084/
