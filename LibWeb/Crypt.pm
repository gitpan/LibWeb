#==============================================================================
# LibWeb::Crypt -- Encryption for libweb applications.

package LibWeb::Crypt;

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

# $Id: Crypt.pm,v 1.4 2000/07/18 06:33:30 ckyc Exp $

#-#############################
# Use standard library.
use strict;
use vars qw($VERSION @ISA);

#-#############################
# Use custom library.
# This class should not require LibWeb::Core.
# You have been warned!.
require Crypt::CBC;
require LibWeb::Class;
##require Crypt::Blowfish; Crypt::IDEA, or Crypt::DES;

#-#############################
# Version.
$VERSION = '0.02';

#-#############################
# Inheritance.
@ISA = qw(LibWeb::Class);

#-#############################
# Methods.
sub new {
    my ($class, $Class, $self);
    $class = shift; 
    $Class = ref($class) || $class;
    $self = $Class->SUPER::new(shift);
    bless($self, $Class);
}

sub DESTROY {}

sub encrypt_cipher {
    #
    # Params: -data=>, -key=>, -algorithm=>, -format=>
    # e.g. -algorithm => 'Crypt::Blowfish' / 'Crypt::DES' / 'Crypt::IDEA'
    # e.g. -format => 'binary' / 'hex'.
    # This makes use of Crypt::CBC module.  Accept data of arbitrary length.
    #
    my ($self, $data, $key, $algorithm, $format, $cipher);
    $self = shift;
    ($data, $key, $algorithm, $format) =
      $self->rearrange(['DATA', ,'KEY', 'ALGORITHM', 'FORMAT'], @_);

    # Makes perl taint mode happy.  $1 is $cipherAlgorithm in disguise.
    $algorithm =~ m:(.*):;
    $cipher = new Crypt::CBC($key, $1);
    return (uc($format) eq 'HEX') ?
      $cipher->encrypt_hex($data) : $cipher->encrypt($data); 
}

sub decrypt_cipher {
    #
    # Params: -cipher=>, -key=>, -algorithm=>, -format=>
    # e.g. -algorithm => 'Crypt::Blowfish' / 'Crypt::DES' / 'Crypt::IDEA'
    # e.g. -format => 'binary' / 'hex'.
    # This makes use of Crypt::CBC module.  Accept cipher generated by
    # encrypt_cipher() of this module (LibWeb).
    #
    my ($self, $cipherText, $key, $algorithm, $format, $cipher);
    $self = shift;
    ($cipherText, $key, $algorithm, $format) =
      $self->rearrange(['CIPHER', 'KEY', 'ALGORITHM', 'FORMAT'], @_);

    # Makes perl taint mode happy.  $1 is $cipherAlgorithm in disguise.
    $algorithm =~ m:(.*):;
    $cipher = new Crypt::CBC($key, $1);
    return (uc($format) eq 'HEX') ?
      $cipher->decrypt_hex($cipherText) : $cipher->decrypt($cipherText);
}

sub encrypt_password {
    #
    # Params: $plainPassword.
    # 
    # Encrypts argument (usually a password) and returns a
    # 13-character long string.  Random salt.
    # This uses the perl's crypt().  May migrate to use
    # MD5 in later release of this library.
    #
    my ($self, @salt_chars, $salt);
    $self = shift;
    @salt_chars = ('A'..'Z', 0..9, 'a'..'z','.','/');
    $salt = join '',@salt_chars[rand 64, rand 64];
    return crypt($_[0] ,$salt);
}

1;
__END__

=head1 NAME

LibWeb::Crypt - Encryption for libweb applications

=head1 SUPPORTED PLATFORMS

=over 2

=item BSD, Linux, Solaris and Windows.

=back

=head1 REQUIRE

=over 2

=item *

Crypt::CBC

=item *

Crypt::Blowfish (recommended), Crypt::DES or Crypt::IDEA

=back

=head1 ISA

=over 2

=item *

LibWeb::Class

=back

=head1 SYNOPSIS

  use LibWeb::Crypt;
  my $c = new LibWeb::Crypt();

  my $cipher =
      $c->encrypt_cipher(
			 -data => $plain_text,
			 -key => $key,
			 -algorithm => 'Crypt::Blowfish',
			 -format => 'hex'
			);

  my $plain_text =
      $c->decrypt_cipher(
			 -cipher => $cipher,
			 -key => $key,
			 -algorithm => 'Crypt::Blowfish',
			 -format => 'hex'
			);

  my $encrypted_pass =
      $c->encrypt_password('password_in_plain_text');

=head1 ABSTRACT

This class provides methods to

=over 2

=item *

encrypt data of arbitrary length into cipher (binary or hex) by using
the algorithm provided by Crypt::Blowfish, Crypt::DES or Crypt::IDEA,
and chained by using Crypt::CBC,

=item *

decrypt ciphers generated by this class,

=item *

encrypt plain text password by using the perl's crypt() routine with
randomly chosen salt.

=back

The current version of LibWeb::Crypt is available at

   http://libweb.sourceforge.net

Several LibWeb applications (LEAPs) have be written, released and
are available at

   http://leaps.sourceforge.net

=head1 DESCRIPTION

=head2 METHODS

B<encrypt_cipher()>

Params:

  -data=>, -key=>, -algorithm=>, -format=>

Pre:

=over 2

=item *

C<-data> is the data to be encrypted as cipher,

=item *

C<-key> is the private key such the same key is needed to decrypt the
cipher (sorry, I do not have a rigorous definition for that right
now),

=item *

C<-algorithm> must be 'Crypt::Blowfish', 'Crypt::DES' or
'Crypt::IDEA',

=item *

C<-format> is the format of the cipher, which must be either 'binary'
or 'hex'.

=back

Post:

=over 2

=item *

Encrypt C<-data> and return the cipher.

=back

Note: this makes use of the Crypt::CBC module and therefore can accept
data of arbitrary length.

B<decrypt_cipher()>

Params:

  -cipher=>, -key=>, -algorithm=>, -format=>

Pre:

=over 2

=item *

C<-cipher> is the cipher to be decrypted,

=item *

C<-key> is the private key such that it is the same key used to
encrypt the original data of C<-cipher> (sorry, I do not have a
rigorous definition for that right now),

=item *

C<-algorithm> must be 'Crypt::Blowfish', 'Crypt::DES' or 'Crypt::IDEA'
and it must match the algorithm used when preparing the cipher,

=item *

C<-format> is the format of the cipher, which must be either 'binary'
or 'hex'.

=back

Post:

=over 2

=item *

Decrypt C<-cipher> and return the original data.

=back

B<encrypt_password()>

Usage:

  my $encrypted_password =
      $crypt->encrypt_password($password_in_plain_text);

Encrypts the parameter (usually a password) and returns a 13-character
long string using the perl's crypt() routine and randomly chosen salt.

=head1 AUTHORS

=over 2

=item Colin Kong (colin.kong@toronto.edu)

=back

=head1 CREDITS

=over 2

=item Lincoln Stein (lstein@cshl.org)

=back

=head1 BUGS


=head1 SEE ALSO


L<Digest::HMAC>, L<Digest::SHA1>, L<Digest::MD5>, L<Crypt::CBC>,
L<Crypt::Blowfish>, L<Crypt::DES>, L<Crypt::IDEA>, L<LibWeb::Admin>,
L<LibWeb::Digest>, L<LibWeb::Session>.

=cut
