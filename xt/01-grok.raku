use v6.d+;

use lib $*CWD, $?FILE.IO.parent;
#use lib <lib>;

#use Skry::Grok;

#use Kaolin::Node;
use Skry::Node::Grok;

my @grok;
my $source-file = @*ARGS ?? @*ARGS.shift !! Nil;
if $source-file {
    say 'loading: ', $source-file;
    @grok = Skry::Grok::load-from-file( $source-file.IO );
}

my $root = Skry::Node::Grok::create-tree( @grok  );
#say 'initial tree'; $root.dump;;
say $root.count-nodes, ' nodes';
say '';

$root.compress-grok-nodes;
say '';

#say 'compressed tree: ';
$root.dump(:nodir);
say '';
say $root;
say '';

my $id = @*ARGS ?? @*ARGS.shift !! Nil;
if $id.defined {
    say 'dd ', $id;
    dd $root.get($id);
}
