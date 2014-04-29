use strict;
use warnings;
use Test::More tests => 23;
use lib 'lib';
use Forward::Routes;



#############################################################################
### NON block style

my $r = Forward::Routes->new;
my $authors = $r->add_route('/authors');

$authors->add_route->to('Author#index');
my $author = $authors->add_route('/:author_name');

$author->add_route->to('Author#show');
my $articles = $author->add_route('articles');

$articles->add_route->to('Article#index');
my $article = $articles->add_route('/:article_id');

$article->add_route->to('Article#show');
my $comments = $article->add_route('comments');

$comments->add_route->to('Comment#index');
$comments->add_route('/:comment_id')->to('Comment#show');


# tests
my $m = $r->match(get => '/authors');
is_deeply $m->[0]->params, {controller => 'Author', action => 'index'};

$m = $r->match(get => '/authors/steven');
is_deeply $m->[0]->params, {controller => 'Author', action => 'show', author_name => 'steven'};

$m = $r->match(get => '/authors/steven/articles');
is_deeply $m->[0]->params, {controller => 'Article', action => 'index', author_name => 'steven'};

$m = $r->match(get => '/authors/steven/articles/4');
is_deeply $m->[0]->params, {controller => 'Article', action => 'show', author_name => 'steven', article_id => 4};

$m = $r->match(get => '/authors/steven/articles/4/comments');
is_deeply $m->[0]->params, {controller => 'Comment', action => 'index', author_name => 'steven', article_id => 4};

$m = $r->match(get => '/authors/steven/articles/4/comments/3');
is_deeply $m->[0]->params, {controller => 'Comment', action => 'show', author_name => 'steven', article_id => 4, comment_id => 3};


#############################################################################
### block style

my $b = Forward::Routes->new;

$b->add_route('/authors', sub {
    my $authors = shift;

    $authors->add_route->to('Author#index');
    $authors->add_route('/:author_name', sub {
        my $author = shift;

        $author->add_route->to('Author#show');
        $author->add_route('articles', sub {
            my $articles = shift;

            $articles->add_route->to('Article#index');
            $articles->add_route('/:article_id', sub {
                my $article = shift;

                $article->add_route->to('Article#show');
                $article->add_route('comments', sub {
                    my $comments = shift;

                    $comments->add_route->to('Comment#index');
                    $comments->add_route('/:comment_id')->to('Comment#show');

                });

            });

        });

    });
});


# tests
$m = $b->match(get => '/authors');
is_deeply $m->[0]->params, {controller => 'Author', action => 'index'};
is $m->[0]->class, 'Author';

$m = $b->match(get => '/authors/steven');
is_deeply $m->[0]->params, {controller => 'Author', action => 'show', author_name => 'steven'};

$m = $b->match(get => '/authors/steven/articles');
is_deeply $m->[0]->params, {controller => 'Article', action => 'index', author_name => 'steven'};

$m = $b->match(get => '/authors/steven/articles/4');
is_deeply $m->[0]->params, {controller => 'Article', action => 'show', author_name => 'steven', article_id => 4};

$m = $b->match(get => '/authors/steven/articles/4/comments');
is_deeply $m->[0]->params, {controller => 'Comment', action => 'index', author_name => 'steven', article_id => 4};

$m = $b->match(get => '/authors/steven/articles/4/comments/3');
is_deeply $m->[0]->params, {controller => 'Comment', action => 'show', author_name => 'steven', article_id => 4, comment_id => 3};



#############################################################################
### block style with inheritance

my $root = Forward::Routes->new->app_namespace('Root');
$root->add_route('/authors', sub {
    my $authors = shift;

    $authors->namespace('My::Authors');
    $authors->format('json');
    $authors->via(['post']);

    $authors->add_route('/:author_name', sub {
        my $author = shift;

        $author->add_route('articles', sub {
            my $articles = shift;

            $articles->add_route('/:article_id', sub {
                my $article = shift;
                $article->add_route('comments')->name("comments_index")->to("Comment#index");
            });

        });

    });
});
my $comments_index_route = $root->find_route('comments_index');
is $comments_index_route->app_namespace, 'Root';
is $comments_index_route->namespace, 'My::Authors';
is_deeply $comments_index_route->format, ['json'];
is_deeply $comments_index_route->via, ['post'];
$m = $root->match(post => '/authors/steven/articles/4/comments.json');
is_deeply $m->[0]->params, {controller => 'Comment', action => 'index', author_name => 'steven', article_id => 4, format => 'json'};



# similar test
$root = Forward::Routes->new->app_namespace('Admin');
$root->add_route('/authors', namespace => 'Your::Authors', format => ['xml'], via => ['put'], sub {
    my $authors = shift;

    $authors->add_route('/:author_name', sub {
        my $author = shift;

        $author->add_route('articles', sub {
            my $articles = shift;

            $articles->add_route('/:article_id', sub {
                my $article = shift;
                $article->add_route('comments')->name("comments_index")->to("Comment#index");
            });

        });

    });
});
$comments_index_route = $root->find_route('comments_index');
is $comments_index_route->app_namespace, 'Admin';
is $comments_index_route->namespace, 'Your::Authors';
is_deeply $comments_index_route->format, ['xml'];
is_deeply $comments_index_route->via, ['put'];
$m = $root->match(put => '/authors/steven/articles/4/comments.xml');
is_deeply $m->[0]->params, {controller => 'Comment', action => 'index', author_name => 'steven', article_id => 4, format => 'xml'};



#############################################################################
### block style, using method signatures

#use Method::Signatures::Simple;
#
#my $ms = Forward::Routes->new;
#
#$ms->add_route('/authors', func($authors) {
#
#    $authors->add_route->to('Author#index');
#    $authors->add_route('/:author_name', func($author) {
#
#        $author->add_route->to('Author#show');
#        $author->add_route('articles', func($articles) {
#
#            $articles->add_route->to('Article#index');
#            $articles->add_route('/:article_id', func($article) {
#
#                $article->add_route->to('Article#show');
#                $article->add_route('comments', func($comments) {
#
#                    $comments->add_route->to('Comment#index');
#                    $comments->add_route('/:comment_id')->to('Comment#show');
#
#                });
#
#            });
#
#        });
#
#    });
#});

# tests
#$m = $ms->match(get => '/authors');
#is_deeply $m->[0]->params, {controller => 'Author', action => 'index'};
#
#$m = $ms->match(get => '/authors/steven');
#is_deeply $m->[0]->params, {controller => 'Author', action => 'show', author_name => 'steven'};
#
#$m = $ms->match(get => '/authors/steven/articles');
#is_deeply $m->[0]->params, {controller => 'Article', action => 'index', author_name => 'steven'};
#
#$m = $ms->match(get => '/authors/steven/articles/4');
#is_deeply $m->[0]->params, {controller => 'Article', action => 'show', author_name => 'steven', article_id => 4};
#
#$m = $ms->match(get => '/authors/steven/articles/4/comments');
#is_deeply $m->[0]->params, {controller => 'Comment', action => 'index', author_name => 'steven', article_id => 4};
#
#$m = $ms->match(get => '/authors/steven/articles/4/comments/3');
#is_deeply $m->[0]->params, {controller => 'Comment', action => 'show', author_name => 'steven', article_id => 4, comment_id => 3};

