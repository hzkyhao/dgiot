%%--------------------------------------------------------------------
%% Copyright (c) 2020 EMQ Technologies Co., Ltd. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%--------------------------------------------------------------------

-module(prop_emqx_rpc).

-include_lib("proper/include/proper.hrl").
-include_lib("eunit/include/eunit.hrl").

-define(ALL(Vars, Types, Exprs),
        ?SETUP(fun() ->
            State = do_setup(),
            fun() -> do_teardown(State) end
         end, ?FORALL(Vars, Types, Exprs))).

%%--------------------------------------------------------------------
%% Properties
%%--------------------------------------------------------------------

prop_node() ->
    ?ALL(Node, nodename(),
         begin
             ?assert(emqx_rpc:cast(Node, erlang, system_time, [])),
             case emqx_rpc:call(Node, erlang, system_time, []) of
                 {badrpc, _Reason} -> true;
                 Delivery when is_integer(Delivery) -> true;
                 _Other -> false
             end
         end).

prop_node_with_key() ->
    ?ALL({Node, Key}, nodename_with_key(),
         begin
             ?assert(emqx_rpc:cast(Key, Node, erlang, system_time, [])),
             case emqx_rpc:call(Key, Node, erlang, system_time, []) of
                 {badrpc, _Reason} -> true;
                 Delivery when is_integer(Delivery) -> true;
                 _Other -> false
             end
         end).

prop_nodes() ->
    ?ALL(Nodes, nodesname(),
         begin
             case emqx_rpc:multicall(Nodes, erlang, system_time, []) of
                 {badrpc, _Reason} -> true;
                 {RealResults, RealBadNodes}
                   when is_list(RealResults);
                        is_list(RealBadNodes) ->
                     true;
                 _Other -> false
             end
         end).

prop_nodes_with_key() ->
    ?ALL({Nodes, Key}, nodesname_with_key(),
         begin
             case emqx_rpc:multicall(Key, Nodes, erlang, system_time, []) of
                 {badrpc, _Reason} -> true;
                 {RealResults, RealBadNodes}
                   when is_list(RealResults);
                        is_list(RealBadNodes) ->
                     true;
                 _Other -> false
             end
         end).

%%--------------------------------------------------------------------
%%  Helper
%%--------------------------------------------------------------------

do_setup() ->
    {ok, _Apps} = application:ensure_all_started(gen_rpc),
    ok = application:set_env(gen_rpc, call_receive_timeout, 1),
    ok = emqx_logger:set_log_level(emergency),
    ok = meck:new(gen_rpc, [passthrough, no_history]),
    ok = meck:expect(gen_rpc, multicall,
                     fun(Nodes, Mod, Fun, Args) ->
                             gen_rpc:multicall(Nodes, Mod, Fun, Args, 1)
                     end).

do_teardown(_) ->
    ok = emqx_logger:set_log_level(debug),
    ok = application:stop(gen_rpc),
    ok = meck:unload(gen_rpc).

%%--------------------------------------------------------------------
%% Generator
%%--------------------------------------------------------------------

nodename() ->
    ?LET({NodePrefix, HostName},
         {node_prefix(), hostname()},
         begin
             Node = NodePrefix ++ "@" ++ HostName,
             list_to_atom(Node)
         end).

nodename_with_key() ->
    ?LET({NodePrefix, HostName, Key},
         {node_prefix(), hostname(), choose(0, 10)},
         begin
             Node = NodePrefix ++ "@" ++ HostName,
             {list_to_atom(Node), Key}
         end).

nodesname() ->
    oneof([list(nodename()), [node()]]).

nodesname_with_key() ->
    oneof([{list(nodename()), choose(0, 10)}, {[node()], 1}]).

node_prefix() ->
    oneof(["emqxct", text_like()]).

text_like() ->
    ?SUCHTHAT(Text, list(range($a, $z)), (length(Text) =< 5 andalso length(Text) > 0)).

hostname() ->
    oneof(["127.0.0.1", "localhost"]).
