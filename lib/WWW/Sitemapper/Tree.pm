
package WWW::Sitemapper::Tree;

=encoding utf8

=head1 NAME

WWW::Sitemapper::Tree - Tree structure of pages.

=head1 VERSION

Version 0.01

=cut


use Moose;
use WWW::Sitemapper::Types qw( tDateTime );

=head1 ATTRIBUTES

=head2 id

Unique id of the node.

=cut

has 'id' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    default => '0',
);

=head2 uri

URI object for page. Represents the link found on the web site - before any
redirections.

=cut

has 'uri' => (
    is => 'rw',
    isa => 'URI',
    required => 1,
);

has '_base_uri' => (
    is => 'rw',
    isa => 'URI',
);

=head2 title

Title of page.

=cut

has 'title' => (
    is => 'rw',
    isa => 'Str',
);

=head2 last_modified

Value of Last-modified header.

=cut

has 'last_modified' => (
    is => 'rw',
    isa => tDateTime,
    coerce => 1,
);

=head2 nodes

An array of all links found on the page - represented by
L<WWW::Sitemapper::Tree>.

=cut

has 'nodes' => (
    traits => [qw( Array )],
    is => 'rw',
    isa => 'ArrayRef[WWW::Sitemapper::Tree]',
    default => sub { [] },
    handles => {
        children => 'elements',
        add_child => 'push',
    }
);

has '_dictionary' => (
    traits => [qw( Hash )],
    is => 'rw',
    isa => 'HashRef[ScalarRef]',
    default => sub { +{} },
    handles => {
        add_to_dictionary => 'set',
        fast_lookup => 'get',
        all_entries => 'values',
    }
);

has '_redirects' => (
    traits => [qw( Hash )],
    is => 'rw',
    isa => 'HashRef[Ref]',
    default => sub { +{} },
    handles => {
        store_redirect => 'set',
        find_redirect => 'get',
    },
);

=head1 METHODS

=head2 find_node

    my $map = MyWebSite::Map->new(
        site => 'http://mywebsite.com/',
        status_storage => 'sitemap.data.storable',
    );

    my $node = $map->tree->find_node( $uri );

Searches the cache for a node with matching uri.

Note: use it only at the root element.

=cut

sub find_node {
    my $self = shift;
    my $url = shift;

    if ( my $node = $self->fast_lookup( $url->as_string ) ) {
        return $$node;
    }
    return;
}

=head2 redirected_from

    my $parent = $map->tree->redirected_from( $uri );

Searches the redirects cache for a node with matching uri.

Note: use it only at the root element.

=cut

sub redirected_from {
    my $self = shift;
    my $url = shift;

    if ( my $node = $self->find_redirect( $url->as_string ) ) {
        return $$node;
    }
    return;
}


=head2 add_node

    my $parent = $map->tree->find_node( $parent_uri );

    my $child = $parent->add_node(
        WWW::Sitemapper::Tree->new(
            uri => $uri,
        )
    );

Searches the cache for a node with matching uri.

Note: use it only at the root element.

=cut


sub add_node {
    my $self = shift;
    my $link = shift;

    $link->id( join(':', $self->id, scalar @{ $self->nodes } ) );

    $self->add_child( $link );

    return $link;
}

=head2 loc

URI object for page. Represents the base location of page - which takes into
account any redirections.

=cut

sub loc {
    my $self = shift;

    return $self->_base_uri || $self->uri;
}


=head1 AUTHOR

Alex J. G. Burzyński, E<lt>ajgb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Alex J. G. Burzyński

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;
