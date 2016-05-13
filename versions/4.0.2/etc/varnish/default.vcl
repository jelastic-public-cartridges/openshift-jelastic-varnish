vcl 4.0;
import std;
import directors;

backend default { .host = "127.0.0.1"; .port = "80"; }

sub vcl_init {
        new myclust = directors.hash();
        }

sub vcl_deliver {
        if (obj.hits > 0) {
                set resp.http.X-Cache = "HIT";
        } else {
                set resp.http.X-Cache = "MISS";
        }
}

sub vcl_recv {
        if (req.http.Upgrade ~ "(?i)websocket") {
                set req.backend_hint = myclust.backend(client.identity);
                return (pipe);
        }
        else {
                set req.backend_hint = myclust.backend(client.identity);
        }
}

sub vcl_hash {
    hash_data(req.url);
    if (req.http.host) {
        hash_data(req.http.host);
    } else {
        hash_data(server.ip);
    }
    return (lookup);
}

sub vcl_fini {
    return (ok);
        }
