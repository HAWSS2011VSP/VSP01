-module(logger).
-export([create/1]).

create(File) ->
  {ok, Handle} = file:open(File, [append]),
  Run = fun() -> run(Handle) end,
  register(logger, spawn_link(Run)).

run(File) ->
  receive
    {debug, Msg} ->
      Message = lists:concat(["DEBUG: ", Msg, "\n"]),
      io:format(Message, []),
      file:write(File, Message);
    _ ->
      io:format("unknown operation!")
  end,
  run(File).
