package ODataTypes;
use Moose::Util::TypeConstraints;
use namespace::autoclean;
use MIME::Base64 ();
use DateTime::Tiny;
use Time::Tiny;
use Math::BigInt;
use Math::BigFloat;

our %coerce_map = (
	'Null'               => 0,
	'Edm.Binary'         => 1,
        'Edm.Boolean'        => 1,
	'Edm.Byte'           => 1,
	'Edm.DateTime'       => 1,
	'Edm.Decimal'        => 0,
        'Edm.Double'         => 1,
	'Edm.Single'         => 0,
        'Edm.Guid'           => 1,
        'Edm.Int16'          => 0,
        'Edm.Int32'          => 0,
        'Edm.Int64'          => 1,
        'Edm.SByte'          => 0,
        'Edm.String'         => 0,
        'Edm.Time'           => 1,
#        'Edm.DateTimeOffset' => 1,
);

# Needs a coercion?
subtype 'Null',
	as 'Item';

# Base64 encoded stream
subtype 'Edm.Binary',
    as 'Defined';

coerce 'Edm.Binary',
    from 'Str',
    via { MIME::Base64::decoded($_) };

# string which is either "true" or "false"
subtype 'Edm.Boolean',
    as 'Bool';

coerce 'Edm.Boolean',
    from 'Str',
    via { $_ eq "true" ? 1 : 0 };

# 8 bit unsigned integer value
subtype 'Edm.Byte',
    as 'Int';

coerce 'Edm.Byte',
    from 'Str',
    via { hex($_) };

# Example format: 2000-12-12T12:00
subtype 'Edm.DateTime',
    as 'Maybe[DateTime::Tiny]';

coerce 'Edm.DateTime',
    from 'Str',
    via { DateTime::Tiny->from_string($_) };

subtype 'Edm.Decimal',
    as 'Num';

subtype 'Edm.Double',
    as 'Math::BigFloat';

coerce 'Edm.Double',
    from 'Str',
    via { Math::BigFloat->new($_) };

subtype 'Edm.Single',
    as 'Num';

# dddddddd-dddd-dddd-dddd-dddddddddddd
subtype 'Edm.Guid',
    as 'Str';
    where { /[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}/ },
    message { 'The value provided is not a valid GUID.' };

subtype 'Edm.Int16',
    as 'Int';

subtype 'Edm.Int32',
    as 'Int';

subtype 'Edm.Int64',
    as 'Math::BigInt';

coerce 'Edm.Int64',
    from 'Str',
    via { Math::BigInt->new($_) };

# signed 8 bit integer
subtype 'Edm.SByte',
    as 'Int';

subtype 'Edm.String',
    as 'Str';

subtype 'Edm.Time',
    as 'Time::Tiny';

coerce 'Edm.Time',
    from 'Str',
    via { Time::Tiny->from_string($_) };

#subtype 'Edm.DateTimeOffset',
#    as 'DateTime::Offset';

#coerce 'Edm.DateTimeOffset',
#    from 'Str',
#    via { DateTime::Offset->new($_) };

1;
