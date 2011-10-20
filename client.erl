-module(client).
-export([start/2, setup/2]).

setup(ServerAddress, Number) ->
  random:seed(now()),
  process_flag(trap_exit, true),
  Config = config:read('client.cfg'),
  net_adm:ping(ServerAddress),
  timer:sleep(500),
  Server = {config:get(servername, Config), ServerAddress},
  loop(Server, config:get(sendeintervall, Config) * 1000, 0, Number).

start(ServerAddress, Number) ->
  logger:create(lists:concat([node(), ".log"])),
  start_n(ServerAddress, Number).

start_n(_ServerAddress, 0) ->
  ok;
start_n(ServerAddress, Number) ->
  spawn(?MODULE, setup, [ServerAddress, Number]),
  io:format("Spawned client nr ~s~n", [integer_to_list(Number)]),
  start_n(ServerAddress, Number - 1).

loop(Server, Interval, 5, Number) ->
  Server ! {getmessages, self()},
  logger ! {debug, "Getting a message."},
  receive
    {Msg, false} ->
      logger ! {debug, lists:concat(["Got message: ", Msg])},
      loop(Server, Interval, 5, Number);
    {Msg, true} ->
      logger ! {debug, lists:concat(["Got message: ", Msg])},
      loop(Server, calculateNewInterval(Interval), 0, Number);
    _X ->
      logger ! {debug, "Unknown error."}
  end;
loop(Server, Interval, Count, Number) ->
  ID = getId(Server),
  Message = createMsg(ID, Number),
  logger ! {debug, lists:concat(["Inserting message: ", Message])},
  Server ! {dropmessage, {Message, ID}},
  timer:sleep(Interval),
  loop(Server, Interval, Count + 1, Number).

getId(Server) ->
  Server ! {getmsgid, self()},
  receive
    Num ->
      Num
  end.

calculateNewInterval(Interval) ->
  Increase = utils:bool_rand(),
  Value = trunc(max(Interval * 0.5, 1000)),
  if
    Increase ->
      Total = Interval + Value,
      logger ! {debug, lists:concat(["Setting ", integer_to_list(Total), " as new interval."])},
      Total;
    true ->
      Total = max(Interval - Value, 1000),
      logger ! {debug, lists:concat(["Setting ", integer_to_list(Total), " as new interval."])},
      Total
  end.

createMsg(ID, Number) ->
  lists:concat(["client", integer_to_list(Number), "@", hostname(), "-1-22-", utils:now_str(), ": This is Message Number ", integer_to_list(ID)]).

hostname() ->
  Split = re:split(atom_to_list(node()), "@"),
  binary_to_list(lists:nth(2,Split)).
