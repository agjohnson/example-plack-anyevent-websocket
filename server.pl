
use 5.010;
use strict;
use warnings;

use Plack::Builder;
use Plack::Request;
use Plack::Response;
use Plack::Middleware::Static;
use SockJS;
use AnyEvent::Redis;
use Data::Dumper;

our $Guards = {};


sub app {
    builder {
        mount '/event' => websocket();
        enable 'Plack::Middleware::Static',
          path => qr/\.(?:html|js)$/,
          root => 'public/';
        mount '/' => process();
    }
}

sub process {
    return sub {
        my $env = shift;

        my $req = Plack::Request->new($env);
        my $path = $req->path_info;

        if ($path =~ m#^[/]{0,1}$#) {
            return Plack::Response->new(
                302,
                {Location => '/index.html'},
                []
            )->finalize;
        }

        return Plack::Response->new(
            404,
            {},
            'Not found'
        )->finalize;
    }
}

sub websocket {
    SockJS->new(
        sockjs_url => '/sockjs-0.3.4.min.js',
        chunked => 0,
        handler => sub {
            my ($session) = @_;

            my $redis_sub = redis();
            $Guards->{$redis_sub} = $redis_sub;
            $redis_sub->subscribe('event', sub {
                my ($data, $channel) = @_;
                $session->write($data);
            });

            my $redis_pub = redis();
            $Guards->{$redis_pub} = $redis_pub;
            $session->on('data' => sub {
                my ($session, $data) = @_;
                $redis_pub->publish('event', $data);
            });
        }
    );
}

sub redis {
    AnyEvent::Redis->new(
        host => '127.0.0.1',
        port => 6379
    );
}

app();
