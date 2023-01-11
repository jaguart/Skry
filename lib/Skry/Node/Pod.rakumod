use v6.d+;
use Skry::Node;

class Skry::Node::Pod is Skry::Node {

    has $.thing     is rw;
    has @.content   is rw;

    our sub create-tree ( $pod, :$node is copy, :$depth=0 ) {

        # we basically need to split pod.contents into:
        # 1. Content for THIS NODE - only simple things like Array of Str
        # 2. --or-- KID Nodes
        # You probably shouldn't have both @!content and .kids... <-- thing about this

        # PRE-NODE CREATION content stringification
        my @content;
        given $pod {
            #when Pod::Block::Table      {  }
            when Pod::Block::Code       { @content.append( .contents.join('').split("\n") ) }   # \n are present
            when Pod::Block::Declarator { @content.append( .leading // '', .trailing // '' )  }
            when Pod::Block::Comment    { @content.append( .contents.join('').split("\n") ) }   # \n are present
            default {
                @content.append( .contents.flat ) if all(.?contents) ~~ Str;
            }
        }

        # Create ROOT node or add ourselves as a kid to an existing node.
        $node = $node ?? $node.add-kid(
                            :thing($pod),
                            :content(@content),
                         )
                      !! $?CLASS.new(
                            :thing($pod),
                            :content(@content),
                         );


        # create nodes form $pod itself
        given $pod {
            when Iterable           { create-tree( $_, :$node, :depth($depth+1) ) for $pod.flat  }
        }

        # create nodes from POD .contents if we haven't already determined @content.
        if not @content and $pod.?contents ~~ Iterable {
            create-tree( $_, :$node, :depth($depth+1) ) for $pod.contents.flat;
        }

        $node;

    }


    submethod TWEAK {
        self.name ||= $!thing.^name ~ ($!thing.?name ?? ' ' ~ $!thing.?name !! '' );
        if $!thing.^name eq 'Str' and not @!content {
            @!content.append($!thing)
        }
    }

    method descr ( --> Str ) {

        my $leading = '';
        given $!thing {
            when Pod::Defn              { $leading = "{$!thing.term}: "    }
            when Pod::Heading           { $leading = "{$!thing.level}: "   }
            when Pod::FormattingCode    { $leading = "{$!thing.type}: "    }
            when Pod::Item              { $leading = "{$!thing.level}: "   }
            when Pod::Block::Table      { $leading = "{$!thing.caption}: " }
        }

        my $trailing = '';
        given $!thing {
            when Pod::Block::Table      { $trailing = ' ' ~ $!thing.headers.join('␤ ') }
        }

        my $content = @!content.join('␤');

        $content ||= "{$!thing.elems} elems" if $!thing ~~ Array;
        $content ||= ".contents {$!thing.?contents.elems} elems" if $!thing.?contents;

        $content = $content.raku if $content ~~ / ^^ \s* $$ /;

        ( $leading, $content, $trailing ).grep(*.so).join(' ');

    }

    #| compress Pod::Blocks that just have a single kid
    method compress-pod-nodes {

        .compress-pod-nodes for self.kids;

        if not self.content.elems and self.kids.elems == 1 {
            my $kid = self.kids[0];

            if self.thing ~~ Array or $kid.thing ~~ Pod::Block::Para {
                if self.thing ~~ Array {
                    say 'replaced: ', $kid.id, ' ',$kid.name, ' -> ', self.id, ' ', self.name;
                    self.thing  = $kid.thing ;
                    self.name   = $kid.name;
                    self.left   = $kid.left;
                }
                else {
                    say 'merged:   ', $kid.id, ' ',$kid.name, ' -> ', self.id, ' ', self.name;
                }
                self.content.append( $kid.content.flat );
                self.kids.append( $kid.kids.flat );
                self.del-kid(0);
            }
            else {
                say 'skipped:  ', $kid.id, ' ',$kid.name, ' -> ', self.id, ' ', self.name;
            }
        }


    }



}