package Locale::Geocode::Territory;

use warnings;
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
	my $proto = shift;
	my $class = ref $proto || $proto;

	# maintain 1.x compatibility by explicitly using
	# Locale::Geocode->lookup

	return Locale::Geocode->new->lookup($_[0])
		if ref $_[0] ne 'Locale::Geocode';

	my $self = { lg => shift, node => shift };

	return undef if not defined $self->{node};

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

	my $rv = undef;

	for (ref $key) {
		/^$/ && do
		{
			my ($iso3166_1, $iso3166_2) = split '-', $key;

			$rv = new Locale::Geocode::Territory $iso3166_1, $self;
			$rv = $rv->lookup($iso3166_2) if $rv && $iso3166_2;

			last;
		};

		/HASH/ && do
		{
			# don't lookup a damn thing if the user didn't
			# ask us to...

			last if not scalar keys %$key;

			# use lookup tables in a lazy fashion, reusing
			# the keys from the hashref the user handed us.

			my @a = map {
				new Set::Scalar $self->{data}->{$_}->{lc $key->{$_}}->{alpha2}
			} keys %$key;

			# find the intersection of the aggregate result
			# of the lookups.  i'd rather this be utilized
			# as a class method like the cartesian product
			# method, but it doesn't appear to be possible.
			# there's an overloaded multiplication operator
			# for intersections, but it looks strange and
			# gives the impression it's a cartesian product.
			# so i'll just use the instance method...

			my $set	= scalar(@a) > 1
				? $a[0]->intersection($a[1 .. $#a])
				: $a[0];

			# recursive lookup; use the first member of the
			# Set if there are multiples.  handling multiple
			# items may be a future feature, but for now we
			# are just going to return the first one.

			$rv = $self->lookup($set->members);

			last;
		};

		die "unable to handle $_ in lookup";
	}

	return $rv;
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

sub name
{
	my $self = shift;

	return $self->name('' => 'short') if scalar @_ == 0;

	my $lang = shift;
	my $type = shift;

	my $query	= { lang => $lang, type => $type };
	my $path	= Locale::Geocode->_serialize_query('name', $query);

	my $set = $self->{node}->find($path);

	return undef if not $set->size;

	my @a = map { $_->getChildNode(1)->toString } $set->get_nodelist;

	return scalar @a > 1 ? @a : $a[0];
}

=item code

=cut

sub code
{
	my $self		= shift;
	my $standard	= shift;
	my $type		= shift;

	my $query	= { standard => $standard, type => $type };
	my $path	= Locale::Geocode->_serialize_query('code', $query);

	my $set = $self->{node}->find($path);

	return undef if not $set->size;

	my @a = map { $_->getChildNode(1)->toString } $set->get_nodelist;

	return scalar @a > 1 ? @a : $a[0];
}

=item num

=cut

sub num
{
	return shift->code(iso => 'numeric');
}

=item alpha2

=cut

sub alpha2
{
	return shift->code(iso => 'alpha2');
}

=item alpha3

=cut

sub alpha3
{
	return shift->code(iso => 'alpha3');
}

=item fips

=cut

sub fips
{
	return shift->code(fips => '');
}

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

returns an array of Locale::Geocode::Division objects
representing all territorial divisions.  this method
honors the configured extensions.

=cut

sub divisions
{
	my $self = shift;

	return map { $self->lookup($_->{code}) || () } @{ $self->{data}->{division} };
}

=item divisions_sorted

the same as divisions, only all objects are sorted
according to the specified metadata.  if metadata
is not specified (or is invalid), then all divisions
are sorted by name.  the supported metadata is any
data-oriented method of Locale::Geocode::Division
(name, code, fips, region, et alia).

=cut

sub divisions_sorted
{
	my $self = shift;
	my $meta = lc shift || 'name';

	$meta = 'name' if not grep { $meta eq $_ } @Locale::Geocode::Division::meta;

	return sort { $a->$meta cmp $b->$meta } $self->divisions;
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
 L<Locale::Geocode::Division>

=cut

1;
