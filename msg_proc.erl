-module(msg_proc).
-export([start/1]).


start(Timeout) ->
  loop(Timeout).

loop(Timeout) ->
  receive
    {waitForMsg, ID} ->
      waitFor(ID, Timeout),
      loop(Timeout)
  end.

waitFor(ID, Timeout) ->
  io:format("Waiting for Msg ~s~n", [io_lib:write(ID)]),
  receive
    {putMsg, ID, Msg} ->
      storage ! {putMsg, ID, lists:concat([Msg, " ", currentDateTime()])}
  after Timeout ->
    storage ! {nil, putMsg, ID, lists:concat([">> Msg with ID ", ID, " is missing ", currentDateTime(), " <<"])}
  end.

currentDateTime() ->
  {Year, Month, Day} = erlang:date(),
  {Hour, Minute, Second} = erlang:time(),
  lists:concat([mkString(".", [Day, Month, Year],[]), " ", mkString(":", [Hour, Minute, Second], [])]).

mkString(_, [], Result) ->
  Result;
mkString(Seperator, [Item|[]], Result) ->
  mkString(Seperator, [], lists:concat([Result, Item]));
mkString(Seperator, [Item|Rest], Result) ->
  mkString(Seperator, Rest, lists:concat([Result, Item, Seperator])).
