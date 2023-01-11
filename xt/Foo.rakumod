use v6;

unit module Foo:ver<0.2.0>:api<0.0.1>:auth<foo:jaguart>;

role Alice {
    has $!apple;
    method action ( Str $a, Int $b --> Hash ) { }
}

role Bob {
    has $!bobbin;
    method bobbing ( Str $a, Int $b --> Hash ) { }
}

class Carol {
    has $.clue;
    method create {
    }
}

class Dan is Carol does Alice does Bob {
    has $!ding;
    has $!dong;
    multi method doing ( Str $x --> Str ) {}
    multi method doing ( Int $x --> Int ) {}
    submethod TWEAK { }
    method denting ( --> Bool ) { }
}