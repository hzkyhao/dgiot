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

-module(dgiot_app).

-behaviour(application).

-export([ start/2
        , stop/1
        ]).

-define(APP, dgiot).

%%--------------------------------------------------------------------
%% Application callbacks
%%--------------------------------------------------------------------

start(_Type, _Args) ->
    print_banner(),
    ekka:start(),
    {ok, Sup} = emqx_sup:start_link(),
    ok = emqx_modules:load(),
    ok = emqx_plugins:init(),
    emqx_plugins:load(),
    start_autocluster(),
    register(emqx, self()),
    emqx_alarm_handler:load(),
    print_vsn(),
    {ok, Sup}.

-spec(stop(State :: term()) -> term()).
stop(_State) ->
    emqx_alarm_handler:unload(),
    emqx_modules:unload().

%%--------------------------------------------------------------------
%% Print Banner
%%--------------------------------------------------------------------

print_banner() ->
    io:format("Starting ~s on node ~s~n", [?APP, node()]).

print_vsn() ->
    {ok, Descr} = application:get_key(description),
    {ok, Vsn} = application:get_key(vsn),
    io:format("~s ~s is running now!~n", [Descr, Vsn]).

%%--------------------------------------------------------------------
%% Autocluster
%%--------------------------------------------------------------------

start_autocluster() ->
    ekka:callback(prepare, fun emqx:shutdown/1),
    ekka:callback(reboot,  fun emqx:reboot/0),
    ekka:autocluster(?APP).

