#!/usr/bin/perl -w

#======================================================================
# testing.cgi -- a perl script to test LibWeb installation.
#
# Copyright (C) 2000  Colin Kong
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
# USA.
#
#======================================================================

#=============================================================
# Begin edit.

# Uncomment the following line and edit the path if you have
# installed LibWeb into non-standard Perl's library locations.
#use lib '/path/to/LibWeb';

# Where is your LibWeb rc (config) file located?
# (Absolute path; NOT url).
my $Rc_file = '/home/my_site/lw_rc_file';

# For debugging cgi perl script via a web browser.
# Should be commented out in production release of this script.
use CGI::Carp qw(fatalsToBrowser);

# End edit.
#=============================================================

# Make perl taint mode happy.
$ENV{PATH} = "";

# Use standard libraries.
use strict;

# Use custome libraries.
use LibWeb::HTML::Default;
use LibWeb::Themes::Default;
use LibWeb::CGI;
use LibWeb::Database;
use LibWeb::Admin;
use LibWeb::File;
use LibWeb::Time;

# Global variables.
my $html = LibWeb::HTML::Default->new( $Rc_file );
my $themes = LibWeb::Themes::Default->new();
my $q = LibWeb::CGI->new();
my $db; eval { $db = LibWeb::Database->new(); }; my $db_fail_msg = $@;
my $a; eval { $a = LibWeb::Admin->new(); }; my $admin_fail_msg = $@;
my $fh = LibWeb::File->new();
my $t = LibWeb::Time->new();
my $this = $ENV{SCRIPT_NAME};

# CGI paramters.
my $p_a = '.a';
my $p_err_msg = '.err_msg';
my $a_mail_admin = 'mail_admin';
my $a_test_err_msg = 'test_err_msg';

# Fetch CGI parameters.
my $action = $q->parameter($p_a);
my $err_msg = $q->parameter($p_err_msg);

# MAIN.
if ( $action eq $a_mail_admin) { send_mail_to_admin(); }

elsif ( $action eq $a_test_err_msg) {
    $html->fatal(
		 -helpMsg => $html->$err_msg(),
		 -isAlert => 0
		);
}

else { print_testing_page(); }

exit(0);

#===========================================================================
# Subroutines.
sub print_testing_page {
    print $q->header();
    print ${ _testing_page_html() };
}

sub send_mail_to_admin {
    $html->fatal(
		 -alertMsg => "This is a LibWeb's test message!",
		 -isDisplay => 0
		 );
    print_testing_page();
}

#===========================================================================
# HTML pages.
sub _testing_page_html {
    return $html->display(
			  -header => _header(), -sheader => _sheader(),
			  -lpanel => _lpanel(), -content => _content(),
			  -rpanel => _rpanel(), -footer => _footer()
			 );
}

#===========================================================================
# Page constructs.
sub _sheader {
    return
      [
       $themes->table(
		      -content => [ '&nbsp;&nbsp;This is sub-header, you could put a navigation bar here :)' ],
		      -bg_color => $html->{SITE_LIQUID_COLOR2}
		     )
      ];
}

sub _lpanel {
    return
      [
       $themes->titled_bordered_table(
				      -title => "LibWeb's status",
				      -title_align => 'left',
				      -content =>
				      [ _libweb_status_phtml(), _colors_test_phtml() ]
				     )
      ];
}

sub _content {
    my $congratulations =
      $themes->titled_table_enlighted(
				      -title => 'Congratulations!',
				      -content => [ _congratulation_msg_phtml() ]
				     );
    my $err_msg_test =
      $themes->titled_table_enlighted(
				      -title => 'Error messages test',
				      -content => [ _test_err_msg_phtml() ]
				     );
    my $time_test =
      $themes->titled_table_enlighted(
				      -title => 'LibWeb::Time tests',
				      -content => [ _test_LibWeb_Time_phtml() ]
				     );
    return [ $congratulations, '<br>', $err_msg_test, '<br>', $time_test ];
}

sub _rpanel {
    my $utilities =
      $themes->titled_table(
			    -title => "LibWeb's utilities",
			    -title_align => 'left',
			    -content => [ _libweb_utilities_phtml() ],
			    -cellpadding => 3
			   );
    return [ $utilities ];
}

sub _header {
    return undef; # Use LibWeb::HTML::Default header.
}

sub _footer {
    return undef; # Use LibWeb::HTML::Default footer.
}

#=======================================================================
# PHTML.
sub _congratulation_msg_phtml {
    my $time = $t->get_datetime();
return \<<HTML;
<br>$time<br>
<p>Congratulations!  LibWeb has been successfully installed for
$html->{SITE_NAME}.  For more information on how LibWeb can help you
rapidly develop Web applications, please read the documentations
available at
<a href="http://libweb.sourceforge.net">LibWeb's home page</a>.</p>
<p>If you are looking for more information on plug-and-play Web
applications for Web site with LibWeb installed, please go to the
<a href="http://leaps.sourceforge.net">LEAPs' home page</a>.</p>
<p>Thank you.</p>
HTML
}

sub _colors_test_phtml {
    return      \ (
       '<P>SITE_1ST_COLOR: ' . ${ $themes->table( -bg_color => $html->{SITE_1ST_COLOR}, -content => ['tested'] ) } .
       '<P>SITE_2ND_COLOR: ' . ${ $themes->table( -bg_color => $html->{SITE_2ND_COLOR}, -content => ['tested'] ) } .
       '<P>SITE_3RD_COLOR: ' . ${ $themes->table( -bg_color => $html->{SITE_3RD_COLOR}, -content => ['tested'] ) } .
       '<P>SITE_4TH_COLOR: ' . ${ $themes->table( -bg_color => $html->{SITE_4TH_COLOR}, -content => ['tested'] ) } .
       '<P>SITE_LIQUID_COLOR1: ' . ${ $themes->table( -bg_color => $html->{SITE_LIQUID_COLOR1}, -content => ['tested'] ) } .
       '<P>SITE_LIQUID_COLOR2: ' . ${ $themes->table( -bg_color => $html->{SITE_LIQUID_COLOR2}, -content => ['tested'] ) } .
       '<P>SITE_LIQUID_COLOR3: ' . ${ $themes->table( -bg_color => $html->{SITE_LIQUID_COLOR3}, -content => ['tested'] ) } .
       '<P>SITE_LIQUID_COLOR4: ' . ${ $themes->table( -bg_color => $html->{SITE_LIQUID_COLOR4}, -content => ['tested'] ) } .
       '<P>SITE_LIQUID_COLOR5: ' . ${ $themes->table( -bg_color => $html->{SITE_LIQUID_COLOR5}, -content => ['tested'] ) } .
       '<P>SITE_TXT_COLOR: ' . ${ $themes->table( -bg_color => $html->{SITE_TXT_COLOR}, -content => ['tested'] ) } .
       '<P>SITE_BG_COLOR: ' . ${ $themes->table( -bg_color => $html->{SITE_BG_COLOR}, -content => ['tested'] ) }
      );
}

sub _libweb_status_phtml {
    my ( $database_test, $admin_test );
    if (defined $db) {
	$database_test =
	  '<p>- LibWeb has successfully connected to and disconnected from your database!</p>';
    } else {
	$database_test =
	  "<p>- LibWeb could not connect to your database, reason: " .
	    defined($db_fail_msg) ? $db_fail_msg : 'unknown reason.' . '</p>';
    }
    if (defined $a) {
	$admin_test =
	  '<p>- User/session management has been successfully initiated.</p>';
    } else {
	$admin_test =
	  '<p>- User/session management could not be initiated, reason: ' .
	    defined($admin_fail_msg) ? $admin_fail_msg : 'unknown reason.' . '</p>';
    }
return \<<HTML;
$database_test
$admin_test
<p>- You are using the default LibWeb::HTML display and default LibWeb::Themes.</p>
<p>- The following colors have been registered with LibWeb:</p>
HTML
}

sub _libweb_utilities_phtml {
return \<<HTML;
<a href="${this}?$p_a=$a_mail_admin">Send</a> a test e-mail to the
site administrator.  The following admin e-mail has been registered
with LibWeb: <font color="red">$html->{ADMIN_EMAIL}</font>.
HTML
}

sub _test_err_msg_phtml {
return \<<HTML;
<p>LibWeb\'s built-in error messages:</p>
<ul>
<li><a href="$this?$p_a=$a_test_err_msg&$p_err_msg=cookie_error">cookie_error</a></li>
<li><a href="$this?$p_a=$a_test_err_msg&$p_err_msg=database_error">database_error</a></li>
<li><a href="$this?$p_a=$a_test_err_msg&$p_err_msg=exceeded_max_login_attempt">exceeded_max_login_attempt</a></li>
<li><a href="$this?$p_a=$a_test_err_msg&$p_err_msg=hit_back_and_edit">hit_back_and_edit</a></li>
<li><a href="$this?$p_a=$a_test_err_msg&$p_err_msg=login_expired">login_expired</a></li>
<li><a href="$this?$p_a=$a_test_err_msg&$p_err_msg=login_failed">login_failed</a></li>
<li><a href="$this?$p_a=$a_test_err_msg&$p_err_msg=logout_failed">logout_failed</a></li>
<li><a href="$this?$p_a=$a_test_err_msg&$p_err_msg=mysterious_error">mysterious_error</a></li>
<li><a href="$this?$p_a=$a_test_err_msg&$p_err_msg=post_too_large">post_too_large</a></li>
<li><a href="$this?$p_a=$a_test_err_msg&$p_err_msg=registration_failed">registration_failed</a></li>
<li><a href="$this?$p_a=$a_test_err_msg&$p_err_msg=special_characters_not_allowed">special_characters_not_allowed</a></li>
</ul>
<p>Please read the man page for LibWeb::HTML::Error and LibWeb::HTML::Default for
details on how to customize these and add your own error messages.</p>
HTML
}

sub _test_LibWeb_Time_phtml {
    my $date = $t->get_date();
    my $datetime = $t->get_datetime();
    my $time = $t->get_time();
    my $timestamp = $t->get_timestamp();
    my $year = $t->get_year();
return \<<HTML;
<p>LibWeb::Time class testing:</p>
<ul>
<li>Date: $date</li>
<li>Date, time & year: $datetime</li>
<li>Time: $time</li>
<li>Timestamp: $timestamp</li>
<li>Year: $year</li>
</ul>
HTML
}

1;
__END__
