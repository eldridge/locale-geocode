package Locale::Geocode;

use strict;
use warnings;

=head1 NAME

Locale::Geocode

=head1 DESCRIPTION

Locale::Geocode provides data and an associated interface
with which to locate abbreviations and other information on
geographical entities and their administrative subdivisions.
Locale::Geocode focuses primarily on the political entities
described within ISO 3166-1 and ISO 3166-2, but is capable
of supporting other standards such as FIPS.  It is the most
complete ISO 3166 module available on CPAN.

=head1 SYNOPSIS

 my $lc     = new Locale::Geocode;

 # retrieve a Locale::Geocode::Territory object
 # for the ISO 3166-1 alpha-2 code 'US'
 my $lct    = $lc->lookup('US');

 # retrieve ISO 3166-1 information for US
 my $name   = $lct->name;   # United States
 my $alpha2 = $lct->alpha2; # US
 my $alpha3 = $lct->alpha3; # USA
 my $num    = $lct->num;    # 840

 # lookup a subdivision of US
 my $lcd    = $lct->lookup('TN');

 # retrieve ISO 3166-2 information for US-TN
 my $name   = $lcd->name;   # Tennessee
 my $code   = $lcd->code;   # TN

 # returns an array of Locale::Geocode::Division
 # objects representing all divisions of US
 my @divs   = $lct->divisions;

 # retrieve a Locale::Geocode::Division object
 # for the ISO 3166-1/ISO 3166-2 combo 'GB-ESS'
 my $lct    = $lc->lookup('GB-ESS');

 # retrieve ISO 3166-2 information for GB-ESS
 # as well as special regional information
 my $name   = $lct->name;   # Essex
 my $code   = $lct->name;   # ESS
 my $region = $lct->region; # ENG

=head1 SOURCES

 Wikipedia - http://en.wikipedia.org/wiki/ISO_3166
 Statoids - http://www.statoids.com

=head1 CONFORMING TO

 BS 6879
 ISO 3166-1
 ISO 3166-1 Newsletter V-1 (1998-02-05; Samoa)
 ISO 3166-1 Newsletter V-2 (1999-10-01; Occupied Palestinian Territory)
 ISO 3166-1 Newsletter V-3 (2002-02-01; Romania)
 ISO 3166-1 Newsletter V-4 (2002-05-20; Name changes)
 ISO 3166-1 Newsletter V-5 (2002-05-20; East Timor)
 ISO 3166-1 Newsletter V-6 (2002-11-15; Timor-Leste)
 ISO 3166-1 Newsletter V-7 (2003-01-14; Comoros)
 ISO 3166-1 Newsletter V-8 (2003-07-23; Serbia and Montenegro)
 ISO 3166-1 Newsletter V-9 (2004-02-13; &#xc5;land Islands)
 ISO 3166-1 Newsletter V-10 (2004-04-26; Name changes)
 ISO 3166-1 Newsletter V-11 (2006-03-29; Jersey, Guernsey, Isle of Man)
 ISO 3166-1 Newsletter V-12 (2006-09-26; Serbia, Montenegro)
 ISO 3166-2
 ISO 3166-2 Newsletter I-1 (2000-06-12)
 ISO 3166-2 Newsletter I-2 (2002-05-21)
 ISO 3166-2 Newsletter I-3 (2002-08-20)
 ISO 3166-2 Newsletter I-4 (2002-12-10)
 ISO 3166-2 Newsletter I-5 (2003-09-05)
 ISO 3166-2 Newsletter I-6 (2004-03-08)
 ISO 3166-2 Newsletter I-7 (2006-09-12)

=cut

our $VERSION = '2.00';

use Locale::Geocode::Data;
use Locale::Geocode::Territory;
use Locale::Geocode::Division;

# Locale::Geocode extensions.  the following recognized extensions
# are switchable flags that alter the behavior of the lookup methods.
# many of these extensions are part of the ISO 3166 standard as a
# courtesy to other international organizations (such as the UPU or
# ITU).  others are specific to Locale::Geocode for other practical
# reasons (such as the usm extension for US overseas military or
# usps for all US postal abbreviations).

my @exts = qw(upu wco itu uk fx eu usm usps ust);
my @defs = qw(ust);

my $defctypes = { iso => 'alpha2', fips => '' };

=head1 METHODS

=over 4

=item new

=cut

sub new
{
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $args = { @_ };
	my $self = {};

	bless $self, $class;

	my @exts = @defs;

	if ($args->{ext}) {
		my $reftype = ref $args->{ext};

		die 'ext argument must be scalar or list reference'
			if $reftype ne '' && $reftype ne 'ARRAY';

		@exts = $reftype eq 'ARRAY' ? @{ $args->{ext} } : $args->{ext};
	}

	$self->ext(@exts);

	return $self;
}

=item lookup

=cut

sub lookup
{
	my $self = shift;

	# allow multiple lookups in a single call by handling
	# the special case of an array reference being passed

	if (ref $_[0] eq 'ARRAY') {
		my @a = @{ $_[0] };

		if (scalar @a == scalar grep { ref eq '' } @a) {
			return map { $self->lookup($_) || () } @a;
		}

		my %h = @a;

		return map { $self->lookup($_ => $h{$_}) || () } keys %h;
	}

	# maintain 1.x compatibility for hashref lookups by
	# flattening the hashref (which should be the first
	# argument) and prepending the 'iso' standard.

	# this is not be a 1.x feature, but i'm keeping it here
	# as a reminder of wtf i was trying to do before the
	# disk failure

	#@_ = ('iso', %{$_[0]}) if ref $_[0] eq 'HASH';

	# maintain 1.x compatibility by allowing single argument
	# lookups.  this has the side effect of a shortcut that
	# defaults to the iso standard, so it's likely to stay.

	return $self->lookup(iso => $_[0]) if scalar @_ == 1;

	# now we're ready to party

	my $standard	= shift;
	my $query		= shift;

	# maintain 1.x compatibility for hypenated lookups that
	# return a Locale::Geocode::Division object rather than
	# a Locale::Geocode::Territory object.  this practice is
	# discouraged.  use lookup_division instead.

	if (ref $query eq '' && $query =~ /-/) {
		warn 'hypenated lookups are deprecated; use lookup_division instead';

		return $self->lookup_division(iso => $query);
	}

	# now we get a list of queries, making sure to normalize
	# them into hashrefs by inserting the default code type
	# for the standard where required.

	my @queries = map { ref($_) ? { standard => $standard, %$_ } : { $defctypes->{$standard} => $_ } }
		ref $query eq 'ARRAY' ? @$query : ($query);

	my $path	= join '|', map { $self->_serialize_query('/geocode/territory', $_) } @queries;
	my $set		= Locale::Geocode::Data->xp->find($path);
	my @a		= map { new Locale::Geocode::Territory $self, $_ } $set->get_nodelist;

	return scalar(@a > 1) ? @a : $a[0];
}

sub lookup_division
{
	my $self = shift;

	# maintain 1.x compatibility by allowing single argument
	# lookups.  this has the side effect of a shortcut that
	# defaults to the iso standard, so it's likely to stay.

	return $self->lookup_division(iso => $_[0]) if scalar @_ == 1;

	my $standard	= shift;
	my $query		= shift;

	my ($a, $b) = split '-', $query;

	my $lgt = $self->lookup($standard => $a);

	return $lgt ? $lgt->lookup($b) : undef;
}

my @attrs = qw(lang standard type);
my $atmap = { alpha2 => [ code => 'type' ], alpha3 => [ code => 'type' ] };

my $pathmap = {
	'/geocode/territory' =>
	{
		type		=> '@type',
		standard	=> 'code/@standard'
	},

	'name' =>
	{
		type		=> '@type',
		lang		=> '@lang'
	},

	'code' =>
	{
		type		=> '@type',
		standard	=> '@standard'
	}
};

sub _serialize_query
{
	my $self	= shift;
	my $root	= shift;
	my $ref		= shift;

	my $expr	= $root;

	#my $query	= join ' and ', map { "$pathmap->{$_} = $ref->{$_}" } keys %$ref;

	#return $root . '[' . $query . ']';

	for (ref $ref) {
		/^$/ && do
		{
			$expr = "$root\[code = '$ref']|$root\[name = '$ref']";

			last;
		};

		/HASH/ && do
		{
			my @terms = ();

			foreach my $key (keys %$ref) {
				my $val = $ref->{$key};

				if (my $exp = $pathmap->{$root}->{$key}) {
					push @terms, "$pathmap->{$root}->{$key} = '$val'";
					#$expr .= $self->_serialize_query('', { $exp->[0] => $val });

					#$val = $key;
					#$key = $exp->[1];
				} else { 
					push @terms, "code = '$val'";
					push @terms, 'code/@type = ' . "'$key'";
				}

				#if (scalar grep { $_ eq $key } @attrs) {
				#	$key = "attribute::$key";
				#}

				#$expr .= "[$key='$val']";
			}

			$expr .= '[' . join(' and ', @terms) . ']';

			last;
		};

		die "unable to handle $_ in query";
	}

	#print "expression for $root: $expr\n";

	return $expr;
}

=item territories

=cut

sub territories
{
	my $self = shift;

#	return map { $self->lookup($_) || () } keys %{ $data->{alpha2} };
}

=item territories_sorted

=cut

sub territories_sorted
{
	my $self = shift;

	return sort { $a->name cmp $b->name } $self->territories;
}

=item territories_sorted_us

=cut

sub territories_sorted_us
{
	my $self = shift;

	sub sorted_us
	{
		return -1 if $a->alpha2 eq 'US';
		return 1  if $b->alpha2 eq 'US';
		return $a->name cmp $b->name;
	};

	return sort sorted_us $self->territories;
}

=item ext

=cut

sub ext
{
	my $self = shift;

	if (scalar @_ > 0) {
		$self->{ext} =
		{
			ust => 1, # 'ust' is always on unless explicitly disabled
			map {
				/^-(.*)$/
					? ($1 => 0)
					: $_ eq 'all'
						? map { $_ => 1 } @exts
						: ($_ => 1)
			} @_
		};
	}

	return grep { $self->{ext}->{$_} } keys %{ $self->{ext} };
}

=item ext_enable

=cut

sub ext_enable
{
	my $self = shift;

	foreach my $ext (@_) {
		$self->{ext}->{$ext} = 1 if grep { $ext eq $_ } @exts;
	}
}

=item ext_disable

=cut

sub ext_disable
{
	my $self = shift;

	delete $self->{ext}->{$_} foreach @_;
}

sub chkext
{
	my $self = shift;
	my $href = shift;

	return $href->{ext} ? grep { $self->{ext}->{$_} } @{ $href->{ext} } : 1;
}

#sub data { return $data }

sub import { @defs = @_[1..$#_] }

=back

=cut

=head1 AUTHOR

 Mike Eldridge <diz@cpan.org>

=head1 CREDITS

 Kim Ryan

=head1 SEE ALSO

 L<Locale::Geocode::Territory>
 L<Locale::Geocode::Division>

=cut

1;

