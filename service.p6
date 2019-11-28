use Blog::Database;
use Blog::Routes;
use Cro::HTTP::Log::File;
use Cro::HTTP::Server;
use Cro::HTTP::Session::InMemory;

my $db = Blog::Database.new;

my Cro::Service $http = Cro::HTTP::Server.new(
    http => <1.1>,
    host => %*ENV<BLOG_HOST> ||
        die("Missing BLOG_HOST in environment"),
    port => %*ENV<BLOG_PORT> ||
        die("Missing BLOG_PORT in environment"),
    application => routes($db),
    before => [
        Cro::HTTP::Session::InMemory[Blog::Session].new(
                expiration => Duration.new(60 * 15),
                cookie-name => '_session')
    ],
    after => [
        Cro::HTTP::Log::File.new(logs => $*OUT, errors => $*ERR)
    ]
);
$http.start;

say "Listening at http://%*ENV<BLOG_HOST>:%*ENV<BLOG_PORT>";
react {
    whenever signal(SIGINT) {
        say "Shutting down...";
        $http.stop;
        done;
    }
}
