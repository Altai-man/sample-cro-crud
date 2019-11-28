use Crypt::Argon2;
use Cro::WebApp::Template;
use Cro::HTTP::Router;
use Blog::Database;
use Blog::Session;

sub auth-routes(Blog::Database $db) is export {
    route {
        get -> Blog::Session $session, 'register' {
            template 'register.crotmp', { :logged-in($session.user-id.defined), :!error };
        }

        post -> Blog::Session $session, 'register' {
            request-body -> (:$username!, :$password!, *%) {
                with $db.get-user($username) {
                    template 'register.crotmp', { error => "User $username is already registered" };
                } else {
                    $db.add-user(:$username, :password(argon2-hash($password)));
                    redirect :see-other, '/auth/login';
                }
            }
        }

        get -> Blog::Session $session, 'login' {
            template 'login.crotmp', { :logged-in($session.user-id.defined), :!error };
        }

        post -> Blog::Session $session, 'login' {
            request-body -> (:$username!, :$password!, *%) {
                my $user = $db.get-user($username);
                with $user {
                    if (argon2-verify($_<password>, $password)) {
                        $session.user-id = $_<id>;
                        redirect :see-other, '/';
                    } else {
                        template 'login.crotmp', { :!logged-in, error => 'Incorrect password.' };
                    }
                } else {
                    template 'login.crotmp', { :!logged-in, error => 'Incorrect username.' };
                }
            }
        }

        get -> Blog::Session $session, 'logout' {
            $session.user-id = Nil;
            redirect :see-other, '/';
        }
    }
}
