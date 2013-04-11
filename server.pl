use 5.010;
use strict;
use warnings;

use Plack::Builder;
use Plack::Request;
use Plack::Response;
use Plack::Middleware::Static;


sub app {
    builder {
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

app();
