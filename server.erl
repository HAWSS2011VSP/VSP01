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
    {getmsgid, PID} ->
      PID ! {msgId, Index},
      msg_proc ! {waitForMsg, Index},
      loop(Timeout, Index+1);
    {getmessages, PID} ->
      storage ! {PID, getMsg},
      loop(Timeout, Index);
    {dropmessage, {Message, Number}} ->
      msg_proc ! {putMsg, Number, Message},
      loop(Timeout, Index)
  after Timeout ->
    exit(whyYouNoNeedMe)
  end.
