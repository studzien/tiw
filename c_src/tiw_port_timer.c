#include <stdio.h>
#include <erl_driver.h>

#define get_int32(s) ((((unsigned char*) (s))[0] << 24) | \
                      (((unsigned char*) (s))[1] << 16) | \
                      (((unsigned char*) (s))[2] << 8)  | \
                      (((unsigned char*) (s))[3]))

static ErlDrvData timer_start(ErlDrvPort, char*);
static void timer_stop(ErlDrvData);
static void timer_read(ErlDrvData, char*, ErlDrvSizeT);
static void timer(ErlDrvData);

static ErlDrvEntry timer_driver_entry =
{
    NULL,
    timer_start,
    timer_stop,
    timer_read,
    NULL,
    NULL,
    "tiw_port_timer",
    NULL,
    NULL,
    NULL,
    timer,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    ERL_DRV_EXTENDED_MARKER,
    ERL_DRV_EXTENDED_MAJOR_VERSION,
    ERL_DRV_EXTENDED_MINOR_VERSION,
    0,
    NULL,
    NULL,
    NULL
};

DRIVER_INIT(tiw_port_timer)
{
    return &timer_driver_entry;
}

static ErlDrvData timer_start(ErlDrvPort port, char *buf)
{
    return (ErlDrvData)port;
}

static void timer_read(ErlDrvData p, char *buf, ErlDrvSizeT len)
{
    ErlDrvPort port = (ErlDrvPort) p;
    driver_set_timer(port, get_int32(buf));
}

static void timer_stop(ErlDrvData port)
{
}

static void timer(ErlDrvData port)
{
    char* reply = "timeout";
    driver_output((ErlDrvPort)port, reply, 7);
}
