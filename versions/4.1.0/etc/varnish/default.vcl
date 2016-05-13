#Please change the ".expected_response" param if there is a redirect on your backend to prevent considering 
#backend node as broken (Varnish expects "200" response code by default, change it to the value needed.)
#Example: backend serv1 { .host = "127.0.0.1"; .port = "80"; 
#       .probe = { .url = "/"; .timeout = 30s; .interval = 60s; .window = 5; .threshold = 2; .expected_response = 302; } }

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
