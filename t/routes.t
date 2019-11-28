use Cro::HTTP::Test;
use Test;
use Blog::Session;
use Blog::Database;
use Blog::Routes;

# Auth module tests
test-service routes(Blog::Database.new), fake-auth => Blog::Session.new, {
    # Can't access user-private pages
    test-given '/blog/create', {
        get status => 200,
            body => / 'Login' /;
    }

    # Can get and post login page
    test-given '/auth/login', {
        test get,
                status => 200,
                body => / 'Login' /;
        test post(content-type => 'application/x-www-form-urlencoded', body => { :username('no such'), :password('bad one') }),
                status => 200,
                body => / 'Incorrect username' /;
    }

    # Can register and login
    test-given '/auth/register', {
        test get, status => 200, body => / 'Register' /;

        test post(content-type => 'application/x-www-form-urlencoded', body => { :username('test'), :password('test') }),
                status => 200,
                body => / 'Login' /;

        test post(content-type => 'application/x-www-form-urlencoded', body => { :username('test'), :password('test') }),
                status => 200,
                body => / 'Register' .*? 'User test is already registered' /;
    }

    # Recognizes incorrect password of existing user
    test-given '/auth/login', {
        test post(content-type => 'application/x-www-form-urlencoded', body => { :username('test'), :password('bad one') }),
                status => 200,
                body => / 'Incorrect password' /;
    }
}


# A new mock database
my $db = Blog::Database.new(users => 1 => { :1id, :username('test'), :password('$argon2i$v=19$m=65536,t=2,p=2$YXmhOzwxmM8VSqECN4jkjg$wJtiqhDu+/IMjN2ySMvq9A') });

test-service routes($db), {
    # Fake a session for the user
    my $fake-auth = Blog::Session.new(user-id => 1);
    test-given :$fake-auth, {
        # Can visit main page
        test get,
                status => 200,
                body => / 'Posts' /;
        # Can create new post
        test get('/blog/create'),
                status => 200,
                body => / 'New' /;
        test post('/blog/create', content-type => 'application/x-www-form-urlencoded', body => { :title('Test message 1'), :body('My first post.') }),
                status => 200,
                body => / 'Posts' .+? 'Test message 1' .+? 'My first post.' /;
        # Can't update a non-existing post
        test get('/blog/999/update'),
                status => 404;
        # Can update a post
        test get('/blog/1/update'),
                status => 200,
                body => / 'Edit' .+? 'Test message 1' .+? 'My first post.' /;
        test post('/blog/1/update', content-type => 'application/x-www-form-urlencoded', body => { :title('Test message 10'), :body('My new post.') }),
                status => 200,
                body => / 'Posts' .+? 'Test message 10' .+? 'My new post.' /;
        # Can delete a post
        test post('/blog/1/delete'),
                status => 200;
        isnt $db.get-post(1).defined, 'Post was removed';
        # Can't delete a non-existing post
        test post('/blog/999/delete'),
                status => 404;
    }
}

done-testing;
