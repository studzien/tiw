tiw
===

This tool allows you to dump all the timers inside the Erlang VM via gdb.
Please note that this might not work properly on your OTP version and
it currently *does not* work on OTP >= 18.

Why?
----
There are two main reasons why you might need this:
* you assumed that you can distribute load uniformly using timers, but
  some glitch caused timers to synchronize (all timers are triggered in a
  short period of time)
* you like to look under the hood

How?
----
Since one example is worth a thousand words...

(you can rerun the commands on a Docker container built from
``docker/Dockerfile``, you need to start two terminals in order to attach
`gdb` to `beam`).

Terminal 1:
```
root@e9858d91550c:/tiw# erl -smp enable -pa ebin
Erlang/OTP 17 [erts-6.4] [source] [64-bit] [smp:1:1] [async-threads:10]
[kernel-poll:false]

Eshell V6.4  (abort with ^G)
1> os:getpid().
"19"
2> tiw_example:process_timers(100, 10000),
2> timer:sleep(2000),
2> tiw_example:bif_timers(100, 20000),
2> timer:sleep(2000),
2> tiw_example:port_timers(100, 30000).
[<0.236.0>,<0.237.0>,<0.238.0>,<0.239.0>,<0.240.0>,
 <0.241.0>,<0.242.0>,<0.243.0>,<0.244.0>,<0.245.0>,<0.246.0>,
 <0.247.0>,<0.248.0>,<0.249.0>,<0.250.0>,<0.251.0>,<0.252.0>,
 <0.253.0>,<0.254.0>,<0.255.0>,<0.256.0>,<0.257.0>,<0.258.0>,
 <0.259.0>,<0.260.0>,<0.261.0>,<0.262.0>,<0.263.0>,<0.264.0>|...]
```

Terminal 2:
```
root@10a857bd690c:/# gdb --pid=19
(gdb) source
~/.kerl/builds/17.5/otp_src_17.5/erts/etc/unix/etp-commands.in
(gdb) source tiw/priv/tiw.in
(gdb) set height 0
(gdb) set logging file timers_smp
(gdb) set logging on
(gdb) tiw
=== tiw start
35696
36083
3
bif_timer_timeout
<0.145.0> ! {msg,10}.

36120
16
ptimer_timeout
#NotPid<0x2a47> | #Port<0.676>

36401
8
ptimer_timeout
<0.88.0> | #NotPort<0x583>
...
35329
9
ptimer_timeout
<0.101.0> | #NotPort<0x653>
=== tiw end
```

This should've generated a `/timers_smp` file.

Later you can use some
helpers to parse the file (of course it can be done somewhere else):
```
root@10a857bd690c:/tiw# erl -pa ebin
Erlang/OTP 17 [erts-6.4] [source] [64-bit] [async-threads:10]
[kernel-poll:false]

Eshell V6.4  (abort with ^G)
1> rr("src/tiw.hrl").
[timer]
2> Timers = tiw:load("../timers_smp").
[#timer{expires_in = 1000,callback = aux_work_timeout,
        info = <<"NULL">>},
 #timer{expires_in = 4993,callback = ptimer_timeout,
        info = <<"<0.36.0> | #NotPort<0x243>">>},
 #timer{expires_in = 14993,callback = ptimer_timeout,
        info = <<"<0.37.0> | #NotPort<0x253>">>},
 #timer{expires_in = 16995,callback = bif_timer_timeout,
        info = <<"<0.136.0> ! {msg,1}.">>},
 #timer{expires_in = 24993,callback = ptimer_timeout,
        info = <<"<0.38.0> | #NotPort<0x263>">>},
 #timer{expires_in = 29000,callback = ptimer_timeout,
        info = <<"#NotPid<0x2827> | #Port<0.642>">>},
 #timer{expires_in = 34993,callback = ptimer_timeout,
        info = <<"<0.39.0> | #NotPort<0x273>">>},
 #timer{expires_in = 36995,callback = bif_timer_timeout,
        info = <<"<0.137.0> ! {msg,2}.">>},
 #timer{expires_in = 44993,callback = ptimer_timeout,
        info = <<"<0.40.0> | #NotPort<0x283>">>},
 #timer{expires_in = 54993,callback = ptimer_timeout,
        info = <<"<0.41.0> | #NotPort<0x293>">>},
 #timer{expires_in = 56995,callback = bif_timer_timeout,
        info = <<"<0.138.0> ! {msg,3}.">>},
 #timer{expires_in = 59000,callback = ptimer_timeout,
        info = <<"#NotPid<0x2837> | #Port<0.643>">>},
 #timer{...},
 {...}|...]
3> tiw:buckets(Timers, 1000).
[{{1000,1999},1},
 {{4000,4999},1},
 {{14000,14999},1},
 {{16000,16999},1},
 {{24000,24999},1},
 {{29000,29999},1},
 {{34000,34999},1},
 {{36000,36999},1},
 {{44000,44999},1},
 {{54000,54999},1},
 {{56000,56999},1},
 {{59000,59999},1},
 {{64000,...},1},
 {{...},...},
 {...}|...]
```

The second command returns number of timers in appropriate seconds
(interval is the second argument, in milliseconds).
