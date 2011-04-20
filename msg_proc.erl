-module(msg_proc).
-export([start/1]).


start(Timeout) ->
  loop(Timeout).

loop(Timeout) ->
  receive
    {waitForMsg, ID} ->
      waitFor(ID, Timeout)
  end.

waitFor(ID, Timeout) ->
  receive
    {PID, putMessage, ID, Msg} ->
      storage ! {PID, putMessage, ID, Msg}
  after Timeout ->
    storage ! {nil, putMessage, ID, lists:concat([">> Msg with ID ", ID, " is missing ", currentDateTime(), " <<"])}
  end.

currentDateTime() ->
  {Year, Month, Day} = erlang:date(),
  {Hour, Minute, Second} = erlang:time(),
  lists:concat([mkString(".", [Day, Month, Year],[]), " ", mkString(":", [Hour, Minute, Second], [])]).

mkString(Seperator, [], Result) ->
  Result;
mkString(Seperator, [Item|[]], Result) ->
  mkString(Seperator, [], lists:concat([Result, Item]));
mkString(Seperator, [Item|Rest], Result) ->
  mkString(Seperator, Rest, lists:concat([Result, Item, Seperator])).