package Locale::Geocode::Territory;

use strict;

=head1 NAME

Locale::Geocode::Territory

=head1 DESCRIPTION

Locale::Geocode::Territory represents an individual
country or territory as listed in ISO-3166-1.  This
class provides methods for returning information 
about the territory and any administrative divisions
therein.

To be listed in ISO-3166-1, a country or territory
must be listed in the United Nations Terminology
Bulletin Country Names or Country and Region Codes
for Statistical Use of the UN Statistics Division.
In order for a country or territory to be listed in
the Country Names bulletin, one of the following
must be true of the territory:

  - is a United Nations member state a member 
  - is a member of any of the UN specialized agencies
  - a party to the Statute of the International Court of Justice

=head1 SYNOPSIS

 my $lct    = new Locale::Geocode::Territory 'US';

 # lookup a subdivision of US
 my $lcd    = $lct->lookup('TN');

 # retrieve ISO-3166-2 information for US-TN
 my $name   = $lcd->name;   # Tennessee
 my $code   = $lcd->code;   # TN

 # returns an array of Locale::Geocode::Division
 # objects representing all divisions of US
 my @divs   = $lct->divisions;

=head1 SOURCES

 Wikipedia - http://en.wikipedia.org/wiki/ISO_3166
 ISO 3166-1 - http://www.statoids.com/wab.html
 ISO 3166-2 - Locale::SubCountry

=cut

use overload
	'""' => sub { return shift->alpha2 },
	'==' => sub { return shift->num == shift->num },
	'!=' => sub { return shift->num != shift->num };

use Locale::Geocode::Division;

=head1 METHODS

=over 4

=item new

=cut

sub new
{
	my $proto	= shift;
	my $key		= lc(shift);
	my $lg		= shift || new Locale::Geocode;

	my $class	= ref($proto) || $proto;
	my $self	= {};
	$self->{lg}	= $lg;

	$self->{data} =	Locale::Geocode::data()->{alpha2}->{$key} ||
					Locale::Geocode::data()->{alpha3}->{$key} ||
					Locale::Geocode::data()->{num}->{$key} ||
					Locale::Geocode::data()->{name}->{$key};
	
	return undef if not defined $self->{data};
	return undef if not $lg->chkext($self->{data});
	
	return bless $self, $class;
}

=item lg

=cut

sub lg { return shift->{lg} }

=item lookup

=cut

sub lookup
{
	my $self	= shift;
	my $key		= shift;

	return new Locale::Geocode::Division $key, $self;
}

=item lookup_by_index

=cut

sub lookup_by_index
{
	my $self	= shift;
	my $idx		= shift;

	return new Locale::Geocode::Division $self->{data}->{division}->[$idx], $self;
}

=item name

=cut

sub name { return shift->{data}->{name} }

=item num

=cut

sub num { return shift->{data}->{num} }

=item alpha2

=cut

sub alpha2 { return shift->{data}->{alpha2} }

=item alpha3

=cut

sub alpha3 { return shift->{data}->{alpha3} }

=item fips

=cut

sub fips { return shift->{data}->{fips} }

=item has_notes

=cut

sub has_notes
{
	my $self = shift;

	my $data = $self->{data};
	
	return $data->{note} && scalar @{ $data->{note} } > 0 ? 1 : 0
}

=item num_notes

=cut

sub num_notes
{
	my $self = shift;
	
	my $data = $self->{data};
	
	return $data->{note} ? scalar @{ $data->{note} } : 0;
}

=item notes

=cut

sub notes
{
	my $self = shift;
	
	my $data = $self->{data};
	
	return $data->{note} ? @{ $data->{note} } : ();
}

=item note

=cut

sub note
{
	my $self	= shift;
	my $idx		= shift;
	
	my $data = $self->{data};
	
	return $data->{note} ? $data->{note}->[$idx] : undef;
}

=item divisions

=cut

sub divisions
{
	my $self = shift;

	return map { $self->lookup($_->{code}) || () } @{ $self->{data}->{division} };
}

=item num_divisions

=cut

sub num_divisions
{
	my $self = shift;

	return scalar grep { $self->lg->chkext($_) } @{ $self->{data}->{division} };
}

=back

=cut

=head1 AUTHOR

 Mike Eldridge <diz@cpan.org>

=head1 CREDITS

 Kim Ryan

=head1 SEE ALSO

 L<Locale::Geocode>
 L<Locale::SubCountry>
 L<Geography::Countries>
 L<Geography::Country>

=cut

1;
