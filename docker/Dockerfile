FROM studzien/erlang:17.5

RUN apt-get install -y gdb git && \
    git clone https://github.com/studzien/tiw && \
    cd tiw && \
    ./rebar compile
