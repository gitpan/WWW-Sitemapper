
package WWW::Sitemapper::Tree;

=encoding utf8

=head1 NAME

WWW::Sitemapper::Tree - Tree structure of pages.

=cut

use Moose;
use WWW::Sitemapper::Types qw( tDateTime );

our $VERSION = '0.02';

=head1 ATTRIBUTES

=head2 id

Unique id of the node.

Type: C<Str>.

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

Type: L<WWW::Sitemapper::Types/"tURI">.

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

Type: C<Str>.

=cut

has 'title' => (
    is => 'rw',
    isa => 'Str',
);

=head2 last_modified

Value of Last-modified header.

Type: L<WWW::Sitemapper::Types/"tDateTime">.

=cut

has 'last_modified' => (
    is => 'rw',
    isa => tDateTime,
    coerce => 1,
);

=head2 nodes

An array of all mapped links found on the page - represented by
L<WWW::Sitemapper::Tree>.

Type: C<ArrayRef[>L<WWW::Sitemapper::Tree>C<]>.

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

    my $mapper = MyWebSite::Map->new(
        site => 'http://mywebsite.com/',
        status_storage => 'sitemap.data',
    );
    $mapper->restore_state();

    my $node = $mapper->tree->find_node( $uri );

Searches the cache for a node with matching uri.

Note: use it only at the root element L<WWW::Sitemapper/"tree">.

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

    my $parent = $mapper->tree->redirected_from( $uri );

Searches the redirects cache for a node with matching uri.

Note: use it only at the root element L<WWW::Sitemapper/"tree">.

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

    my $child = $parent->add_node(
        WWW::Sitemapper::Tree->new(
            uri => $uri,
        )
    );

Adds new node to C<$parent> object and returns child with id set.

=cut

sub add_node {
    my $self = shift;
    my $link = shift;

    $link->id( join(':', $self->id, scalar @{ $self->nodes } ) );

    $self->add_child( $link );

    return $link;
}

=head2 loc
    
    print $node->loc;

Represents the base location of page (which may be different from node
L<"uri"> if there was a redirection).

=cut

sub loc {
    my $self = shift;

    return $self->_base_uri || $self->uri;
}


=head2 children

    for my $child ( $node->children ) {
        ...
    }

Returns all children of the node.


=head1 AUTHOR

Alex J. G. Burzyński, E<lt>ajgb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Alex J. G. Burzyński

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;