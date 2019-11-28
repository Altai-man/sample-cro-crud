#| A mock in-memory database.
class Blog::Database {
    has %.users;
    has %.posts;

    method add-user(:$username, :$password) {
        my $id = %!users.elems + 1;
        %!users{$id} = { :$id, :$username, :$password }
    }

    multi method get-user(Int $id) {
        %!users{$id}
    }

    multi method get-user(Str $username) {
        %!users.values.first(*<username> eq $username)
    }

    method add-post(:$title, :$body, :$author-id) {
        my $id = %!posts.elems + 1;
        %!posts{$id} = { :$id, :$title, :$body, :$author-id, created => now }
    }

    method get-post(UInt $id) {
        %!posts{$id}
    }

    method update-post($id, $title, $body) {
        %!posts{$id}<title> = $title;
        %!posts{$id}<body> = $body
    }

    method get-posts {
        %!posts.values.map({
            $_<username> = %!users{$_<author-id>}<username>;
            $_;
        }).sort(*.<created>);
    }

    method delete-post($id) {
        %!posts{$id}:delete;
    }
}
