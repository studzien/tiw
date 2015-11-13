-module(tiw_example).

-compile(export_all).

process_timers(N, Ms) ->
    [ spawn_link(fun() ->
                         receive
                         after I*Ms ->
                                   ok
                         end
                 end) || I <- lists:seq(1, N) ].

bif_timers(N, Ms) ->
    [ begin
          Pid = spawn_link(fun() ->
                                   receive
                                       _ -> ok
                                   end
                           end),
          erlang:send_after(I*Ms, Pid, {msg, I})
      end || I <- lists:seq(1, N) ].

port_timers(N, Ms) ->
    ok = erl_ddll:load_driver("priv", "tiw_port_timer"),
    [ spawn_link(port_timer_fun(I*Ms)) || I <- lists:seq(1, N) ].

port_timer_fun(Timeout) ->
    fun() ->
            Port = erlang:open_port({spawn, tiw_port_timer}, [binary]),
            true = erlang:port_command(Port, <<Timeout:32>>),
            receive
                {Port, {data, <<"timeout">>}} ->
                    ok
            end
    end.
