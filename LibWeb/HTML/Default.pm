#=============================================================================
# LibWeb::HTML::Default -- a component of LibWeb--a Perl library/toolkit for
#                          building World Wide Web applications.

package LibWeb::HTML::Default;

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

# Use standard libraries.
use strict;
use vars qw($VERSION @ISA);

# Use custome libraries.
require LibWeb::HTML::Site;
require LibWeb::HTML::Error;

$VERSION = '0.01';
@ISA = qw( LibWeb::HTML::Site LibWeb::HTML::Error );

sub new {
    #
    # Params: $class, $rc_file
    #
    # - $class is the class/package name of this package, be it a string
    #   or a reference.
    # - $rc_file is the absolute path to the rc file for LibWeb.
    #
    # Usage: my $html = new LibWeb::HTML::Default( $rc_file );
    #
    # PLEASE do not edit anything in this ``new'' method unless you know
    # what you are doing.
    #
    my ($class, $Class, $self);
    $class = shift;
    $Class = ref($class) || $class;
    $self = $Class->SUPER::new( shift, shift || bless( {}, $Class ) );
    bless( $self, $Class );
}

sub DESTROY {
    # Destructor: performs cleanup when this object is not being
    # referenced any more.  For example, disconnect a database
    # connection, filehandle...etc.
}

#==================================================================================
# ISA this class (LibWeb::HTML::Default) and override the following method to
# customize normal display.  To customize error message display, ISA this class
# (LibWeb::HTML::Default) and override LibWeb::Error::display_error().
#
sub display {
   #
   # Implementing base class method: LibWeb::HTML::Site::display().
   # Params: -content=>, [ -sheader=>, -lpanel=>, -rpanel=>, -header=>, -footer=> ].
   #
   # -content, -sheader, -lpanel, -rpanel, -header and -footer must be an ARRAY
   # ref. to elements which are scalar/SCALAR ref/ARRAY ref.
   # If the the elements are ARRAY ref., then the elements in that ARRAY ref. must
   # be scalar and NOT ref.
   #
   # -content default is lines read from $self->content().
   # -sheader default is lines read from $self->sheader().
   # -lpanel default is lines read from $self->lpanel().
   # -rpanel default is lines read from $self->rpanel().
   # -header default is lines read from $self->header().
   # -footer default is lines read from $self->footer().
   #
   # Return a scalar ref. to a formatted page in HTML format for display
   # to Web client.
   #
   my ($self, $content, $sheader, $lpanel, $rpanel, $header, $footer,
	@content_display, @sheader_display, @lpanel_display, @rpanel_display,
	@header_display, @footer_display, $ref);
   $self = shift;
   ($content, $sheader, $lpanel, $rpanel, $header, $footer) =
     $self->rearrange(['CONTENT', 'SHEADER', 'LPANEL', 'RPANEL', 'HEADER',
			'FOOTER'], @_);

   $content ||= [ $self->content() ];
   $sheader ||= [ $self->sheader() ];
   $lpanel ||= [ $self->lpanel() ];
   $rpanel ||= [ $self->rpanel() ];
   $header ||= [ $self->header() ];
   $footer ||= [ $self->footer() ];

   foreach (@$content) {
	$ref = ref($_);
	if ( $ref eq 'SCALAR' ) { push(@content_display, $$_); }
	elsif ( $ref eq 'ARRAY' ) { push(@content_display, @$_); }
       else { push(@content_display, $_); }
   }
   foreach (@$sheader) {
	$ref = ref($_);
	if ( $ref eq 'SCALAR' ) { push(@sheader_display, $$_); }
	elsif ( $ref eq 'ARRAY' ) { push(@sheader_display, @$_); }
       else { push(@sheader_display, $_); }
   }
   foreach (@$header) {
	$ref = ref($_);
	if ( $ref eq 'SCALAR' ) { push(@header_display, $$_); }
	elsif ( $ref eq 'ARRAY' ) { push(@header_display, @$_); }
       else { push(@header_display, $_); }
   }
   foreach (@$lpanel) {
	$ref = ref($_);
	if ( $ref eq 'SCALAR' ) { push(@lpanel_display, $$_); }
	elsif ( $ref eq 'ARRAY' ) { push(@lpanel_display, @$_); }
       else { push(@lpanel_display, $_); }
   }
   foreach (@$rpanel) {
	$ref = ref($_);
	if ( $ref eq 'SCALAR' ) { push(@rpanel_display, $$_); }
	elsif ( $ref eq 'ARRAY' ) { push(@rpanel_display, @$_); }
       else { push(@rpanel_display, $_); }
   }

   foreach (@$footer) {
	$ref = ref($_);
	if ( $ref eq 'SCALAR' ) { push(@footer_display, $$_); }
	elsif ( $ref eq 'ARRAY' ) { push(@footer_display, @$_); }
       else { push(@footer_display, $_); }
   }

#<!-- Begin template -->
return \<<HTML;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html><head><meta name="description" content="$self->{SITE_DESCRIPTION}">
<meta name="keywords" content="$self->{SITE_KEYWORDS}">
<title>$self->{SITE_NAME}</title><link rel="stylesheet" href="$self->{CSS}"></head>
<body bgcolor="$self->{SITE_BG_COLOR}" text="$self->{SITE_TXT_COLOR}">
@header_display
@sheader_display
<table width="100%" cellspacing="10" cellpadding="0" border="0" bgcolor="$self->{SITE_BG_COLOR}">
<Tr>

<!-- Left panel -->
<td width="20%" valign="top">
@lpanel_display</td><!-- end left panel -->

<!-- Content -->
<td width="60%" valign="top">
@content_display</td><!-- end content -->

<!-- Right panel -->
<td width="20%" valign="top">
@rpanel_display</td><!-- end right panel -->

</Tr>
</table>

@footer_display</body></html>

HTML
#<!-- End template -->
}

#=================================================================================
# Begin implementation for site's default header, sub header, left panel,
# right panel, content, footer and possibly any other HTML constructs.

sub header {
    my $self = shift;
# Begin header
return \<<HTML;
<center>
<a href="$self->{URL_ROOT}">
<img src="$self->{SITE_LOGO_BG}" border="0" alt="$self->{SITE_NAME}">
</a>
</center>
HTML
# End header    
}

sub sheader {
# Begin sheader
return \<<HTML;

HTML
# End sheader
}

sub lpanel {
# Begin lpanel
return \<<HTML;

HTML
# End lpanel
}

sub content {
    my $self = shift;
    my $time = localtime();
# Begin content 
return \<<HTML;
<br><center>$time</center><br><br><br>
<p>Congratulations!  LibWeb has been successfully installed for
$self->{SITE_NAME}.  For more information on how LibWeb can help you
rapidly develop Web applications, please read the documentations
available at
<a href="http://libweb.sourceforge.net/">LibWeb's home page</a>.</p>
<p>If you are looking for more information on plug-and-play Web
applications for Web site with LibWeb installed, please go to the
<a href="http://leaps.sourceforge.net">LEAPs' home page</a>.</p>
<p>Thank you.</p>
HTML
# End content
}

sub rpanel {
# Begin rpanel
return \<<HTML;

HTML
# End rpanel
}

sub footer {
    my $self = shift;
return \<<HTML;
<center><table border=0 width="60%"><Tr><td align="center"><hr size=1>
<a href="$self->{COPYRIGHT}">Copyright</a>&nbsp;&copy;&nbsp;$self->{SITE_YEAR}&nbsp;$self->{SITE_NAME}.  All rights reserved.<br>
<a href="$self->{TOS}">Terms of Service.</a> &nbsp;
<a href="$self->{PRIVACY_POLICY}">Privacy Policy.</a>
</td></Tr></table></center>
HTML
}

1;
__DATA__

1;
__END__

=pod

=head1 NAME

LibWeb:: - HTML DISPLAY FOR LIBWEB APPLICATIONS

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

LibWeb::HTML::Site

=item *

LibWeb::HTML::Error

=back

=head1 SYNOPSIS

  use LibWeb::HTML::Default;
  my $html =
      new LibWeb::HTML::Default( '/absolute/path/to/libweb/rc_file' );

  $html->fatal(
                -msg => 'You have not typed in the stock symbol.',
                -alertMsg => 'Try to view stock quotes without a symbol.',
                -helpMsg => $html->hit_back_and_edit()
              )
      unless ($stock_symbol);

  my $display =
      $html->display(
                      -content => [ $news, $stock_quotes, $weather ],
                      -sheader=> [ $navigation_bar ],
                      -lpanel=> [ $banner_ad ],
                      -rpanel=> [ $back_issues, $downloads ],
                      -header=> undef,
                      -footer=> undef
                    );

  print "Content-Type: text/html\n\n";
  print $$display;

I pass the absolute path to my LibWeb's rc (config) file to
C<LibWeb::HTML::Default::new()> so that LibWeb can do things according
to my site's preferences.  A sample rc file is included in the eg
directory, if you could not find that, go to the following addresses
to down load a standard distribution of LibWeb
(http://libweb.sourceforge.net).  This synopsis also demonstrated how
I have handled error by calling the C<fatal()> method.  For the
C<display()> call, I passed `C<undef>' to C<-header> and C<-footer> to
demonstrate how to tell the display to use default header and footer.
Finally, I de-referenced C<$display> (by appending C<$> in front of
the variable) to print out the HTML page.  Please see the synopsis of
L<LibWeb::Themes::Default> to see how I have prepared C<$news,
$weather, $stock_quotes, $back_issues and $navigation_bar>.  If I
would like to customize the HTML display of LibWeb, I would have ISA
LibWeb::HTML::Default, say a class called C<MyHTML> and I just have to
replace the following two lines,

  use LibWeb::HTML::Default;
  my $html = new LibWeb::HTML::Default( $rc_file );

with

  use MyHTML;
  my $html = new MyHTML( $rc_file );

=head1 ABSTRACT

This class is a sub-class of both LibWeb::HTML::Site and
LibWeb::HTML::Error and therefore it handles both normal and error
display (HTML) for a LibWeb application.  To customize the behavior
of display(), display_error() and built-in error/help messages, you
can make a sub-class of LibWeb::HTML::Default (an example can be found
in the eg directory.  If you could not find it, download a standard
distribution from the following addresses).  In the sub-class you
made, you can also add your own error messages.  You may want to take
a look at L<LibWeb::HTML::Error> to see what standard error messages
are built into LibWeb.  To override the standard error messages, you
re-define them in the sub-class you made.

The current version of LibWeb::HTML::Default is available at

   http://libweb.sourceforge.net
   ftp://libweb.sourceforge/pub/libweb

Several LibWeb applications (LEAPs) have be written, released and
are available at

   http://leaps.sourceforge.net
   ftp://leaps.sourceforge.net/pub/leaps

=head1 TYPOGRAPHICAL CONVENTIONS AND TERMINOLOGY

All `error/help messages' mentioned can be found at
L<LibWeb::HTML::Error> and they can be customized by ISA (making a
sub-class of) LibWeb::HTML::Default.  Error/help messages are used
when you call LibWeb::Core::fatal, see L<LibWeb::Core> for details.
Method's parameters in square brackets means optional.

=head1 DESCRIPTION

B<new()>

Params:

=over 2

=item

I<class>, I<rc_file>

=back

Usage:

  my $html = new LibWeb::HTML::Default( $rc_file );

Pre:

=over 2

=item *

I<class> is the class/package name of this package, be it a string or a
reference.

=item *

I<rc_file> is the absolute path to the rc file for LibWeb.

=back

B<display()>

This implements the base class method: LibWeb::HTML::Site::display().

Params:

  -content=>, [ -sheader=>, -lpanel=>, -rpanel=>, -header=>, -footer=> ]

Pre:

=over 2

=item *

-content, -sheader, -lpanel, -rpanel, -header and -footer each must be
an ARRAY reference to elements which are scalars/SCALAR
references/ARRAY references,

=item *

if the elements are ARRAY references, then the elements in those
ARRAY references must be scalars and NOT references,

=item *

-content default is content(),

=item *

-sheader stands for ``sub header'' and default is sheader(),

=item *

-lpanel default is lpanel(),

=item *

-rpanel default is rpanel(),

=item *

-header default is header(),

=item *

-footer default is footer().

=back

Post:

=over 2

=item *

Return a scalar reference to a formatted HTML page suitable for
display to a Web client (browser).

=back

Each of the following methods return a SCALAR reference to a HTML
construct.  These are the defaults used by the C<display()> method.

B<header()>

B<sheader()>

B<lpanel()>

B<content()>

B<rpanel()>

B<footer()>

=head1 AUTHORS

=over 2

=item Colin Kong (colin.kong@toronto.edu)

=back

=head1 CREDITS

=head1 BUGS

=head1 SEE ALSO

L<LibWeb::Core>, L<LibWeb::HTML::Error>, L<LibWeb::HTML::Site>,
L<LibWeb::Themes::Default>.

=cut
