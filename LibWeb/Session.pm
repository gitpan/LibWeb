#=============================================================================
# LibWeb::Session -- a component of LibWeb--a Perl library/toolkit for building
#                    World Wide Web applications.

package LibWeb::Session;

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

# For debugging purposes. Should be commented out in production release.

# Use standard library.
use strict;
use vars qw(@ISA $VERSION);

# Use custom library.
require LibWeb::Core;
require LibWeb::Crypt;

#Inheritance.
@ISA = qw(LibWeb::Core);

$VERSION = '0.01';

sub new {
    #
    # Params: $class [, $rc_file]
    #
    # - $class is the class/package name of this package, be it a string
    #   or a reference.
    # - $rc_file is the absolute path to the rc file for LibWeb.
    #
    # Usage: my $object = new LibWeb::Admin([$rc_file]);
    #
    my ($class, $Class, $self);
    $class = shift;
    $Class = ref($class) || $class;

    # Inherit instance variables from the base class.
    $self = $Class->SUPER::new(shift);
    bless($self, $Class);
}

sub DESTROY {}

sub _checkDummyCookieIntegrity {
    #
    # Params:
    # $dummyCookies
    #
    # Pre: 
    # 1. $dummyCookies is a scalar which is the dummy cookie retrieved
    #    from $ENV{HTTP_COOKIE}.
    #
    my $self = shift;
    unless ($_[0] =~ m:^B=.+$:) {
	$self->fatal( -alertMsg => 'Dummy cookie has been tampered with.',
		      -isDisplay => 0 );
	require LibWeb::CGI;
	LibWeb::CGI->new()->redirect( 
				     -url => $self->{LM_IN},
				     -cookie => $self->prepare_deauth_cookie()
				    );
    }
    return 1;
}

sub _getAuthInfoFromCookie {
    #
    # Params:
    # [$isJustLogin] (scalar).
    #
    # Pre:
    # 1. Parameter `$isJustLogin' is to indicate whether this is the first login
    #    check.  This parameter should be defined in order to check whether the
    #    remote Web browser is cookie enabled when first logging in.
    # 2. A dummy cookie (see sub _authenticateLogin()) must be set and sent
    #    to client Web browser before hand.  This cookie must came before
    #    the auth. cookie (if any) in the $ENV{HTTP_COOKIE} string.
    # 3. The auth. cookie must came after the dummy cookie in the $ENV{HTTP_COOKIE}
    #    string i.e. in the second position.
    #
    # Post:
    # 1. Output an error message and exit the program if integrity of the dummy
    #    cookies have been tampered with.  This is achieved by checking the positions
    #    of the dummy.
    #
    # 2. Return encrypted auth. info in an array
    #    (sid, issueTime, expireTime, user, ip, uid, MAC) if auth. cookie is set
    #    properly on client Web browser; ow, return undef (null).
    #
    # Since the authentication cookie is stored as one single gigantic string,
    # need to parse it to get sub info within it.
    #
    my ($self, $is_just_login, @cookies, $auth);
    $self = shift;
    $is_just_login = shift;
    
    $self->is_browser_cookie_enabled( $is_just_login );
    @cookies = split /; /, $ENV{HTTP_COOKIE};
    $self->_checkDummyCookieIntegrity($cookies[0]);
    $auth = $cookies[1] if defined($cookies[1]);
    if (defined($auth)) {
	$auth =~ m:^C=z=(.*)&y=(.*)&x=(.*)&w=(.*)&v=(.*)&u=(.*)&t=(.*)$:;
	return ($1, $2, $3, $4, $5, $6, $7);
    }
    return undef;
}

sub is_browser_cookie_enabled {
    #
    # Params:
    # ($is_just_login)
    #
    # Pre:
    # 1. $is_just_login is either 1 or undef indicating whether the user has
    #    just logged in.
    #
    # Post:
    # 1. Print out an error to client Web browser telling the user that his/her
    #    browser is not cookie enabled and exit the program if $ENV{HTTP_COOKIE}
    #    is not defined and $is_just_login is defined.
    # 2. Redirect remote Web browser to a login page if $ENV{HTTP_COOKIE}
    #    is not defined and $is_just_login is undef.
    # 3. Return 1 ow.
    #
    # Caveat: $ENV{HTTP_COOKIE} is still null even if the browser is cookie-enabled
    #         if no cookie is available for our domain.  Therefore a dummy cookie is
    #         sent to client Web browser (it stays for one browser session) to help
    #         indicate that the browser is still cookie-enabled (i.e. to keep
    #         $ENV{HTTP_COOKIE} defined even after DeAuth. cookie has been issued.)
    #         For details, see sub _authenticateLogin() where the dummy cookie is
    #         first set.
    #
    my ($self, $is_just_login);
    $self = shift;
    $is_just_login = shift;
    unless ( $ENV{HTTP_COOKIE} ) {

	if ( $is_just_login ) {
	    $self->fatal( -msg => 'Your browser is not cookie enabled.',
			  -alertMsg => 'Could not retrieve cookie.',
			  -helpMsg => $self->{HHTML}->cookie_error(),
			  -cookie => $self->prepare_deauth_cookie() );
	} else {
	    require LibWeb::CGI;
	    LibWeb::CGI->new()->redirect( 
					 -url => $self->{LM_IN},
					 -cookie => $self->prepare_deauth_cookie()
					);
	}
    }

    return 1;
}

sub is_login {
    #
    # Check to see if Web client (browser) has logged in by
    # checking expiration time, IP and MAC in cookie.
    #
    # Params:
    # ($isJustLogin)
    #
    # Pre:
    # 1. Parameter `$isJustLogin' is either 1 or undef is to indicate
    #    whether this is the first login check.  This parameter should be
    #    defined in order to update database's 'NUM_LOGIN_ATTEMPT' when
    #    user first logged in.
    #
    # Post:
    # 1. Retrieve authentication cookies from client Web browser.
    #
    # 2. If cookie values are null/zero, alert admin and redirect user to login
    #    page.
    #
    # 3a.If MAC mis-match (this means possible hacking from remote host), alert
    #    admin and redirect user to login page.
    #
    # 3b.If IP mis-match (this means possible hacking from remote host), alert
    #    admin and redirect user to login page.
    #
    # 3c.Login expired if expiration time reached.  Update database: set
    #    'NUM_LOGIN_ATTEMPT' to 0, alert admin and redirect user to login page.
    #    
    # 4. Nullify and delete all cookies reside on client Web browser immediately
    #    if any of #2 and #3 happens.  Redirect user to login page.  Also, alert
    #    admin by sending him/her an email.
    #
    # 5. If client has officially logged in and none of #2,#3 and #4 happens, set
    #    database's 'NUM_LOGIN_ATTEMPT' to '$libWeb::var->{LOGIN_INDICATOR}' if
    #    parameter $isJustLogin is defined.  This helps indicate that the user is
    #    online (currently login).
    #
    # 6. And finally return an array (user name and uid) in plain text.
    #
    # Note:
    #    'NUM_LOGIN_ATTEMPT' != 0 && != '$libWeb::var->{LOGIN_INDICATOR}' means
    #    there were several attempts to login but unsuccessful solely because
    #    cryptGuess != cryptRealPass.  Need to re-flush it to 0 manually
    #    after 24 hours of receiving the alert email if this value == the max
    #    login attempt allowed ($self->{MAX_LOGIN_ATTEMPT_ALLOWED}.
    #
    my ($self, $isJustLogin, $crypt, $alertMsg, $userName, $uid, $macKey,
	$preRealMAC, $realMAC, $realIP, $decryptExpireTime, $gmcDecryptExpireTime,
	$db, $log, $sqlStatement);
    $self = shift;
    $isJustLogin = shift;
    $crypt = LibWeb::Crypt->new();
    my(
       $cipher_key, $cipher_algorithm, $cipher_format,
       $digest_key, $digest_algorithm, $digest_format
      )
      = (
	 $self->{CIPHER_KEY}, $self->{CIPHER_ALGORITHM}, $self->{CIPHER_FORMAT},
	 $self->{DIGEST_KEY}, $self->{DIGEST_ALGORITHM}, $self->{DIGEST_FORMAT}
	);
    #================== #1 ===============================
    my ($sid, $issueTime, $expireTime, $user, $guessIP, $guessCUID, $guessMAC) =
      $self->_getAuthInfoFromCookie($isJustLogin);
    #================== #2 ===============================
    unless ( defined($sid) && defined($issueTime) && defined($expireTime) &&
	     defined($user) && defined($guessIP) && defined($guessCUID) &&
	     defined($guessMAC) ) {

	$self->fatal( -alertMsg => 'No auth. cookies!!!', -isDisplay => 0 );
	require LibWeb::CGI;
	LibWeb::CGI->new()->redirect( 
				     -url => $self->{LM_IN},
				     -cookie => $self->prepare_deauth_cookie()
				    );
    }
    #================== #3 ===============================
    # Note: some roxies have rotating IPs, can't check their IP in that case.
    #       How to get ``true'' IP of remote browser?
    #if ( $ENV{REMOTE_HOST} =~ m:^proxy: ) { $realIP = $guessIP; }
    if ( $ENV{HTTP_VIA} ) { $realIP = $guessIP; }
    else {
	$realIP = $crypt->generate_digest(
					 -data => $ENV{REMOTE_ADDR},
					 -key => $digest_key,
					 -algorithm => $digest_algorithm,
					 -format => $digest_format
					);
    }
    $macKey = $self->{MAC_KEY};
    $preRealMAC =
      $crypt->generate_MAC(
			   -data => $sid.$issueTime.$expireTime.$user.$realIP.$guessCUID.$macKey,
			   -key => $macKey,
			   -algorithm => $digest_algorithm,
			   -format => $digest_format
			  );
    $realMAC = $crypt->generate_MAC(
				    -data => $macKey.$preRealMAC,
				    -key => $macKey,
				    -algorithm => $digest_algorithm,
				    -format => $digest_format
				   );
    #=============== #3a =====================
    unless ($guessMAC eq $realMAC) {
	$alertMsg = "MAC mis-match!!!\nGuessMAC: $guessMAC\nRealMAC: $realMAC\n";
	$self->fatal( -alertMsg => $alertMsg, -isDisplay => 0 );
	require LibWeb::CGI;
	LibWeb::CGI->new()->redirect( 
				     -url => $self->{LM_IN},
				     -cookie => $self->prepare_deauth_cookie()
				    );
    }
    #=============== #3b =====================
    unless ($guessIP eq $realIP) {
	$alertMsg = "IP mis-match!!!\nGuessIP: $guessIP\nRealIP: $realIP\n";
	$self->fatal( -alertMsg => $alertMsg, -isDisplay => 0 );
	require LibWeb::CGI;
	LibWeb::CGI->new()->redirect( 
				     -url => $self->{LM_IN},
				     -cookie => $self->prepare_deauth_cookie()
				    );
    }
    #=============== #3c =====================
    $userName = $crypt->decrypt_cipher(
				       -cipher => $user,
				       -key => $cipher_key,
				       -algorithm => $cipher_algorithm,
				       -format => $cipher_format
				      );
    $uid = $crypt->decrypt_cipher(
				  -cipher => $guessCUID,
				  -key => $cipher_key,
				  -algorithm => $cipher_algorithm,
				  -format => $cipher_format
				 );
    $decryptExpireTime =
      $crypt->decrypt_cipher(
			     -cipher => $expireTime,
			     -key => $cipher_key,
			     -algorithm => $cipher_algorithm,
			     -format => $cipher_format
			    );
    unless ( $decryptExpireTime > time() ) {

	require LibWeb::Database;
	$db = new LibWeb::Database();
	
	# Flush the databse.  Set `NUM_LOGIN_ATTEMPT' to 0.
	$sqlStatement = "update $self->{USER_LOG_TABLE} " .
	                "set $self->{USER_LOG_TABLE_NUM_LOGIN_ATTEMPT}=0 " .
	                "where $self->{USER_LOG_TABLE_UID}=$uid";
	$db->do( -sql => $sqlStatement );
	$db->finish();

	# Alert admin and redirect user to login page.
	$gmcDecryptExpireTime = localtime($decryptExpireTime);
	$alertMsg = "Login session expired.\n " .
	            "Current time: " . localtime() . "\n " .
	            "Expire time: $gmcDecryptExpireTime\n";
	$self->fatal( -alertMsg => $alertMsg, -isDisplay => 0 );
	require LibWeb::CGI;
	LibWeb::CGI->new()->redirect( 
				     -url => $self->{LM_IN},
				     -cookie => $self->prepare_deauth_cookie()
				    );
    }
    #=============== #5 ======================
    if ( $isJustLogin ) {

	require LibWeb::Database;
	$db = new LibWeb::Database();

	my $time = localtime();
	my $ip = $ENV{REMOTE_ADDR};
	my $host = $ENV{REMOTE_HOST};
	$sqlStatement = "update $self->{USER_LOG_TABLE} " .
	                "set $self->{USER_LOG_TABLE_NUM_LOGIN_ATTEMPT}=" .
			"$self->{LOGIN_INDICATOR}, " .
	                "$self->{USER_LOG_TABLE_LAST_LOGIN}='$time', " .
	                "$self->{USER_LOG_TABLE_IP}='$ip', " .
	                "$self->{USER_LOG_TABLE_HOST}='$host' " .
	                "where $self->{USER_LOG_TABLE_UID}=$uid";
	$db->do( -sql => $sqlStatement );
	$db->finish();
    }
    return ($userName, $uid);
}

# Selfloading methods declaration.
sub LibWeb::Session::prepare_deauth_cookie ;
1;
__DATA__

sub prepare_deauth_cookie {
    #
    # Params:
    # none.
    #
    # Pre:
    # 1. None.
    #
    # Post:
    # 1. Return prepared DeAuth cookies (array ref) for nullifying
    #    all cookies for this site on client Web browser by preparing zero/null
    #    auth cookies with an expiration date in the past.
    #
    my $self = shift;
    return
      ['B=0; path=/',
       'C=z=0&y=0&x=0&w=0&v=0&u=0&t=0; path=/; expires=' . $self->{CLASSIC_EXPIRES}];
}

1;
__END__

=pod

=head1 NAME

LibWeb:: - SESSIONS MANAGEMENT FOR LIBWEB APPLICATIONS

=head1 SUPPORTED PLATFORMS

=over 2

=item BSD, Linux, Solaris and Windows.

=back

=head1 REQUIRE

=over 2

=item *

LibWeb::Crypt

=back

=head1 ISA

=over 2

=item *

LibWeb::Core

=back

=head1 SYNOPSIS

  use LibWeb::Session;
  my $session = new LibWeb::Session();

  my ($user_name, $user_id) = $session->is_login();

      # or

  my ($user_name, $user_id) = $session->is_login(1);

=head1 ABSTRACT

This class manages session authentication after the remote user has logged in.

The current version of LibWeb::Session is available at

   http://libweb.sourceforge.net
   ftp://libweb.sourceforge/pub/libweb

Several LibWeb applications (LEAPs) have be written, released and
are available at

   http://leaps.sourceforge.net
   ftp://leaps.sourceforge.net/pub/leaps

=head1 TYPOGRAPHICAL CONVENTIONS AND TERMINOLOGY

Variables in all-caps (e.g. MAX_LOGIN_ATTEMPT_ALLOWED) are those variables
set through LibWeb's rc file.  Please read L<LibWeb::Core> for
more information.  All `error/help messages' mentioned can be found at
L<LibWeb::HTML::Error> and they can be customized by ISA (making a sub-class of)
LibWeb::HTML::Default. Please see L<LibWeb::HTML::Default> for details.
Method's parameters in square brackets means optional.

=head1 DESCRIPTION

=head2 METHODS

B<is_login()>

Params:

  [ is_just_logged_in ]

Pre:

=over 2

=item *

Parameter `is_just_logged_in' is either 1 or undef.  This is to indicate
whether this is the first login check.  This parameter should be
defined in order to update database's USER_LOG_TABLE.NUM_LOGIN_ATTEMPT when
user first logged in; possibly in the first script invoked after the user
has been authenticated.

=back

Post:

=over 2

=item *

Retrieve authentication cookies from client Web browser,

=item *

if cookie values are null/zero, send an alert e-mail to ADMIN_EMAIL and redirect
the remote user to the login page (LM_IN),

=item *

if MAC mis-match (this means possible spoofing from remote host), send an alert
e-mail to ADMIN_EMAIL and redirect the remote user to the login page (LM_IN),

=item *

if IP mis-match (this means possible spoofing from remote host), send an alert
e-mail to ADMIN_EMAIL and redirect the remote user to the login page (LM_IN),

=item *

login is expired if expiration time reached.  Update database: set
USER_LOG_TABLE.NUM_LOGIN_ATTEMPT to 0, send an alert e-mail to ADMIN_EMAIL and
redirect the remote user to the login page (LM_IN),

=item *

nullify and delete all cookies reside on client Web browser immediately
if any of item 2, 3, 4 or 5 happens.  Send an alert e-mail to ADMIN_EMAIL and
redirect the remote user to the login page (LM_IN),

=item *

if client has officially logged in and none of item 2, 3, 4 or 5 happens, set
USER_LOG_TABLE.NUM_LOGIN_ATTEMPT to LOGIN_INDICATOR if parameter
`is_just_logged_in' is defined.  This helps to indicate that the user is
online (currently logged in), and

=item *

finally return an array (user name and uid) in plain text.

=back

Note:
USER_LOG_TABLE.NUM_LOGIN_ATTEMPT != 0 && != LOGIN_INDICATOR means there were
several attempts to login but unsuccessful solely because incorrect password
were entered by the remote user.  You need to re-flush NUM_LOGIN_ATTEMPT to 0
manually after 24 hours (no rigorous reason why it should be 24 hours) of receiving
the alert e-mail if this value == MAX_LOGIN_ATTEMPT_ALLOWED.

=head1 AUTHORS

=over 2

=item Colin Kong (colin.kong@toronto.edu)

=back

=head1 CREDITS


=head1 BUGS


=head1 SEE ALSO

L<LibWeb::Admin>, L<LibWeb::Core>, L<LibWeb::Crypt>.

=cut
