use Cro::HTTP::Router;
use Cro::WebApp::Template;
use Blog::Database;
use Blog::Routes::Auth;
use Blog::Routes::Blog;

sub routes(Blog::Database $db) is export {
    template-location 'templates/';

    route {
        after { redirect '/auth/login', :see-other if .status == 401 };

        include auth => auth-routes($db);

        include blog-routes($db);

        get -> 'css', *@path {
            static 'static-content/css', @path
        }
    }
}
