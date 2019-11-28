use Blog::Database;
use Blog::Routes::Auth;
use Blog::Session;
use Cro::HTTP::Router;
use Cro::WebApp::Template;

sub blog-routes(Blog::Database $db) is export {
    route {
        get -> Blog::Session $session {
            my $user = $session.logged-in ?? $db.get-user($session.user-id) !! {};
            $user<logged-in> = $session.logged-in;
            my $posts = $db.get-posts.map({
                $_<created> = Date.new($_<created>).Str;
                $_;
            });
            template 'index.crotmp', { :$user, :$posts };
        }

        include <blog> => route {
            get -> LoggedIn $session, 'create' {
                template 'create.crotmp';
            }

            post -> LoggedIn $session, 'create' {
                request-body -> (:$title!, :$body!, *%) {
                    $db.add-post(:$title, :$body, author-id => $session.user-id);
                    redirect :see-other, '/';
                }
            }

            #| A helper for executing code blocks
            #| only on posts one can access
            sub process-post($session, $id, &process) {
                with $db.get-post($id) -> $post {
                    if $post<author-id> == $session.user-id {
                        &process($post);
                    } else {
                        forbidden;
                    }
                } else {
                    not-found;
                }
            }

            get -> LoggedIn $session, UInt $id, 'update' {
                process-post($session, $id, -> $post { template 'update.crotmp', $post });
            }

            post -> LoggedIn $session, UInt $id, 'update' {
                process-post($session, $id, -> $ {
                    request-body -> (:$title!, :$body!) {
                        $db.update-post($id, $title, $body);
                        redirect :see-other, '/';
                    }
                });
            }

            post -> LoggedIn $session, UInt $id, 'delete' {
                process-post($session, $id, -> $ {
                    $db.delete-post($id);
                    redirect :see-other, '/';
                });
            }
        }
    }
}
