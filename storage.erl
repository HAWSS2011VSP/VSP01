-module(storage).
-export([start/1]).

start(CheckInterval) ->
  loop([],[], CheckInterval).

loop(Clients, Messages, CheckInterval) ->
  receive
    Some ->
      loop(Clients, Messages, CheckInterval)
  after CheckInterval ->
    loop(Clients, Messages, CheckInterval)
  end.
