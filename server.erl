-module(server).
-export([start/0]).

start() ->
  process_flag(trap_exit, true),
  Config = config:read('server.cfg'),
  register(config:get(servername, Config), self()),
  register(storage, spawn_link(storage, start, [500, config:get(clientlifetime, Config), config:get(dlqlimit, Config)])),
  register(msg_proc, spawn_link(msg_proc, start, [1000])),
  logger:create('NServer.log'),
  loop(config:get(lifetime, Config) * 1000, 0).

loop(Timeout, Index) ->
  receive
    {getmsgid, PID} ->
      PID ! Index,
      msg_proc ! {waitForMsg, Index},
      loop(Timeout, Index+1);
    {getmessages, PID} ->
      logger ! {debug, "Get message called."},
      storage ! {PID, getMsg},
      loop(Timeout, Index);
    {dropmessage, {Message, Number}} ->
      msg_proc ! {putMsg, Number, Message},
      loop(Timeout, Index)
  after Timeout ->
    exit(whyYouNoNeedMe)
  end.
