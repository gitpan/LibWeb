#==============================================================================
# LibWeb::Themes::Default -- a component of LibWeb--a Perl library/toolkit for
#                            building World Wide Web applications.

package LibWeb::Themes::Default;

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

# Use custom libraries.
require LibWeb::Core;

$VERSION = '0.01';
@ISA = qw(LibWeb::Core);

#=================================================================================
# Constructor
sub new {
    #
    # Params: $class [, $rc_file]
    #
    # - $class is the class/package name of this package, be it a string
    #   or a reference.
    # - $rc_file is the absolute path to the rc file for LibWeb.
    #
    # Usage: my $object = new LibWeb::HTML::Themes([$rc_file]);
    #
    my ($class, $Class, $self);
    $class = shift;
    $Class = ref($class) || $class;

    # Inherit instance variables from the base class.
    $self = $Class->SUPER::new(shift);
    bless($self, $Class);
}

sub DESTROY {
    #Destructor: performs cleanup when this object is not being
    #referenced any more.  For example, disconnect a database
    #connection, filehandle...etc.
}

sub table {
    #
    # Params: -content=>, [ -bg_color=>, -align=>, -valign=>, -width=> ]
    #
    # -content must be an ARRAY ref. to elements which are
    #  scalar/SCALAR ref./ARRAY ref. to plain HTML.
    # -bg_color default is SITE_BG_COLOR.
    # -align is the content's horizontal alignment; default is `left'.
    # -valign is the content's vertical alignment; default is `top'.
    # -width default is 100%.
    #
    # Return a SCALAR ref. to a  formatted table in HTML format.
    #
    my ($self, $content, $bg_color, $align, $valign, $width,
	@content_display, $ref);
    $self = shift;
    ($content, $bg_color, $align, $valign, $width)
      = $self->rearrange( ['CONTENT', 'BG_COLOR', 'ALIGN', 'VALIGN', 'WIDTH'], @_ );

    $content ||= [' '];
    $bg_color ||= $self->{SITE_BG_COLOR};
    $align ||= 'left';
    $valign ||= 'top';
    $width ||= '100%';

    foreach (@$content) {
	$ref = ref($_);
	if ( $ref eq 'SCALAR' ) { push(@content_display, $$_); }
	elsif ( $ref eq 'ARRAY' ) { push(@content_display, @$_); }
        else { push(@content_display, $_); }
    }

#<!-- start HTML for table -->
return \<<HTML;
<table border=0 cellpadding=0 cellspacing=0 width="$width" bgcolor="$bg_color">
<Tr><td align="$align" valign="$valign">
@content_display
</td></Tr>
</table>

HTML
#<!-- end HTML for the table -->
}

sub titled_table {
    #
    # Params: -title=>, -content=>, [ -title_space=>, -title_align=>,
    #                               -title_bg_color=>, -title_txt_color=>,
    #                               -bg_color=>, align=>, valign=>,
    #                               -cellpadding=>, -width=> ]
    #
    # -content must be an ARRAY ref. to elements which are
    # scalar/SCALAR ref./ARRAY ref. to plain HTML.
    # -title_space is the space (&nbsp;) prepended before (if -title_align is `left')
    #  or append after (if -title_align is `right') the title.  It's always 0 if
    #  -title_align is `center'.  Default is 2, i.e. `&nbsp;&nbsp;'.
    # -title_align default is center.
    # -title_bg_color default is SITE_1ST_COLOR.
    # -title_txt_color default is SITE_BG_COLOR.
    # -bg_color default is if SITE_BG_COLOR.
    # -align is the content's horizontal alignment; default is `left'.
    # -valign is the content's vertical alignment; default is `top'.
    # -cellpadding is the distance between the content and the `border' of table,
    #  default is 1.
    # -width default is 100%.
    #
    # Return a SCALAR ref. to a  formatted table in HTML format.
    #
    my ($self,
	$title, $content, $title_space, $title_align, $title_bg_color,
	$title_txt_color, $bg_color, $align, $valign, $cellpadding, $width,
	$title_spacer, @content_display, $ref);
    $self = shift;
    ($title, $content, $title_space, $title_align, $title_bg_color,
     $title_txt_color, $bg_color, $align, $valign, $cellpadding, $width)
      = $self->rearrange( ['TITLE', 'CONTENT', 'TITLE_SPACE', 'TITLE_ALIGN',
			   'TITLE_BG_COLOR', 'TITLE_TXT_COLOR', 'BG_COLOR',
			   'ALIGN', 'VALIGN', 'CELLPADDING', 'WIDTH'],
			  @_ );

    $title ||= " ";
    $content ||= [' '];
    $title_align ||= 'center';
    unless  ( defined($title_space) ) {
	$title_space = ( uc($title_align) eq 'CENTER' ) ? 0 : 2;
    }
    $title_spacer = '&nbsp;' x $title_space;
    if ( uc($title_align) eq 'RIGHT' ) { $title = '<b>'.$title.'<b>'.$title_spacer; }
    else { $title = $title_spacer.'<b>'.$title.'<b>'; }
    $title_bg_color ||= $self->{SITE_1ST_COLOR};
    $title_txt_color ||= $self->{SITE_BG_COLOR};
    $bg_color ||= $self->{SITE_BG_COLOR};
    $align ||= 'left';
    $valign ||= 'top';
    $cellpadding ||= 1;
    $width ||= '100%';

    foreach (@$content) {
	$ref = ref($_);
	if ( $ref eq 'SCALAR' ) { push(@content_display, $$_); }
	elsif ( $ref eq 'ARRAY' ) { push(@content_display, @$_); }
        else { push(@content_display, $_); }
    }

#<!-- start HTML for titled_table -->
return \<<HTML;
<table border=0 cellpadding=0 cellspacing=0 width="$width" bgcolor="$bg_color">

<Tr><td>
<table border=0 cellpadding=0 cellspacing=0 width="100%" bgcolor="$title_bg_color">
<Tr><td align="$title_align" bgcolor="$title_bg_color">
<font color="$title_txt_color">$title</font>
</td></Tr></table>
</td><Tr>

<Tr><td>
<table bgcolor="$bg_color" cellpadding="$cellpadding" cellspacing=0 width="100%" border=0>
<Tr><td align="$align" valign="$valign">
@content_display
</td></Tr></table>
</td></Tr>

</table>

HTML
#<!-- end HTML for the titled_table -->
}

sub titled_table_enlighted {
    #
    # Params: -title=>, -content=>, [ -title_space=>, -title_align=>,
    #                               -title_bg_color=>,
    #                               -title_txt_color=>, -title_border_color=>,
    #                               -bg_color=>, -align=>, -valign=>,
    #                               -cellpadding=>, -width=> ]
    #
    # -content must be an ARRAY ref. to elements which are
    # scalar/SCALAR ref./ARRAY ref. to plain HTML.
    # -title_space is the space (&nbsp;) prepended before (if -title_align is `left')
    #  or append after (if -title_align is `right') the title; default is 2,
    #  i.e. `&nbsp;&nbsp;'.  It's always 0 if -title_align if `center'.
    # -title_align default is center.
    # -title_bg_color default is SITE_LIQUID_COLOR3.
    # -title_txt_color default is SITE_LIQUID_COLOR5.
    # -title_border_color default is SITE_LIQUID_COLOR5.
    # -bg_color default is if SITE_BG_COLOR.
    # -align is the content's horizontal alignment; default is `left'.
    # -valign is the content's vertical alignment; default is `top'.
    # -cellpadding is the distance between the content and the `border' of table,
    #  default is 1.
    # -width default is 100%.
    #
    # Return a SCALAR ref. to a  formatted table in HTML format.
    #
    my ($self,
	$title, $content, $title_space, $title_align, $title_bg_color,
	$title_txt_color, $title_border_color, $bg_color, $align, $valign,
	$cellpadding, $width,
	$title_spacer, @content_display, $ref);
    $self = shift;
    ($title, $content, $title_space, $title_align, $title_bg_color,
     $title_txt_color, $title_border_color, $bg_color, $align, $valign,
     $cellpadding, $width)
      = $self->rearrange( ['TITLE', 'CONTENT', 'TITLE_SPACE', 'TITLE_ALIGN',
			   'TITLE_BG_COLOR', 'TITLE_TXT_COLOR', 'TITLE_BORDER_COLOR',
			   'BG_COLOR', 'ALIGN', 'VALIGN', 'CELLPADDING', 'WIDTH'],
			  @_ );

    $title ||= " ";
    $content ||= [' '];
    $title_align ||= 'center';
    unless  ( defined($title_space) ) {
	$title_space = ( uc($title_align) eq 'CENTER' ) ? 0 : 2;
    }
    $title_spacer = '&nbsp;' x $title_space;
    if ( uc($title_align) eq 'RIGHT' ) { $title = "<b>${title}</b>${title_spacer}"; }
    else { $title = "${title_spacer}<b>${title}</b>"; }
    $title_bg_color ||= $self->{SITE_LIQUID_COLOR3};
    $title_txt_color ||= $self->{SITE_LIQUID_COLOR5};
    $title_border_color ||= $self->{SITE_LIQUID_COLOR5};
    $bg_color ||= $self->{SITE_BG_COLOR};
    $align ||= 'left';
    $valign ||= 'top';
    $cellpadding ||= 1;
    $width ||= '100%';

    foreach (@$content) {
	$ref = ref($_);
	if ( $ref eq 'SCALAR' ) { push(@content_display, $$_); }
	elsif ( $ref eq 'ARRAY' ) { push(@content_display, @$_); }
        else { push(@content_display, $_); }
    }

#<!-- start HTML for titled_table_enlighted -->
return \<<HTML;
<table border=0 cellpadding=0 cellspacing=0 width="$width" bgcolor="$bg_color">

<Tr><td>
<table border=0 cellpadding=1 cellspacing=0 width="100%" bgcolor="$title_border_color">
<Tr><td>
<table border=0 cellpadding=0 cellspacing=0 width="100%" bgcolor="$title_bg_color">
<Tr><td bgcolor="$title_bg_color" align="$title_align">
<font color="$title_txt_color">$title</font>
</td></Tr>
</table>
</td></Tr>
</table>
</td><Tr>

<Tr><td>
<table bgcolor="$bg_color" cellpadding="$cellpadding" cellspacing=0 width="100%" border=0>
<Tr><td align="$align" valign="$valign">
@content_display
</td></Tr>
</table>
</td></Tr>

</table>

HTML
#<!-- end HTML for the titled_table_enlighted -->
}

sub bordered_table {
    #
    # Params: -content=>, [ -border_color=>, -bg_color=>, align=>, -valign=>,
    #                     -cellpadding=>, -width=> ]
    #
    # -content must be an ARRAY ref. to elements which are
    #  scalar/SCALAR ref./ARRAY ref. to plain HTML.
    # -border_color default is SITE_1ST_COLOR.
    # -bg_color default is if SITE_BG_COLOR.
    # -align is the content's horizontal alignment; default is `left'.
    # -valign is the content's vertical alignment; default is `top'.
    # -cellpadding is the distance between the content and the `border' of table,
    #  default is 1.
    # -width default is 100%.
    #
    # Return a SCALAR ref. to a formatted table in HTML format.
    #
    my ($self,
	$content, $border_color, $bg_color, $align, $valign, $cellpadding, $width,
	@content_display, $ref);
    $self = shift;
    ($content, $border_color, $bg_color, $align, $valign, $cellpadding, $width)
      = $self->rearrange( ['CONTENT', 'BORDER_COLOR', 'BG_COLOR', 'ALIGN', 'VALIGN',
			   'CELLPADDING', 'WIDTH'], @_ );

    $content ||= [' '];
    $border_color ||= $self->{SITE_1ST_COLOR};
    $bg_color ||= $self->{SITE_BG_COLOR};
    $align ||= 'left';
    $valign ||= 'top';
    $cellpadding ||= 1;
    $width ||= '100%';

    foreach (@$content) {
	$ref = ref($_);
	if ( $ref eq 'SCALAR' ) { push(@content_display, $$_); }
	elsif ( $ref eq 'ARRAY' ) { push(@content_display, @$_); }
        else { push(@content_display, $_); }
    }

#<!-- start HTML for bordered_table -->
return \<<HTML;
<table border=0 cellpadding=1 cellspacing=0 bgcolor="$border_color" width="$width">

<Tr><td>
<table bgcolor="$bg_color" cellpadding="$cellpadding" cellspacing=0 width="100%" border=0>
<Tr><td align="$align" valign="$valign" bgcolor="$bg_color">
@content_display
</td></Tr></table>
</td></Tr>

</table>

HTML
#<!-- end HTML for the bordered_table -->
}

sub titled_bordered_table {
    #
    # Params: -title=>, -content=>, [ -title_space=>, -title_align=>,
    #                               -border_color=>,
    #                               -title_txt_color=>,
    #                               -bg_color=>, -align=>, -valign=>,
    #                               -cellpadding=>, -width=> ]
    #
    # -content must be an ARRAY ref. to elements which are
    #  scalar/SCALAR ref./ARRAY ref. to plain HTML.
    # -title_space is the space (&nbsp;) prepended before (if -title_align is `left')
    #  or append after (if -title_align is `right') the title; default is 2, i.e.
    #  `&nbsp;&nbsp;'.  If -title_align is `center', -title_space is always 0.
    # -title_align default is center.
    # -border_color default is SITE_1ST_COLOR.
    # -title_txt_color default is SITE_BG_COLOR.
    # -bg_color default is if SITE_BG_COLOR.
    # -align is the content's horizontal alignment; default is `left'.
    # -valign is the content's vertical alignment; default is `top'.
    # -cellpadding is the distance between the content and the `border' of table,
    #  default is 1.
    # -width default is 100%.
    #
    # Return a SCALAR ref. to a formatted table in HTML format.
    #
    my ($self,
	$title, $content, $title_space, $title_align, $border_color,
	$title_txt_color, $bg_color, $align, $valign, $cellpadding, $width,
	$title_spacer, @content_display, $ref);
    $self = shift;
    ($title, $content, $title_space, $title_align, $border_color,
     $title_txt_color, $bg_color, $align, $valign, $cellpadding, $width)
      = $self->rearrange( ['TITLE', 'CONTENT', 'TITLE_SPACE', 'TITLE_ALIGN',
			   'BORDER_COLOR', 'TITLE_TXT_COLOR',
			   'BG_COLOR', 'ALIGN', 'VALIGN', 'CELLPADDING', 'WIDTH'],
			  @_ );

    $title ||= " ";
    $content ||= [' '];
    $title_align ||= 'center';
    unless  ( defined($title_space) ) {
	$title_space = ( uc($title_align) eq 'CENTER' ) ? 0 : 2;
    }
    $title_spacer = '&nbsp;' x $title_space;
    if ( uc($title_align) eq 'RIGHT' ) { $title = '<b>'.$title.'<b>'.$title_spacer; }
    else { $title = $title_spacer.'<b>'.$title.'<b>'; }
    $border_color ||= $self->{SITE_1ST_COLOR};
    $title_txt_color ||= $self->{SITE_BG_COLOR};
    $bg_color ||= $self->{SITE_BG_COLOR};
    $align ||= 'left';
    $valign ||= 'top';
    $cellpadding ||= 1;
    $width ||= '100%';

    foreach (@$content) {
	$ref = ref($_);
	if ( $ref eq 'SCALAR' ) { push(@content_display, $$_); }
	elsif ( $ref eq 'ARRAY' ) { push(@content_display, @$_); }
        else { push(@content_display, $_); }
    }

#<!-- start HTML for titled_bordered_table -->
return \<<HTML;
<table border=0 cellpadding=1 cellspacing=0 bgcolor="$border_color" width="$width">

<Tr><td>
<table width="100%" border=0 cellspacing=0 cellpadding=0 bgcolor="$border_color">
<Tr><td align="$title_align" bgcolor="$border_color">
<font color="$title_txt_color">$title</font>
</td></Tr></table>
</td></Tr>

<Tr><td>
<table bgcolor="$bg_color" cellpadding="$cellpadding" cellspacing=0 width="100%" border=0>
<Tr><td align="$align" valign="$valign" bgcolor="$bg_color">
@content_display
</td></Tr></table>
</td></Tr>

</table>

HTML
#<!-- end HTML for the titled_bordered_table -->
}

1;
__DATA__

1;
__END__

=pod

=head1 NAME

LibWeb::Themes::Default - DEFAULT HTML THEME FOR LIBWEB APPLICATIONS

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

LibWeb::Core

=back

=head1 SYNOPSIS

  use LibWeb::Themes::Default;
  my $theme = new LibWeb::Themes::Default();

  my $navigation_bar =
      $theme->table( -content => [ $nav_bar ] );

  my $stock_quotes =
      $theme->bordered_table(
                              -content => [ $fetched_stock_quotes ]
                            );

  my $weather =
      $theme->titled_bordered_table(
                                     -title => "Today's weather",
                                     -content => [ $fetched_weather ]
                                   );

  my $back_issues =
      $theme->titled_table(
                            -title => "Looking for back issues?",
                            -content => [ $back_issues_archive_list ]
                          );

  my $news =
      $theme->titled_table_enlighted(
                                      -title => "Today's news",
                                      -content => [ $fetched_news ]
                                    );

Please see the synopsis of L<LibWeb::HTML::Default> to see how those
HTML constructs can be displayed.

=head1 ABSTRACT

This class provides several common table templates for HTML display.
This allows Web application designers focus their efforts on the logic
of programs; while Web page designers spend their efforts on
customizing this default by ISAing this class, say
LibWeb::Themes::Futuristic.

The current version of LibWeb::Themes::Default is available at

   http://libweb.sourceforge.net
   ftp://libweb.sourceforge/pub/libweb

Several LibWeb applications (LEAPs) have be written, released and
are available at

   http://leaps.sourceforge.net
   ftp://leaps.sourceforge.net/pub/leaps

=head1 TYPOGRAPHICAL CONVENTIONS AND TERMINOLOGY

Variables in all-caps (e.g. SITE_BG_COLOR) are those variables set
through LibWeb's rc file.  Please read L<LibWeb::Core> for more
information.  Method's parameters in square brackets means optional.

=head1 DESCRIPTION

B<table()>

Params:

  -content=>, [ -bg_color=>, -align=>, -valign=>, -width=> ]

=over 2

=item *

-content must be an ARRAY reference to elements which are
scalars/SCALAR references/ARRAY references to plain HTML,

=item *

-bg_color default is SITE_BG_COLOR,

=item *

-align is the content's horizontal alignment; default is `left',

=item *

-valign is the content's vertical alignment; default is `top',

=item *

-width default is 100%.

=back

Post:

=over 2

=item *

Return a SCALAR reference to a formatted table in HTML.

=back

B<titled_table()>

Params:

  -title=>, -content=>, [ -title_space=>, -title_align=>,
  -title_bg_color=>, -title_txt_color=>, -bg_color=>, align=>,
  valign=>, -cellpadding=>, -width=> ]

Pre:

=over 2

=item *

-title is a scalar,

=item *

-content must be an ARRAY reference to elements which are
scalars/SCALAR references/ARRAY references to plain HTML,

=item *

-title_space is the space (&nbsp;) prepended before (if -title_align
is `left') or append after (if -title_align is `right') the title.
It's always 0 if -title_align is `center'.  Default is 2,
i.e. `&nbsp;&nbsp;',

=item *

-title_align default is `center',

=item *

-title_bg_color default is SITE_1ST_COLOR,

=item *

-title_txt_color default is SITE_BG_COLOR,

=item *

-bg_color default is SITE_BG_COLOR,

=item *

-align is the content's horizontal alignment; default is `left',

=item *

-valign is the content's vertical alignment; default is `top',

=item *

-cellpadding is the distance between the content and the `border' of
table, default is 1.

=item *

-width default is 100%.

=back

Post:

=over 2

=item *

Return a SCALAR reference to a formatted table in HTML.

=back

B<titled_table_enlighted()>

Params:

  -title=>, -content=>, [ -title_space=>, -title_align=>,
  -title_bg_color=>, -title_txt_color=>, -title_border_color=>,
  -bg_color=>, -align=>, -valign=>,
  -cellpadding=>, -width=> ]

Pre:

=over 2

=item *

-title is a scalar,

=item *

-content must be an ARRAY reference to elements which are
scalars/SCALAR references/ARRAY references to plain HTML,

=item *

-title_space is the space (&nbsp;) prepended before (if -title_align
is `left') or append after (if -title_align is `right') the title;
default is 2, i.e. `&nbsp;&nbsp;'.  It's always 0 if -title_align if
`center',

=item *

-title_align default is `center',

=item *

-title_bg_color default is SITE_LIQUID_COLOR3,

=item *

-title_txt_color default is SITE_LIQUID_COLOR5,

=item *

-title_border_color default is SITE_LIQUID_COLOR5,

=item *

-bg_color default is SITE_BG_COLOR,

=item *

-align is the content's horizontal alignment; default is `left',

=item *

-valign is the content's vertical alignment; default is `top',

=item *

-cellpadding is the distance between the content and the `border' of
table, default is 1.

=item *

-width default is 100%.

=back

Post:

=over 2

=item *

Return a SCALAR reference to a formatted table in HTML.

=back

B<bordered_table()>

Params:

  -content=>, [ -border_color=>, -bg_color=>, align=>,
  -valign=>, -cellpadding=>, -width=> ]

Pre:

=over 2

=item *

-content must be an ARRAY reference to elements which are
scalars/SCALAR references/ARRAY references to plain HTML.

=item *

-border_color default is SITE_1ST_COLOR,

=item *

-bg_color default is SITE_BG_COLOR,

=item *

-align is the content's horizontal alignment; default is `left',

=item *

-valign is the content's vertical alignment; default is `top',

=item *

-cellpadding is the distance between the content and the `border' of
table, default is 1,

=item *

-width default is 100%.

=back

Post:

=over 2

=item *

Return a SCALAR reference to a formatted table in HTML.

=back

B<titled_bordered_table()>

Params:

  -title=>, -content=>, [ -title_space=>, -title_align=>,
  -border_color=>, -title_txt_color=>, -bg_color=>, -align=>,
  -valign=>, -cellpadding=>, -width=> ]

Pre:

=over 2

=item *

-title is a scalar,

=item *

-content must be an ARRAY reference to elements which are
scalars/SCALAR references/ARRAY references to plain HTML.

=item *

-title_space is the space (&nbsp;) prepended before (if -title_align
is `left') or append after (if -title_align is `right') the title;
default is 2, i.e.  `&nbsp;&nbsp;'.  If -title_align is `center',
-title_space is always 0,

=item *

-title_align default is `center',

=item *

-border_color default is SITE_1ST_COLOR,

=item *

-title_txt_color default is SITE_BG_COLOR,

=item *

-bg_color default is SITE_BG_COLOR,

=item *

-align is the content's horizontal alignment; default is `left',

=item *

-valign is the content's vertical alignment; default is `top',

=item *

-cellpadding is the distance between the content and the `border' of
table, default is 1,

=item *

-width default is 100%.

=back

Post:

=over 2

=item *

Return a SCALAR reference to a formatted table in HTML.

=back

=head1 AUTHORS

=over 2

=item Colin Kong (colin.kong@toronto.edu)

=back

=head1 CREDITS


=head1 BUGS

This release does not provide a lot of table templates and only a
default theme is available.  Hopefully more people can write more
themes for LibWeb and make them available at
http://libweb.sourceforge.net.

=head1 SEE ALSO

L<LibWeb::HTML::Error>, L<LibWeb::HTML::Site>,
L<LibWeb::HTML::Default>.

=cut
