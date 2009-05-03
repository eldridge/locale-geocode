use Test::More tests => 78;

use strict;

use_ok('Locale::Geocode');

my @tests =
(
	{
		name => 'union path for 1.x compatibility',
		root => 'territory',
		data => 'US',
		path => q(territory[code = 'US']|territory[name = 'US'])
	},
	{
		name => 'terse code lookup',
		root => 'territory',
		data => { alpha3 => 'USA' },
		path => q(territory[code = 'USA' and code/@type = 'alpha3']),
	},
	{
		name => '',
		root => 'territory/division',
		data => { type => 'province' },
		path => q(territory/division[@type = province])
	}
);

is(serialize($_->{root}, $_->{data}), $_->{path}, $_->{name}) foreach @tests;

sub serialize { Locale::Geocode->_serialize_query(@_) }

