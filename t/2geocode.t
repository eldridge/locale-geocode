use Test::More tests => 55;

use_ok('Locale::Geocode');

my $lg;
my $lgt;
my $lgd;
my @lgds;
my $lgt2;

$lg = new Locale::Geocode;
ok(defined($lg), 'new Locale::Geocode object');

$lgt = $lg->lookup('US');
ok(defined($lgt), 'lookup territory via ISO 3166-1 alpha-2 code "US"');
ok($lgt && $lgt->alpha2 eq 'US', 'US: ISO 3166-1 alpha-2 code: ' . $lgt->alpha2);
ok($lgt && $lgt->alpha3 eq 'USA', 'US: ISO 3166-1 alpha-3 code: ' . $lgt->alpha3);
ok($lgt && $lgt->num == 840, 'US: ISO 3166-1 numeric code: ' . $lgt->num);
ok($lgt && $lgt->name =~ /United States/, 'US: ISO 3166-1 name: ' . $lgt->name);
ok("$lgt" eq "US", 'US: object stringifies to "US"');

$lgt2 = $lg->lookup('CA');
ok(defined($lgt2), 'lookup territory via ISO 3166-1 alpha-2 code "CA"');
ok($lgt2 && $lgt2->alpha2 eq 'CA', 'CA: ISO 3166-1 alpha-2 code: ' . $lgt2->alpha2);
ok($lgt2 && $lgt2->alpha3 eq 'CAN', 'CA: ISO 3166-1 alpha-3 code: ' . $lgt2->alpha3);
ok($lgt2 && $lgt2->num == 124, 'CA: ISO 3166-1 numeric code: ' . $lgt2->num);
ok($lgt2 && $lgt2->name =~ /Canada/, 'CA: ISO 3166-1 name: ' . $lgt2->name);
ok("$lgt2" eq "CA", 'CA: object stringifies to "CA"');

# we can't use cmp_ok here because Test::Builder tries to add
# 0 to each argument in order to detect "dualvars" such as $!
ok($lgt != $lgt2, 'overloaded inequality operator');

$lgt2 = $lg->lookup('US');
ok(defined($lgt2), 'lookup territory via ISO 3166-1 alpha-2 code "US"');
ok($lgt2 && $lgt2->alpha2 eq 'US', 'US: ISO 3166-1 alpha-2 code: ' . $lgt2->alpha2);
ok($lgt2 && $lgt2->alpha3 eq 'USA', 'US: ISO 3166-1 alpha-3 code: ' . $lgt2->alpha3);
ok($lgt2 && $lgt2->num == 840, 'US: ISO 3166-1 numeric code: ' . $lgt2->num);
ok($lgt2 && $lgt2->name =~ /United States/, 'US: ISO 3166-1 name: ' . $lgt2->name);
ok("$lgt2" eq "US", 'US: object stringifies to "US"');

# we can't use cmp_ok here because Test::Builder tries to add
# 0 to each argument in order to detect "dualvars" such as $!
ok($lgt == $lgt2, 'overloaded equality operator');

$lgd = $lgt->lookup('TN');
ok(defined($lgd), 'US: lookup division via ISO 3166-2 code "TN"');
ok($lgd && $lgd->code eq 'TN', 'US-TN: ISO 3166-2 code: ' . $lgd->code);
ok($lgd && $lgd->name eq 'Tennessee', 'US-TN: ISO 3166-2 name: ' . $lgd->name);
ok("$lgd" eq "TN", 'US-TN: object stringifies to "TN"');

$lgd = $lgt->lookup('AP');
ok(!defined $lgd, 'US: lookup non ISO 3166-2 code "AP"');

$lgt = $lg->lookup('UK');
ok(!defined $lgd, 'lookup ISO 3166-1 reserved alpha-2 code "UK"');

# enabling single extension for UK->GB mapping
$lg->ext(qw(uk));
ok(eq_array([ sort $lg->ext ], [ qw(uk) ]), 'set extensions for reserved ISO 3166-1 alpha-2 code "UK"');

$lgt = $lg->lookup('UK');
ok(!defined $lgd, 'lookup ISO 3166-1 reserved alpha-2 code "UK"');
ok($lgt && $lgt->alpha2 eq 'UK', 'UK: ISO 3166-1 alpha-2 code: ' . $lgt->alpha2);
ok($lgt && !defined($lgt->alpha3), 'UK: ISO 3166-1 alpha-3 code: N/A');
ok($lgt && !defined($lgt->num), 'UK: ISO 3166-1 numeric code: N/A');
ok($lgt && $lgt->name =~ /United Kingdom/, 'UK: ISO 3166-1 name: ' . $lgt->name);

# usm extension still disabled
$lgt = $lg->lookup('US');
ok(defined($lgt), 'lookup territory via ISO 3166-1 alpha-2 code "US"');

$lgd = $lgt->lookup('AP');
ok(!defined $lgd, 'US: lookup non ISO 3166-2 code "AP"');

@lgds = $lgt->divisions;
ok($lgt->num_divisions == 57, 'US: num_divisions is 57');
ok(scalar @lgds == 57, 'US: divisions method returns a 57 member list');
ok(
	scalar(grep { ref $_ eq 'Locale::Geocode::Division' } @lgds) == 57,
	'US: divisions method returns only Locale::Geocode::Division objects'
);

# enabling multiple extensions at once (US military, UK->GB alias)
$lg->ext(qw(usm uk));
ok(eq_array([ sort $lg->ext ], [ qw(uk usm) ]), 'enable extensions for non ISO 3166 United States Military Postal Service Agency codes');

$lgd = $lgt->lookup('AP');
ok(defined $lgd, 'US: lookup non ISO 3166-2 code "AP"');
ok($lgd && $lgd->name eq 'Armed Forces Pacific', 'US MPSA division name: Armed Forces Pacific');
ok($lgd && $lgd->code eq 'AP', 'US MPSA division code: AP');

@lgds = $lgt->divisions;
ok($lgt->num_divisions == 60, 'US: num_divisions is 60');
ok(scalar @lgds == 60, 'US: divisions method returns a 60 member list');
ok(
	scalar(grep { ref $_ eq 'Locale::Geocode::Division' } @lgds) == 60,
	'US: divisions method returns only Locale::Geocode::Division objects'
);

# enabling multiple extensions at once (European Union and WCO)
$lg->ext(qw(eu wco));
ok(eq_array([ sort $lg->ext ], [ qw(eu wco) ]), 'set extensions for reserved ISO 3166 codes for EU/WCO statistical purposes');

$lgt = $lg->lookup('IC');
ok(defined $lgt, 'IC: lookup territory via reserved ISO 3166-1 alpha-2 code "IC"');
ok($lgt && $lgt->alpha2 eq 'IC', 'IC: ISO 3166-1 alpha-2 code: ' . $lgt->alpha2);
ok($lgt && !defined($lgt->alpha3), 'IC: ISO 3166-1 alpha-3 code: N/A');
ok($lgt && !defined($lgt->num), 'IC: ISO 3166-1 numeric code: N/A');
ok($lgt && $lgt->name eq 'Canary Islands', 'IC: ISO 3166-1 name: ' . $lgt->name);
ok($lgt && $lgt->has_notes, 'IC: has notes');
ok($lgt && $lgt->num_notes == 1, 'IC: number of notes: ' . $lgt->num_notes);
ok($lgt && $lgt->note(0) eq 'reserved on request of WCO to represent area outside EU customs territory', 'IC: note 0: ' . $lgt->note(0));

