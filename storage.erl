-module(storage).
-export([start/3]).

start(CheckInterval, Timeout, MaxSize) ->
  loop(dict:new(),[], 0, CheckInterval, Timeout, MaxSize).

loop(Clients, Messages, Offset, CheckInterval, Timeout, MaxSize) ->
  receive
    {putMsg, _, Msg} ->
      logger ! {debug, lists:concat(["Inserting: ", Msg])},
      {NewMsgs, NewOffset} = insertMessage(Messages, Msg, Offset, MaxSize),
      loop(deleteIdleClients(Clients, CheckInterval), NewMsgs, NewOffset, CheckInterval, Timeout, MaxSize);
    {PID, getMsg} ->
      {NewClients, Msg} = getMessage(PID, Clients, Messages, Offset),
      PID ! Msg,
      loop(deleteIdleClients(NewClients, CheckInterval), Messages, Offset, CheckInterval, Timeout, MaxSize)
  after CheckInterval ->
    loop(deleteIdleClients(Clients, Timeout), Messages, Offset, CheckInterval, Timeout, MaxSize)
  end.

insertMessage(Msgs, Msg, Offset, MaxSize) ->
  Size = length(Msgs),
  if
    Size >= MaxSize ->
      {lists:append(lists:sublist(Msgs,2,Size), [Msg]), Offset+1};
    true ->
      {lists:append(Msgs, [Msg]), Offset}
  end.

deleteIdleClients(Clients, Timeout) ->
  dict:filter(fun(PID, {_, LastSeen}) ->
      Delete = LastSeen =< getUnixTimestamp(now()) - Timeout,
      if
        Delete == true ->
          logger ! {debug, lists:concat(["Removing ", pid_to_list(PID), " from list."])},
          false;
        true ->
          true
        end
    end,
    Clients).

getMessage(PID, Clients, Messages, Offset) ->
  Count = length(Messages),
  case dict:find(PID, Clients) of
    {ok, {Index, _}} when Count > Index - Offset ->
      logger ! {debug, lists:concat(["Getting message nr. ", integer_to_list(Index), " for ", pid_to_list(PID)])},
      {dict:store(PID, {Index+1, getUnixTimestamp(now())} ,Clients), {lists:nth(zeroOrGreater(Index - Offset+1), Messages), false};
    error when Count > 0 ->
      logger ! {debug, lists:concat(["Inserting new client: ", pid_to_list(PID)])},
      {dict:store(PID, {1+Offset,getUnixTimestamp(now())}, Clients), {lists:nth(1,Messages), Count =< 1}};
    _ ->
      {Clients,{lists:concat(["Already got every Message. Offset: ", integer_to_list(Offset), " Count: ", integer_to_list(Count)]), true}}
  end.

zeroOrGreater(Number) ->
  if
    Number > 0 ->
      Number;
    true ->
      0
  end.


getUnixTimestamp({MegaSecs, Secs, _MicroSecs}) ->
    MegaSecs*1000000+Secs.
