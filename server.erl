-module(server).
-export([start/1]).

start(Timeout) ->
  net_kernel:start([server, shortnames]),
  process_flag(trap_exit, true),
  erlang:nodes(visible),
  register(server, self()),
  register(storage, spawn_link(storage, start, [500])),
  register(msg_proc, spawn_link(msg_proc, start, [1000])),
  loop(Timeout, 0).

loop(Timeout, Index) ->
  receive
    {PID, getMsgId} ->
      PID ! {msgId, Index},
      msg_proc ! {waitForMsg, Index},
      loop(Timeout, Index+1);
    {PID, getMsg} ->
      storage ! {PID, getMsg},
      loop(Timeout, Index);
    {PID, putMsg, MsgID, Msg} ->
      msg_proc ! {PID, putMsg, MsgID, Msg},
      loop(Timeout, Index)
  after Timeout ->
    exit(whyYouNoNeedMe)
  end.