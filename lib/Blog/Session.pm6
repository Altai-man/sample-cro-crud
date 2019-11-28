use Cro::HTTP::Auth;

class Blog::Session does Cro::HTTP::Auth {
    has $.user-id is rw;

    method logged-in { $!user-id.defined }
}

subset LoggedIn of Blog::Session is export where *.logged-in;
