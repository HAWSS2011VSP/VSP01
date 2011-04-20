-module(storage).
-export([start/1]).

start(CheckInterval) ->
  loop(dict:new(),dict:new(), 0, CheckInterval).

loop(Clients, Messages, Offset, CheckInterval) ->
  receive
    {PID, putMessage, ID, Msg} ->
      {NewMsgs, NewOffset} = insertMessage(Messages, Msg, Offset),
      loop(Clients, NewMsgs, NewOffset CheckInterval)
  after CheckInterval ->
    loop(Clients, Messages, Offset, CheckInterval)
  end.

insertMessage(Msgs, Msg, Offset) ->
  Size = dict:size(Msg),
  if
    Size >= 1000 ->
      {dict:append(Size, Msg, dict:erase(Offset,Msgs)), Offset+1}
    true ->
      {dict:append(Size, Msg, Msgs), Offset}
  end.
  
deleteIdleClients(Clients, Timeout) ->
  deleteIdleClients(Clients, Timeout, []).
  
deleteIdleClients([], Timeout, Result) -> 
  Result;
deleteIdleClients([Client|Rest], Timeout, Result) ->
  if
    Client