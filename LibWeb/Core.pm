#==============================================================================
# LibWeb::Core -- a component of LibWeb--a Perl library/toolkit for building
#                 World Wide Web applications.

package LibWeb::Core;

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
use SelfLoader;
use strict;
use vars qw($VERSION @ISA %RC $OS);

# Use custom library.
require LibWeb::Class;

$VERSION = '0.01';
@ISA = qw(LibWeb::Class);

sub new {
    #
    # Params: $class [, $rc_file, $error_object]
    #
    # - $class is the class/package name of this package, be it a string
    #   or a reference.
    # - $rc_file is the absolute path to the rc file for LibWeb.
    # - $error_object is a reference to a perl object for printing out
    #   error/help message to users when error occurs.
    #
    # Usage: No, you don't use LibWeb::Core directly in client codes.
    #
    my ($class, $self, %rc);
    $class = shift;

    # Read the rc file if haven't done so in this CGI session.
    # Read rc and take care of portability issues only once for sake
    # of performance!  But the ``%rc = %RC'' is still an expensive way
    # to do that.  Any better approach?
    if (%RC) {
	%rc = %RC;
	bless(\%rc, ref($class) || $class);
    } else {
	$self = do "$_[0]" or die "Couldn't read rc: $!\n";
	$self->{HHTML} = $_[1] or do { require LibWeb::HTML::Error; LibWeb::HTML::Error->new(); };
	_make_portable($self);
	%RC = %{ $self };
	bless($self, ref($class) || $class);
    }
}

sub DESTROY {}

sub _make_portable {
    #
    # Some portability tricks stolen from CGI.pm 2.66.
    #
    my $self = shift;
    # FIGURE OUT THE OS WE'RE RUNNING UNDER
    # Some systems support the $^O variable.  If not
    # available then require() the Config library
    unless ($OS) {
	unless ($OS = $^O) {
	    require Config;
	    $OS = $Config::Config{'osname'};
	}
    }
    if ($OS=~/Win/i) {
	$OS = 'WINDOWS';
    } elsif ($OS=~/vms/i) {
	$OS = 'VMS';
    } elsif ($OS=~/bsdos/i) {
	$OS = 'UNIX';
    } elsif ($OS=~/dos/i) {
	$OS = 'DOS';
    } elsif ($OS=~/^MacOS$/i) {
	$OS = 'MACINTOSH';
    } elsif ($OS=~/os2/i) {
	$OS = 'OS2';
    } else {
	$OS = 'UNIX';
    }
    # The path separator is a slash, backslash or semicolon, depending
    # on the paltform.
    $self->{PATH_SEP} = {
			 UNIX=>'/', OS2=>'\\', WINDOWS=>'\\', DOS=>'\\',
			 MACINTOSH=>':', VMS=>'/'
			}->{$OS};    
    # Define the CRLF sequence.  I can't use a simple "\r\n" because the meaning
    # of "\n" is different on different OS's (sometimes it generates CRLF, sometimes
    # LF and sometimes CR).  The most popular VMS web server doesn't accept CRLF --
    # instead it wants a LR.  EBCDIC machines don't use ASCII, so \015\012 means
    # something different.  I find this all really annoying. -- Lincoln.
    my $EBCDIC = "\t" ne "\011";
    if ($OS eq 'VMS') {
	$self->{CRLF} = "\n";
    } elsif ($EBCDIC) {
	$self->{CRLF} = "\r\n";
    } else {
	$self->{CRLF} = "\015\012";
    }
}


# Selfloading methods declaration.
sub LibWeb::Core::_get_auth_info_from_cookie_for_admin ;
sub LibWeb::Core::alert_admin ;
sub LibWeb::Core::debug_print ;
sub LibWeb::Core::fatal ;
sub LibWeb::Core::sanitize ;
sub LibWeb::Core::send_cookie ;
sub LibWeb::Core::send_mail ;
1;
__DATA__

sub _get_auth_info_from_cookie_for_admin {
    #
    # Params: None.
    #
    # Pre:
    # 1. A dummy cookie (see sub _authenticateLogin()) must be set and sent
    #    to client Web browser before hand.  This cookie must came before
    #    the auth. cookie (if any) in the $ENV{HTTP_COOKIE} string.
    # 2. The auth. cookie must came after the dummy cookie in the $ENV{HTTP_COOKIE}
    #    string i.e. in the second position.
    #
    # Post:
    # 1. Return encrypted auth. info in an array (expireTime, user, $uid) if
    #    auth. cookie is set properly on client Web browser; ow, return undef (null).
    #
    # Since the authentication cookie is stored as one single gigantic string,
    # need to parse it to get sub info within it.
    #
    my ($self, @cookies, $auth);
    $self = shift;
    # Commented out to prevent infinit loop.  Also is_browser_cookie_enabled()
    # is defined in LibWeb::Admin, not here any more.
    #$self->is_browser_cookie_enabled();
    if ( defined $ENV{'HTTP_COOKIE'} ) {
	@cookies = split /; /, $ENV{HTTP_COOKIE};
	# Commented out to prevent infinit loop.  Also _checkDummyCookieIntegrity()
	# is defined in LibWeb::Admin, not here any more.
	#$self->_checkDummyCookieIntegrity($cookies[0]);
	$auth = $cookies[1] if defined($cookies[1]);
	if (defined($auth)) {
	    $auth =~ m:^C=z=.*&y=.*&x=(.*)&w=(.*)&v=.*&u=(.*)&t=.*$:;
	    return ($1, $2, $3);
	}
    }
    return undef;
}

sub alert_admin {
    #
    # Arg: (-msg=>)
    #
    # Pre:
    # - -msg must be a SCALAR ref.
    #
    # Post: Send admin an email indicating what errors have occured.
    #
    my ($self, $crypt, $env_key, $env_value, $pack, $file, $line, $subname,
	$hashargs, $wantarray, $evaltext, $is_require, $i, $msg, $message,
	$expireTime, $user, $uid, $cryptExpireTime, $cryptUser, $cryptUID);
    $self = shift;
    ($msg) = $self->rearrange(['MSG'], @_);
    require LibWeb::Crypt;
    $crypt = LibWeb::Crypt->new();
    # Fetch user info from auth Cookies if any.
    ($expireTime, $user, $uid) = ('N/A', 'N/A', 'N/A');
    ($cryptExpireTime, $cryptUser, $cryptUID)
      = $self -> _get_auth_info_from_cookie_for_admin();
    $uid = $crypt->decrypt_cipher(
				  -cipher => $cryptUID,
				  -key => $self->{CIPHER_KEY},
				  -algorithm => $self->{CIPHER_ALGORITHM},
				  -format => $self->{CIPHER_FORMAT}
				 )
      if defined($cryptUID);
    $user = $crypt->decrypt_cipher(
				   -cipher => $cryptUser,
				   -key => $self->{CIPHER_KEY},
				   -algorithm => $self->{CIPHER_ALGORITHM},
				   -format => $self->{CIPHER_FORMAT}
				  )
      if defined($cryptUser);
    $expireTime =
      localtime(
		$crypt->decrypt_cipher(
				       -cipher => $cryptExpireTime,
				       -key => $self->{CIPHER_KEY},
				       -algorithm => $self->{CIPHER_ALGORITHM},
				       -format => $self->{CIPHER_FORMAT}
				      )
	       )
	if defined($cryptExpireTime);
    $message =
      "\n\nCookies info grabbing: \nUsername: $user \nUID: $uid \nExpire: $expireTime\n";
    # Generate stack traces.
    $i = 0;
    while (($pack,$file,$line,$subname,$hashargs,
	    $wantarray,$evaltext,$is_require) = caller($i++)) {
	$message .= "\n\nStack trace #$i:\n";
	$message .= "Package: $pack\n" if defined $pack;
	$message .= "File: $file\n" if defined $file;
	$message .= "Line: $line\n" if defined $line;
	$message .= "Sub: $subname\n" if defined $subname;
	$message .= "Hashargs: $hashargs\n" if defined $hashargs;
	$message .= "Wantarray: $wantarray\n" if defined $wantarray;
	$message .= "Evaltext: $evaltext\n" if defined $evaltext;
	$message .= "Is_require: $is_require\n" if defined $is_require;
    }
    $message .= "\n\n\n";
    # Fetch Web client and server info.
    while (($env_key,$env_value) = each (%ENV)) {
	$message .= "$env_key: $env_value\n";
    }
    # Just print the error message and return immediately; i.e. don't send mail
    # while debugging.
    if ( $self->{DEBUG} ) {
	print "Content-Type: text/html$self->{CRLF}$self->{CRLF}"
	  if $ENV{GATEWAY_INTERFACE};
	print $$msg . $message;
	return undef;
    }
    # Alert the admin by sending him/her an email.
    $self->send_mail( -to => $self->{ADMIN_EMAIL},
		      -from => $self->{ADMIN_EMAIL},
		      -subject => 'Server Alert!',
		      -msg => \ ( $$msg . $message ) )
      if ( $self->{IS_MAIL_DEBUG_TO_ADMIN} );
    return undef;
}

sub debug_print {
    #
    # Arg: $debugMsg.
    # If LibWeb::var->{DEBUG} == 1, print $debugMsg and return undef.
    # Do nothing otherwise.
    #
    my $self = shift;
    if ( $self->{DEBUG} && $_[0] ) {
	print "Content-Type: text/html$self->{CRLF}$self->{CRLF}"
	  if $ENV{GATEWAY_INTERFACE};
	print "$_[0]$self->{CRLF}";
    }
    return undef;
}

sub fatal {
    #
    # Params: (-msg [,-input=>, -helpMsg=>, -alertMsg=>, -isAlert=>1,-isDisplay=>1,
    #        -ccokie=>]).
    # Print an error message to Web client if `isDisplay' is defined.
    # Alert admin if `isAlert' is defined.  And abort the program except
    # when -isDisplay is defined and equal to 0.  -input is the user input
    # that triggers this fatal error.  -helpMsg is any instruction to guide
    # Web client users, which can be HTML.  -alertMsg will not be displayed to
    # clients but will appear in the email sent to admin.  'cookie' is the cookie
    # to send to client Web browser when 'isDisplay' is defined and equal to 1.
    # The default for -isAlert and -isDisplay is 1 if not specified.
    # -msg, -input, -alertMsg must be scalar.
    # -helpMsg must be SCALAR ref. to HTML.
    #
    my ($self, $msg, $input, $helpMsg, $alertMsg, $isAlert, $isDisplay, $cookie,
	$error_display, $adminMsg);
    $self = shift;
    ($msg, $input, $helpMsg, $alertMsg, $isAlert, $isDisplay, $cookie) =
      $self->rearrange
	(['MSG', 'INPUT', 'HELPMSG', 'ALERTMSG', 'ISALERT', 'ISDISPLAY',
	  'COOKIE'], @_);

    unless (defined($isDisplay) && $isDisplay == 0) {
	# Print the HTML header if this script is in a Web server environment.
	if ( defined $ENV{GATEWAY_INTERFACE} ) {
	    $self->send_cookie($cookie) if defined($cookie);
	    print "Content-Type: text/html$self->{CRLF}$self->{CRLF}";
	}
	print ${ $self->{HHTML}->display_error(
					       $self,
					       $msg || ' ',
					       $input || ' ',
					       $helpMsg || \ (' ')
					      )
               };
    }    
    unless (defined($isAlert) && $isAlert == 0) {
	$adminMsg = defined($input) ? "\nUser input: \n$input\n" : undef;
	$adminMsg .= defined($msg) ? "\nMsg for user: \n$msg\n" : undef;
	$adminMsg .= defined($alertMsg) ? "\nMsg for admin: \n$alertMsg\n" : undef;
	$adminMsg .= defined($helpMsg) ? "\nHelp msg for user: \n$$helpMsg\n" : undef;
	$self->alert_admin( -msg => \$adminMsg );
    }
    exit(0) unless (defined($isDisplay) && $isDisplay == 0);
}

sub sanitize {
    #
    # Sanitizes Web client inputs.
    #
    # Params: (-text=>'plain_text' || -html=>'html_text' || -email=>'email_here'
    #        [, -allow=>[charaters allowed] ).
    #
    # -text/-html/-email is a scalar or an ARRAY ref. to scalars.
    # -allow is an ARRAY ref. to special characters allowed.  It's effective
    #  only when you use it with -text.
    # Array is returned if want array.
    #
    # -text: sanitize text by removing all meta characters.
    # -html: sanitize text by rmoving html <> tags.
    # -email: sanitize email addresses.  Print an error message and
    #         abort the program if email is dirty.
    # Can only process one type at a time (i.e. per subroutine call).
    # Colin Kong's meta characters: `~!@#$%^&*,.:;?"'<>{}[]()\|/-_+=\a\n\r\t\f\e\b
    #
    my ($self, $text, $html, $emails, $allow, $count, $meta);
    $self = shift;
    ($text, $html, $emails, $allow) =
      $self->rearrange(['TEXT', 'HTML', 'EMAIL', 'ALLOW'], @_);
    $count = 0;
    $meta = '\`\~\!\@\#\$\%\^\&\*\.\,\:\;\?\"\'\<\>\{\}\[\]\(\)\\\|\/\-\_\+\=';
    # Removes HTML <> tags.
    if (defined($html)) {
	my $offendingText;
	if (ref($html)) {
	    foreach (@$html) {
		$offendingText = $html->[$count];
		$self->fatal(-alertMsg => 'User imput contains HTML tags',
			     -input => $offendingText, -isDisplay => 0)
		  if $html->[$count] =~ s:<[^>]*>: :g;
		$count++;
	    }
	    wantarray ? return @$html : return $html->[0];
	} else {
	    $offendingText = $html;
	    $self->fatal(-alertMsg => 'User imput contains HTML tags',
			 -input => $offendingText, -isDisplay => 0)
	      if $html =~ s:<[^>]*>: :g;
	    return $html;
	}
    }
    # User input sanitizing (plain text; removes all meta characters except those
    # specified in the `-allow' parameter).
    # Also replace all white spaces with normal space.
    if (defined($text)) {
	
	if (defined $allow) {
	    foreach (@$allow) { $_ = "\\$_"; $meta =~ s:\\$_::; }
	}

	if (ref($text)) {
	    foreach (@$text) {
		$self->fatal(-alertMsg => 'User input contains meta-characters',
			     -input => $text->[$count], -isDisplay => 0)
		  if $text->[$count] =~ s:([$meta]):\\$1:g;
		$self->fatal(-alertMsg => 'User input contains special white-spaces',
			     -input => $text->[$count], -isDisplay => 0)
		  if $text->[$count] =~ tr:\a\n\r\t\f\e\b: :;
		$count++;
	    }
	    wantarray ? return @$text : return $text->[0];   
	} else {
	    $self->fatal(-alertMsg => 'User input contains meta-characters',
			 -input => $text, -isDisplay => 0)
	      if $text =~ s:([$meta]):\\$1:g;
	    $self->fatal(-alertMsg => 'User input contains special white-spaces',
			 -input => $text, -isDisplay => 0)
	      if $text =~ tr:\a\n\r\t\f\e\b: :;
	    return $text;
	}
    }
    # User input (e-mail address) santitizing.
    # Possible (alternative) regex: :^([\w.+-]+)\@([\w.+-]+)$:
    if (ref($emails)) {
	foreach (@$emails) {
	    unless ($emails->[$count]=~ s:(\w{1}[\w-.]*)\@([\w-.]+):$1\@$2:) {
		#$emails->[$count] =~ s:([$meta]):\\$1:g;
		$self->fatal(
			     -msg => 'Invalid e-maill address format',
			     -input => $emails->[$count],
			     -helpMsg => $self->{HHTML}->hit_back_and_edit()
			    );
	    }
	    $count++;
	}
	wantarray ? return @$emails : return $emails->[0];
    } else {
	unless ($emails =~ s:(\w{1}[\w-.]*)\@([\w-.]+):$1\@$2:) {
	    #$emails =~ s:([$meta]):\\$1:g;
	    $self->fatal(
			 -msg => 'Invalid e-maill address format',
			 -input => $emails,
			 -helpMsg => $self->{HHTML}->hit_back_and_edit()
			);
	}
	return $emails;
    }
}

sub send_cookie {
    # This one is here due to inheritance (backward?) issues not yet resolved.
    #
    # Params: $cookies || \@cookies (array ref || scalar)
    # $cookie is an array ref of cookie descriptions which can be feed to client
    # Web Browser manually through the HTTP header.
    # e.g. $cookies = ['cookie_name=cookie_value; path=/',
    #                  'cookie2_name=cookie2_value; path=/'] or
    #      $cookies =  'cookie_name=cookie_value; path=/';
    #
    #
    # Pre:
    # 1. No other HTTP header should be sent before this in a single CGI session.
    #
    # Post:
    # 1.Send the cookie to clent Web browser.
    #
    my ($self, $cookies);
    $self = shift;
    $cookies = shift;
    if ( defined $cookies ) {
	if ( ref($cookies) ) {
	    foreach (@$cookies) { print "Set-Cookie: $_\n"; }
	}
	else { print "Set-Cookie: $cookies\n"; }
    }
    return 1;
}

sub send_mail {
    #
    # Params: (-to [,-bcc] ,-from [,-replyTo] ,-subject, -msg)
    #
    # Pre: -msg is a SCALAR ref. and others are scalars.
    #
    my ($self, $to, $bcc, $from, $replyTo, $subject, $message, $pipe_status);
    $self = shift;
    ($to, $bcc, $from, $replyTo, $subject, $message) =
      $self->rearrange(['TO', 'BCC', 'FROM', 'REPLYTO', 'SUBJECT', 'MSG'], @_);
    $pipe_status = open(MAIL, "|-");
    $self->fatal(-msg => 'Error: couldn\'t send mail',
		 -alertMsg => 'Cannot open to subprocess')
      unless defined($pipe_status);
    # Makes perl taint mode happy.  $1 is $self->{MAIL_PROGRAM} in disguise.
    $self->{MAIL_PROGRAM} =~ m:(.*):;
    exec "$1"
      or $self->fatal(-msg=>'Error: couldn\'t send mail',
		      -alertMsg => 'exec error') if ($pipe_status == 0);
    eval {
	print MAIL "To: $to\n" if defined $to;
	print MAIL "Bcc: $bcc\n" if defined $bcc;
	print MAIL "From: $from\n" if defined $from;
	print MAIL "Reply-to: $replyTo\n" if defined $replyTo;
	print MAIL "X-Mailer: UofTfriends.com Powered Sendmail\n";
	defined($subject) ? print MAIL "Subject: $subject\n\n" :
	                    print MAIL "Subject: (no subject)\n\n";
	print MAIL "$$message";
	print MAIL "\n.\n";
    };
    $self->fatal(-msg => 'Error: couldn\'t send mail',
		 -alertMsg => 'print MAIL error') if $@;
    close MAIL;
}

1;
__END__

=pod

=head1 NAME

LibWeb::Core - THE CORE CLASS FOR LIBWEB MODULES

=head1 SUPPORTED PLATFORMS

=over 2

=item BSD, Linux, Solaris and Windows.

=back

=head1 REQUIRE

=over 2

=item *

LibWeb::HTML::Error

=back

=head1 ISA

=over 2

=item *

LibWeb::Class

=back

=head1 SYNOPSIS

  require LibWeb::Core;
  @ISA = qw(LibWeb::Core);

=head1 ABSTRACT

This class is responsible for reading the LibWeb's rc file, handling portability
issues, printing error and debug messages and sending alert e-mail to the site
administrator should error occur.  You are not supposed to use or ISA this class
directly.  It is ISAed internally by other modules in LibWeb, e.g. LibWeb::Admin,
LibWeb::CGI, LibWeb::Database, LibWeb::HTML::Default and LibWeb::Themes::Default.
You should call the methods presented in this man page through one of those
sub-classes.

The current version of LibWeb::Core is available at

   http://libweb.sourceforge.net
   ftp://libweb.sourceforge/pub/libweb

Several LibWeb applications (LEAPs) have be written, released and
are available at

   http://leaps.sourceforge.net
   ftp://leaps.sourceforge.net/pub/leaps

=head1 TYPOGRAPHICAL CONVENTIONS AND TERMINOLOGY

Variables in all-caps (e.g. ADMIN_EMAIL) are those variables set through
LibWeb's rc file.  `Sanitize' means escaping any illegal character possibly
entered by user in a HTML form.  This will make Perl's taint mode happy and
more importantly make your site more secure.  All `error/help messages'
mentioned can be found at L<LibWeb::HTML::Error> and they can be customized
by ISA (making a sub-class of) LibWeb::HTML::Default.  Please see
L<LibWeb::HTML::Default> for details.  Method's parameters in square brackets
means optional.

=head1 DESCRIPTION

=head2 READING THE LIBWEB RC FILE

You should place your LibWeb rc (config) file outside your WWW document root.
The following shows how a cgi script using LibWeb will typically look like,

  use LibWeb::Session;
  use LibWeb::Database;
  use LibWeb::CGI;
  use LibWeb::Themes::Default;
  use LibWeb::HTML::Default;

  my $rc_file = '/usr/me/.lwrc';

  my $html = new LibWeb::HTML::Default($rc_file);
  my $themes = new LibWeb::Themes::Default();
  my $session = new LibWeb::Session();
  my $db = new LibWeb::Database();
  my $q = new LibWeb::CGI();

  ...

It is recommended that you pass the absolute path of LibWeb's rc file to
LibWeb::HTML::Default and make it the *first* LibWeb object initialized.
This will ensure other LibWeb objects can ``see'' the rc file and be
initialized properly.  However, LibWeb::Admin, LibWeb::CGI, LibWeb::Database,
LibWeb::Themes::Default, and LibWeb::Session all can take $rc_file as the
argument to their B<new()> methods (constructor).  You will never need this
unless you do not want LibWeb::HTML::Default to manage HTML page display for
you.  You still do *not* need this even if you have ISAed LibWeb::HTML::Default.
The reason to ISA LibWeb::HTML::Default is to customize the normal and error
HTML page display and error messages built into LibWeb.  If you have ISAed
LibWeb::HTML::Default, you just have to replace the following two lines,

  use LibWeb::HTML::Default;
  my $html = new LibWeb::HTML::Default($rc_file);

with

  use MyHTML;
  my $html = new MyHTML($rc_file);

where MyHTML is your class which ISAs LibWeb::HTML::Default.  Please read
L<LibWeb::HTML::Default> for details.  A sample rc file has been included
in the ./eg directory.  If you could not find it, please go to
http:://libweb.sourceforge.net and download a standard LibWeb distribution.

=head2 SANITY -- REMOVING ILLEGAL CHARACTERS ENTERED BY USERS

LibWeb::Core provides B<sanitize()> method to escape illegal characters
entered by users in HTML forms.  LibWeb's definition of illegal characters
is as follows,

  `~!@#$%^&*,.:;?"'<>{}[]()\|/-_+=\a\n\r\t\f\e\b

B<sanitize()> also has the ability to escape HTML tags and detect dirty
e-mail addresses (format).  Please see below for details on B<sanitize()>.

=head2 METHODS

B<new()>

Params:

  $class [, $rc_file, $error_object]

Usage:

  No, you do not call LibWeb::Core::new() directly in client codes.

=over 2

=item *

$class is the class/package name of this package, be it a string or a
reference.

=item *

$rc_file is the absolute path to the rc file for LibWeb.

=item *

$error_object is a reference to a perl object for printing out error/help
message to users should error occur.

=back

B<debug_print()>

Usage:

  debug_print($debug_msg);

=over 2

=item *

If `DEBUG' == 1, print $debug_msg and return undef.  Do nothing otherwise.

=back

B<fatal()>

Params:

  -msg [, -input=>, -helpMsg=>, -alertMsg=>, -isAlert=>,
          -isDisplay=>, -ccokie=> ]

Usage:

  fatal(
         -msg => 'You have not entered your password.',
         -alertMSg => "$user did not enter password!",
         -helpMsg => \('Please hit back and edit.')
       );


  fatal(
         -alertMsg => 'Possible denial of service attack detected!',
         -isDisplay => 0
       );

Pre:

=over 2

=item *

-msg, -input, -alertMsg must be scalar and -helpMsg must be a SCALAR
reference.  -cookie can be a scalar or an ARRAY reference to scalars,

=item *

-input is the user input that triggers this fatal error,

=item *

-helpMsg is any instruction to guide the remote user, which can be HTML,

=back

Post:

=over 2

=item *

Send -cookie and print an error message to Web client if `isDisplay' is
defined and is equal to 1 (default),

=item *

send an alert e-mail to ADMIN_EMAIL if `isAlert' is defined and is equal
to 1 (default),

=item *

abort the current running program unless -isDisplay is defined and equal
to 0.

=item *

-alertMsg will not be displayed to client web browser but will appear in
the e-mail sent to ADMIN_EMAIL.

=back

B<sanitize()>: sanitizes Web client inputs

Params:

  -text=>'plain_text' || -html=>'html_text' || -email=>'email_here'
  [, -allow=>[charaters allowed] ]

Usage:

  $sanitized_input =
      sanitize( -text => $user_input, -allow => ['-', '_'] );

  @sanitized_emails =
      sanitize( -email => [$email1,$email2, $email3] );

  $sanitized_input =
      sanitize( -html => $user_input );

Pre:

=over 2

=item *

-text/-html/-email is a scalar or an ARRAY reference to scalars,

=item *

-allow is an ARRAY reference to special characters allowed.  It's effective
only when you use it with -text.

=back

Post:

=over 2

=item *

-text: sanitize text by escaping all illegal characters
(`~!@#$%^&*,.:;?"'<>{}[]()\|/-_+=\a\n\r\t\f\e\b),

=item *

-html: escape all html <> tags,

=item *

-email: sanitize email addresses.  Print an error message and abort the
current running program if email is dirty ( $email !~ m:(\w{1}[\w-.]*)\@([\w-.]+): )

=item *

array is returned if want array,

=item *

this can only process one type of sanity at a time (i.e. per method call).

=back

B<send_cookie()> -- this one is here due to inheritance (backward?)
issues not yet resolved with LibWeb::CGI.

Usage:

  my $cookie1 = 'auth1=0; path=/; expires=Thu, 01-Jan-1970 00:00:01 GMT';
  my $cookie2 = 'cook2=value; path=/';

  send_cookie( $cookie1 ); # or

  send_cookie( [$cookie1, $cookie2] );


Pre:

=over 2

=item *

Parameter must be either a scalar or an ARRAY reference to scalars,

=item *

no other HTTP headers should be sent before this in a single CGI session.

=back

Post:

=over 2

=item *

Send the cookie to client Web browser.

=back

B<send_mail()>

Params:

  -to [,-bcc] ,-from [,-replyTo] ,-subject, -msg

Pre:

=over 2

=item *

-msg must be a SCALAR reference and others must be scalars.

=back

Post:

=over 2

=item *

Send an e-mail to the recipients specified.

=back

=head1 AUTHORS

=over 2

=item Colin Kong (colin.kong@toronto.edu)

=back

=head1 CREDITS

=head1 BUGS

=head1 SEE ALSO

L<LibWeb::Admin>, L<LibWeb::Class>, L<LibWeb::Core>, L<LibWeb::CGI>, L<LibWeb::Crypt>
L<LibWeb::Database>, L<LibWeb::File>, L<LibWeb::HTML::Error>, L<LibWeb::HTML::Site>,
L<LibWeb::HTML::Default>, L<LibWeb::Session>, L<LibWeb::Themes::Default>,
L<LibWeb::Time>.

=cut
 
