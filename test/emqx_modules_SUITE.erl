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

-module(emqx_modules_SUITE).

-compile(export_all).
-compile(nowarn_export_all).

-include_lib("eunit/include/eunit.hrl").

all() -> emqx_ct:all(?MODULE).

init_per_suite(Config) ->
    emqx_ct_helpers:start_apps([], fun set_sepecial_cfg/1),
    Config.

set_sepecial_cfg(_) ->
    application:set_env(emqx, modules_loaded_file, emqx_ct_helpers:deps_path(emqx, "test/emqx_SUITE_data/loaded_modules")),
    ok.

end_per_suite(_Config) ->
    emqx_ct_helpers:stop_apps([]).

t_load(_) ->
    ?assertEqual(ok, emqx_modules:unload()),
    ?assertEqual(ok, emqx_modules:load()),
    ?assertEqual({error, not_found}, emqx_modules:load(not_existed_module)),
    ?assertEqual({error, not_started}, emqx_modules:unload(emqx_mod_rewrite)),
    ?assertEqual(ignore, emqx_modules:reload(emqx_mod_rewrite)),
    ?assertEqual(ok, emqx_modules:reload(emqx_mod_acl_internal)).

t_list(_) ->
    ?assertMatch([{_, _} | _ ], emqx_modules:list()).

