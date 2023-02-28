#ifndef SSL_H
#define SSL_H

#include "net.h"
#include <openssl/evp.h>
#include <openssl/evperr.h>
#include <openssl/ssl.h>

SSL_CTX *ssl_init();

status ssl_set_mutual_auth(SSL_CTX *, const char *, const char *, const char *);
status ssl_set_cipher_list(SSL_CTX *, const char *);
status ssl_connect(connection *, const char *);
status ssl_close(connection *);
status ssl_read(connection *, size_t *);
status ssl_write(connection *, const char *, size_t, size_t *);
size_t ssl_readable(connection *);

#endif /* SSL_H */
