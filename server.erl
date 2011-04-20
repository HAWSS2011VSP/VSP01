-module(server).
-export(start/1).

start(Timeout) ->
  net_kernel:start([server, shortnames]),
  process_flag(trap_exit, true),
  erlang:set_cookie(node(), double_chocolate),
  register(server, self()),
  register(storage, spawn_link(storage, start, [500])),
  register(msg_proc, spawn_link(msg_proc, start, [500])).