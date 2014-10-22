#==============================================================================
# LibWeb::Database -- a component of LibWeb--a Perl library/toolkit for
#                     building World Wide Web applications.

package LibWeb::Database;

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

# For debugging purposes.  Should be commented out in production release.

# Use standard library.
use strict;
use vars qw(@ISA $VERSION);
use DBI;

# Use custom library.
require LibWeb::Core;

# Inheritance.
@ISA = qw(LibWeb::Core);

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
    # Usage: my $object = new LibWeb::Database([$rc_file]);
    #
    my ($class, $Class, $self);
    $class = shift;
    $Class = ref($class) || $class;

    # Inherit instance variables from the base class.
    $self = $Class->SUPER::new(shift);
    bless($self, $Class);

    # Any necessary initialization.
    $self->_init();

    # Returns a reference to this object.
    return $self;
}

sub _init {
    # Initialization whenever an object of this class is created.
    my $self = shift;

    # Connect to the database.
    eval { 
	$self->{__PACKAGE__.'.dbHandle'} = 
	  DBI->connect($self->{DB_SOURCE}, $self->{DB_LOGIN},
		       $self->{DB_PASS}, $self->{DB_OPTIONS});
    };

    $self->fatal(
		 -msg => 'Our database is under construction.',
		 -alertMsg =>
		 'LibWeb::Database::_init(): can\'t connect to database.',
		 -HelpMsg => $self->{HHTML}->database_error()
		)
      if $@;
}

sub DESTROY {
    # Destructor: performs cleanup when this object is not being referenced
    # any more.  For example, disconnect a database connection, filehandle...etc.
    my $self = shift;
    $self->done();
}

sub do {
    #
    # Params: ( -sql=> ).
    #
    # Pre:
    # -sql is a valid sql statement.
    #
    # Post:
    # -Return the number of rows affected by the SQL statement, -sql.
    #
    my ($self, $sql);
    $self = shift;
    ($sql) = $self->rearrange( ['SQL'], @_ );

    return $self->{__PACKAGE__. '.dbHandle'}->do($sql) or
      $self->fatal(
		   -msg => 'Our database is under construction.',
		   -alertMsg => "Database error: $sql failed.\n " .
		   $self->{__PACKAGE__. '.dbHandle'}->errstr(),
		   -HelpMsg => $self->{HHTML}->database_error()
		  );
}

sub query {
    #
    # Params: ( -sql=>, -bind_cols=> [, -want_hash=>].
    #
    # Pre:
    # -sql is the sql statment to perform the query.
    # -bind_cols is an ARRAY ref. to SCALAR refs. to fields to be bound in
    #  the table specified in -sql.
    # -want_hash indicates whether the returning function(a ref.) is a ref. to
    #  fetchrow_hashref() or not.
    #
    # Post:
    # -Returns a fetching function(ref.) based on -sql.
    #  A ref. to fetchrow_arrayref() is returned if -want_hash is not defined;
    #  otherwise a ref. to fetchrow_hashref() is returned.
    #
    my ($self, $sql, $bind_cols, $want_hash);
    $self = shift;
    ($sql, $bind_cols, $want_hash)
      = $self->rearrange( ['SQL', 'BIND_COLS', 'WANT_HASH'], @_ );

    # Prepare query statement handle.
    eval {
	undef $self->{__PACKAGE__. '.stHandle'} if
	  defined($self->{__PACKAGE__. '.stHandle'});
	$self->{__PACKAGE__. '.stHandle'} =
	  ($self->{__PACKAGE__. '.dbHandle'}) -> prepare($sql);
    };
    $self->fatal(
		 -msg => 'Our database is under construction.',
		 -alertMsg => "Database error: $sql cannot be prepared.\n  " .
		              $self->{__PACKAGE__. '.dbHandle'}-> errstr(),
		 -HelpMsg => $self->{HHTML}->database_error()
		)
      if $@;

    # Executes the statement.
    eval { ($self->{__PACKAGE__. '.stHandle'}) -> execute };
    $self->fatal(
		 -msg => 'Our database is under construction.',
		 -alertMsg => "Database error: $sql execution failed.\n  " .
		              $self->{__PACKAGE__. '.dbHandle'}->errstr(),
		 -HelpMsg => $self->{HHTML}->database_error()
		)
      if $@;

    # Binds the columns.  Note: bind columns need to be an array of SCALAR refs.
    eval { $self->{__PACKAGE__. '.stHandle'}->bind_columns(undef, @$bind_cols) };
    $self->fatal(
		 -msg => 'Our database is under construction.',
		 -alertMsg =>
		 "Database error: columns binding for $sql failed.\n  " .
		 $self->{__PACKAGE__. '.dbHandle'}->errstr(),
		 -HelpMsg => $self->{HHTML}->database_error()
		)
      if $@;
    
    # Returns a ref. to a fetching function.
    return sub { ($self->{__PACKAGE__. '.stHandle'}) -> fetchrow_arrayref(); }
      unless defined( $want_hash );
    return sub { ($self->{__PACKAGE__. '.stHandle'}) -> fetchrow_hashref(); };
}

sub finish {
    # Finishes a statement execution.
    my $self = shift;
    eval {
	($self->{__PACKAGE__.'.stHandle'}) ->  finish;
	undef $self->{__PACKAGE__.'.stHandle'};
    } if defined($self->{__PACKAGE__.'.stHandle'});
    $self->fatal(-msg => 'Our database is under construction.',
		 -alertMsg =>
		 "Database error: SQL statement failed to finish properly.\n  " .
		 $self->{__PACKAGE__. '.dbHandle'}->errstr(),
		 -HelpMsg => $self->{HHTML}->database_error()
		)
      if $@;
}

sub disconnect {
    # Disconnect this database session.
    my $self = shift;
    eval {
	($self->{__PACKAGE__. '.dbHandle'}) -> disconnect;
	undef $self->{__PACKAGE__.'.dbHandle'};
    } if defined($self->{__PACKAGE__.'.dbHandle'});
    $self->fatal(-msg => 'Our database is under construction.',
		 -alertMsg =>
		 "Database error: database disconnection failed.\n  " .
		 $self->{__PACKAGE__. '.dbHandle'}->errstr(),
		 -HelpMsg => $self->{HHTML}->database_error()
		)
      if $@;
}

sub done {
    # Finishes a statement execution and disconnect this database session.
    my $self = shift;
    $self->finish();
    $self->disconnect();
}

1;
__DATA__

1;
__END__

=pod

=head1 NAME

LibWeb::Database - A GENERIC DATABASE DRIVER FOR LIBWEB APPLICATIONS

=head1 SUPPORTED PLATFORMS

=over 2

=item BSD, Linux, Solaris and Windows.

=back

=head1 REQUIRE

=over 2

=item *

DBI

=back

=head1 ISA

=over 2

=item *

LibWeb::Core

=back

=head1 SYNOPSIS

  use LibWeb::Database;
  my $db = new LibWeb::Database();

  my ($sql, $user, $host, $fetch, $result);
  $sql = "select USER_TABLE_USER_NAME, USER_TABLE_USER_HOST ".
         "from USER_TABLE ".
         "where USER_TABLE_LOGIN_STATUS = ".
         "LOGGED_IN";

  $fetch = $db->query(
                       -sql => $sql,
                       -bind_cols => [\$user, \$host]
                     );

  while ( &$fetch ) {
      $result .= "$user $host\n";
  }

  $db->done();

  print "Content-Type: text/html\n\n";
  print "The following users have logged in: $result";

=head1 ABSTRACT

As long as you have the proper DBD installed for your database, you
can use this class to interact with your database in your LibWeb
applications.

The current version of LibWeb::Database is available at

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

B<do()>

Params:

  -sql => 

Pre:

=over 2

=item *

-sql is a valid sql statement.

=back

Post:

=over 2

=item *

Return the number of rows affected by the SQL statement, -sql.

=back

B<query()>

Params:

  -sql=>, -bind_cols=> [, -want_hash=> ]

Pre:

=over 2

=item *

-sql is the sql statement to perform the query,

=item *

-bind_cols is an ARRAY reference to SCALAR references to fields to be
bound in the table specified in -sql,

=item *

-want_hash indicates whether the returning function (a reference) is a
reference to DBI's fetchrow_hashref() or fetchrow_arrayref().

=back

Post:

=over 2

=item *

Returns a reference to a fetching function based on -sql.  A reference
to DBI's fetchrow_arrayref() is returned if -want_hash is not defined;
otherwise a reference to DBI's fetchrow_hashref() is returned.

=back

B<finish()>

Finish a statement execution.

B<disconnect()>

Disconnect the current database session.

B<done()>

Finish a statement execution and disconnect the current database session.

=head1 AUTHORS

=over 2

=item Colin Kong (colin.kong@toronto.edu)

=back

=head1 CREDITS

=head1 BUGS

=head1 SEE ALSO

L<DBI>, L<LibWeb::Core>.

=cut
