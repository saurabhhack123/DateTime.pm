##
## Czech tables
##
## Contributed by Honza Pazdziora 

package DateTime::Language::Czech;

use strict;

use vars qw(@ISA @DayNames @DayAbbreviations @MonthNames @MonthAbbreviations @MonthNames2 @AMPM %MonthNames %DayNames $VERSION);
@ISA = qw(DateTime::LanguageDateTime::Format::Generic);


@MonthNames = qw(leden �nor b�ezen duben kv�ten �erven �ervenec srpen z���
	      ��jen listopad prosinec);
@MonthAbbreviations = qw(led �nor b�e dub kv� �vn �ec srp z��� ��j lis pro);
@MonthNames2 = @MonthNames;
for (@MonthNames2)
      { s!en$!na! or s!ec$!ce! or s!ad$!adu! or s!or$!ora!; }

@DayNames = qw(ned�le pond�l� �ter� st�eda �tvrtek p�tek sobota);
@DayAbbreviations = qw(Ne Po �t St �t P� So);

@AMPM = qw(dop. odp.);

@MonthNames{@MonthNames}  = (1 .. scalar(@MonthNames));
@MonthNames{@MonthAbbreviations} = (1 .. scalar(@MonthAbbreviations));
@DayNames{@DayNames}  = (0 .. scalar(@DayNames));
@DayNames{@DayAbbreviations} = (0 .. scalar(@DayAbbreviations));

# contact Honza to make sense of this before deleting! - dave

sub time2str {
      my $ref = shift;
      my @a = @_;
      $a[0] =~ s/(%[do]\.?\s?)%B/$1%Q/;
      $ref->SUPER::time2str(@a);
      }

sub strftime {
      my $ref = shift;
      my @a = @_;
      $a[0] =~ s/(%[do]\.?\s?)%B/$1%Q/;
      $ref->SUPER::time2str(@a);
      }

1;
