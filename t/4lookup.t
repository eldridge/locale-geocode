use Test::More tests => 78;

use_ok('Locale::Geocode');

my $lg;

$lg = new Locale::Geocode;
ok(defined($lg), 'new Locale::Geocode object');

$lgt = $lg->lookup('US');
