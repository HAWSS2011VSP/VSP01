-module(utils).
-export([now_str/0, bool_rand/0]).

now_str() ->
  {{Year, Month, Day},{Hour, Minute, Second}} = calendar:now_to_local_time(now()),
  lists:concat([Day, ".", Month, ".", Year, " ", Hour, ":", Minute, ":", Second]).

bool_rand() ->
  random:uniform(2) == 1.
