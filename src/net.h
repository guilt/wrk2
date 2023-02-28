#ifndef NET_H
#define NET_H

#include <stdint.h>
#include "config.h"
#include "wrk.h"

typedef enum {
    OK,
    ERROR,
    RETRY,
    READ_EOF
} status;

struct sock {
    status ( *connect)(connection *, const char *);
    status (   *close)(connection *);
    status (    *read)(connection *, size_t *);
    status (   *write)(connection *, const char *, size_t, size_t *);
    size_t (*readable)(connection *);
};

status sock_connect(connection *, const char *);
status sock_close(connection *);
status sock_read(connection *, size_t *);
status sock_write(connection *, const char *, size_t, size_t *);
size_t sock_readable(connection *);

#endif /* NET_H */
