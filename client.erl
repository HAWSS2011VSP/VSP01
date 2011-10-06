%% Author: André SchmiDidt
%% Created: 03.04.2011
%% Description: TODO: Add description to dummyClient
-module(client).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([setup/0]).

%%
%% API Functions
%%



%%
%% Local Functions
%%

setup() ->
  net_kernel:start([client, shortnames]),
  erlang:nodes(visible),
  process_flag(trap_exit, true),
  %ServerID = spawn(mainServer,hauptVerwalter,start,[]),
  %ServerID ! {self(), anfrage1 },
  Server = {server,server@localhost},
  net_kernel:connect_node(server@localhost),
  Server ! {self(), getMsgId},
  receive
    {msgId, ID} ->
      io:fwrite( "ID: ~s~n", [io_lib:write(ID)] ),
      Server ! {self(), putMsg, ID, "Das ist eine Nachricht"},
      Server ! {self(), getMsg},
      receive
        {Msg, MsgID, All} ->
          io:format("Got: ~s.~n", [Msg])
      after 10000 ->
        exit(why_no_message)
      end
  end.

% server_node() ->
%     {ok,HostName} = inet:gethostname(),
%     list_to_atom("gandalf@localhost" ++ HostName).
