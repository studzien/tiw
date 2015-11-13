-module(tiw).

-compile(export_all).

-include("tiw.hrl").

-define(TIW_SIZE, 65536).

load(TiwFile) ->
    [Pos|Lines] = read_lines(TiwFile),
    parse_timers(Lines, i(Pos), []).

buckets(Timers, Interval) ->
    Ranges = ranges(Timers, Interval),
    [ {Range, length(Results)} || {Range, Results} <- Ranges,
                                  Results =/= [] ].

ranges(Timers, Interval) ->
    Last = lists:last(Timers),
    ranges(Timers, Interval, Last#timer.expires_in+Interval, Interval, []).

ranges(_, Current, Max, _, Acc) when Current > Max ->
    lists:reverse(Acc);
ranges(Timers, Current, Max, Interval, Acc0) ->
    Pred = fun(#timer{expires_in = Exp}) when Exp < Current -> 
                   true;
              (#timer{}) ->
                   false
           end, 
    {Cool, Uncool} = lists:splitwith(Pred, Timers),
    Acc1 = [{{Current-Interval, Current-1}, Cool} | Acc0],
    ranges(Uncool, Current+Interval, Max, Interval, Acc1).

read_lines(TiwFile) ->
    {ok, File} = file:open(TiwFile, [read, binary]),
    Result = do_read_lines(line(File), File),
    ok = file:close(File),
    Result.

parse_timers([], _, Acc) ->
    lists:keysort(#timer.expires_in, Acc);
parse_timers([_, _, _, <<>> | Rest], Pos, Acc) ->
    %% ignore incompatible format
    parse_timers(Rest, Pos, Acc);
parse_timers([Slot, Count, Callback, Info, <<>> | Rest], Pos, Acc) ->
    Timer = #timer{expires_in = expiration(Pos, i(Slot), i(Count)),
                   callback = binary_to_atom(Callback, utf8),
                   info = Info}, 
    parse_timers(Rest, Pos, [Timer | Acc]).

expiration(Pos, Slot, Count) when Slot > Pos ->
    Slot - Pos + (Count * ?TIW_SIZE);
expiration(Pos, Slot, Count) ->
    ((?TIW_SIZE - Pos) + Slot) + (Count * ?TIW_SIZE).

%% discard prefix
do_read_lines(eof, _File) ->
    erlang:error(tiw_block_not_found);
do_read_lines({ok, <<"=== tiw start\n">>}, File) ->
    do_read_lines(line(File), File, []);
do_read_lines(_, File) ->
    do_read_lines(line(File), File).

%% actual data
do_read_lines(eof, _, Acc) ->
    lists:reverse(Acc);
do_read_lines({ok, <<"=== tiw end\n">>}, _, Acc) ->
    lists:reverse(Acc);
do_read_lines({ok, Line}, File, Acc) ->
    do_read_lines(line(File), File, [strip(Line)|Acc]).

i(Binary) ->
    binary_to_integer(Binary).

line(File) ->
    file:read_line(File).

strip(Binary) ->
    << <<C>> || <<C>> <= Binary, C =/= $\r, C =/= $\n >>.
