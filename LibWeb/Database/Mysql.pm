#=============================================================================
# LibWeb::Database::Mysql -- a component of LibWeb--a Perl library/toolkit for
#                            building World Wide Web applications.

package LibWeb::Database::Mysql;

# Copyright (C) 2000  Colin Kong
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#=============================================================================

# Implementing common, database-specific subroutines.
# This module is for interacting with a MySQL server and therefore
# uses MySQL specific syntax and built-in functions.

# For debugging purposes.  Should be commented out in production release.

# Use standard library.
use strict;
use vars qw(@ISA $VERSION);

# Use custom library.
require LibWeb::Database;

# Inheritance.
@ISA = qw(LibWeb::Database);

$VERSION = '0.01';

#=======================================================================
# Constructor.
sub new {
    #
    # Params: $class [, $rc_file]
    #
    # - $class is the class/package name of this package, be it a string
    #   or a reference.
    # - $rc_file is the absolute path to the rc file for LibWeb.
    #
    # Usage: my $object = new LibWeb::Database::Mysql([$rc_file]);
    #
    my ($class, $Class, $self);
    $class = shift;
    $Class = ref($class) || $class;

    # Inherit instance variables from the base class.
    $self = $Class->SUPER::new(shift);
    bless($self, $Class);

    # Any necessary initialization.
    #$self->_init();

    # Returns a reference to this object.
    return $self;
}

# sub _init {
#     # Initialization whenever an object of this class is created.
# }

sub DESTROY {
    # Destructor: performs cleanup when this object is not being referenced
    # any more.  For example, disconnect a database connection, filehandle...etc.
    my $self = shift;
    $self->done();
}

sub get_count {
    #
    # Params: ( -table =>, -where => ).
    #
    # Pre:
    # -table is a scalar indicating the table's name.
    # -where is a scalar for the `where' phrase of the SQL query.
    #
    # Post:
    # -return the number of counts satisfying the criteria specified in
    #  the -where parameter.
    #
    my ($self, $table, $where, $count);
    $self = shift;
    ($table, $where) = $self->rearrange( ['TABLE', 'WHERE'], @_ );
    $count =
      $self->do( -sql => "select COUNT(*) " . "from $table " . "where $where" );
    $self->finish();

    return $count;
}

1;
__DATA__

1;
__END__

=pod

=head1 NAME

LibWeb::Database::Mysql - MySQL DATABASE API FOR LIBWEB APPLICATIONS

=head1 SUPPORTED PLATFORMS

=over 2

=item BSD, Linux, Solaris and Windows.

=back

=head1 REQUIRE

=over 2

=item *

No non-standard Perl's library is required.

=back

=head1 ISA

=over 2

=item *

LibWeb::Database

=back

=head1 SYNOPSIS

  use LibWeb::Database::Mysql;
  my $db = new LibWeb::Database::Mysql();

  my ($where, $count);

  $where = 'LOGIN_STATUS = LOGGED_IN';
  $count = $db->get_count(
                           -table => USER_TABLE,
                           -where => $where
                         );

  print "Content-Type: text/html\n\n";
  print "$count users have logged in.";

=head1 ABSTRACT

This class provides enhanced support to MySQL database interaction in
you LibWeb applications.  This class also ISA LibWeb::Database so you
can use all the methods provided in LibWeb::Database via objects
created from this class.  See L<LibWeb::Database>.

The current version of LibWeb::Database::Mysql is available at

   http://libweb.sourceforge.net
   ftp://libweb.sourceforge/pub/libweb

Several LibWeb applications (LEAPs) have be written, released and
are available at

   http://leaps.sourceforge.net
   ftp://leaps.sourceforge.net/pub/leaps

=head1 TYPOGRAPHICAL CONVENTIONS AND TERMINOLOGY

Variables in all-caps (e.g. USER_TABLE) are those variables set
through LibWeb's rc file.  Please read L<LibWeb::Core> for more
information.  Method's parameters in square brackets means optional.

=head1 DESCRIPTION

=head2 METHODS

B<get_count()>

Params:

  -table =>, -where =>

Pre:

=over 2

=item *

-table is a scalar indicating a database table's name,

=item *

-where is a scalar describing the `where' phrase of a SQL query.

=back

Post:

=over 2

=item *

Return the number of counts satisfying the criteria specified in the
-where parameter.

=back

=head1 AUTHORS

=over 2

=item Colin Kong (colin.kong@toronto.edu)

=back

=head1 CREDITS

=head1 BUGS

=head1 SEE ALSO

L<LibWeb::Database>.

=cut
