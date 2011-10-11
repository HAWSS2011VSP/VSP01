-module(client).
-export([setup/1]).

setup(ServerAddress) ->
  process_flag(trap_exit, true),
  Config = config:read('client.cfg'),
  net_adm:ping(ServerAddress),
  logger:create(lists:concat([node(), ".log"])),
  timer:sleep(500),
  Server = global:whereis_name(config:get(servername, Config)),
  loop(Server, config:get(sendeintervall, Config) * 1000, 0).

loop(Server, Interval, 5) ->
  Server ! {getmessages, self()},
  logger ! {debug, "Getting a message."},
  receive
    {Msg, false} ->
      logger ! {debug, lists:concat(["Got message: ", Msg])},
      loop(Server, Interval, 5);
    {Msg, true} ->
      logger ! {debug, lists:concat(["Got message: ", Msg])},
      loop(Server, Interval, 0);
    X ->
      logger ! {debug, "Unknown error."}
  end;
loop(Server, Interval, Count) ->
  ID = getId(Server),
  Message = createMsg(ID),
  logger ! {debug, lists:concat(["Inserting message: ", Message])},
  Server ! {dropmessage, {Message, ID}},
  timer:sleep(Interval),
  loop(Server, Interval, Count + 1).

getId(Server) ->
  Server ! {getmsgid, self()},
  receive
    Num ->
      Num
  end.

createMsg(ID) ->
  lists:concat([node(), "-1-22-", utils:now_str(), ": This is Message Number ", integer_to_list(ID)]).

