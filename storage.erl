-module(storage).
-export([start/1]).

start(CheckInterval) ->
  loop(dict:new(),[], 0, CheckInterval).

loop(Clients, Messages, Offset, CheckInterval) ->
  receive
    {putMsg, _, Msg} ->
      io:format("Inserting: ~s~n", [Msg]),
      {NewMsgs, NewOffset} = insertMessage(Messages, Msg, Offset),
      loop(deleteIdleClients(Clients, CheckInterval), NewMsgs, NewOffset, CheckInterval);
    {PID, getMsg} ->
      {NewClients, Msg} = getMessage(PID, Clients, Messages, Offset),
      PID ! Msg,
      loop(deleteIdleClients(NewClients, CheckInterval), Messages, Offset, CheckInterval)
  after CheckInterval ->
    loop(deleteIdleClients(Clients, CheckInterval), Messages, Offset, CheckInterval)
  end.

insertMessage(Msgs, Msg, Offset) ->
  Size = length(Msgs),
  if
    Size >= 1000 ->
      {lists:append(lists:seq(1,Size, Msgs), [Msg]), Offset+1};
    true ->
      {lists:append(Msgs, [Msg]), Offset}
  end.

deleteIdleClients(Clients, Timeout) ->
  dict:filter(fun(PID, [{_, LastSeen}]) ->
      LastSeen >= getUnixTimestamp(now()) - Timeout
    end,
    Clients).

getMessage(PID, Clients, Messages, Offset) ->
  Count = length(Messages),
  case dict:find(PID, Clients) of
    {ok, {Index, _}} when Count > Index ->
      {dict:update(PID, {Index+1, getUnixTimestamp(now())} ,Clients), {lists:nth(zeroOrGreater(Index - Offset+1), Messages), Index, Count >= Index}};
    error when Count > 0 ->
      {dict:append(PID, {1+Offset,getUnixTimestamp(now())}, Clients), {lists:nth(1,Messages), 0, Count >= 1}};
    _ ->
      {Clients,{"Already got every Message.", -1, true}}
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
