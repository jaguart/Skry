use v6.d+;

use lib $?FILE.IO.parent;
use lib <lib>;

use Skry::Pod;
use Skry::Node::Pod;


=begin pod

=head1 NAME

grok, wisp - introspection helpers.


=head1 SYNOPSIS

From the command line:

=begin code :lang<bash>

raku -MGrok -e 'grok( my $a = 42, :deeply :core)'

raku -MGrok -e 'say wisp( Endian )'

=end code
=end pod

=begin pod

=head1 DESCRIPTION

Grok contains B<introspection> helpers that display information about Raku things.

For example: You want to know how many times a sub is wrapped - grok a golf to see what methods are available.

etc.

=for head2
Level Two

and then...

=head2 Abbreviated Heading

So there was some input:

=input
this is input
from my keyboard - appears as code in pod

and then there was resulting output

=output
some output from my terminal
over two lines - comes out as code


=comment Add more here about the algorithm
and a second line
and a third

and a paragraph



=head1 Tables

=begin table
 hdr col 0 | hdr col 1
 ======================
 row 0     | row 0
 col 0     | col 1
 ----------------------
 row 1     | row 1
 col 0     | col 1
 ----------------------
=end table

And another with a Caption:

=begin table :caption<My Tasks>
mow lawn
take out trash
=end table

=begin table :caption<One Row Table>
fix something new
=end table


=end pod

#say $=pod[0].contents[0].contents.raku;
#dd $=pod;
#say '';

my $pod = $=pod;


my $source-file = @*ARGS ?? @*ARGS.shift !! Nil;
if $source-file {
say 'loading: ', $source-file;
    $pod = Skry::Pod::load-from-file( $source-file.IO );
}

#say '$pod is ', $pod.^name, ' with ', $pod.elems, ' items'; say '';

my $root = Skry::Node::Pod::create-tree( $pod  );
#say 'initial tree'; $root.dump;;
#say $root.count-nodes, ' nodes';
#say '';

$root.compress-pod-nodes;
say '';

say 'compressed tree: ';
$root.dump;
say $root.count-nodes, ' nodes';
say '';

my $id = @*ARGS ?? @*ARGS.shift !! Nil;
dd $root.get($id) if $id.defined;

say $root;


