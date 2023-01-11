use v6.d+;
use Skry::Node;

use Grok;
use Grok::Wisp;
#use Grok::Moppet;

use Grok::Utils :cleanup-mop-name, :is-core-class;

use Skry::Grok;
use Skry::Cargo;

our %GROKED;

our $DEBUG = False;


class Skry::Node::Grok is Skry::Node {

    ## not everything we sort has a .Str
    #my &sort-any = { ($^a.gist // '') cmp ($^b.gist // '') };

    has $.type      is rw;  # Str - type of node
    has $.thing     is rw;  # Underlying object/class
    has @.content   is rw;  # Array of Str - textual description, defaults to .gist

    # name          pair.key or inferred <-- in Node
    # value         pair.value ot thing
    # wisp          wisp(value))
    # content       descr or (Wisp) gist
    has $.wisp;

    sub short-name ( Str $name ) {
        $name.split('::').tail
    }


    #| compress Pod::Blocks that just have a single kid
    method compress-grok-nodes {

        .compress-grok-nodes for self.kids;

        if is-core-class($!thing) and self.kids.elems == 1 {

            my $kid = self.kids[0];

            if self.thing ~~ Array {
                if self.thing ~~ Array {
                    say 'replaced: ', $kid.id, ' ',$kid.name, ' -> ', self.id, ' ', self.name if $DEBUG;
                    self.thing  = $kid.thing ;
                    self.name   = $kid.name;
                    self.left   = $kid.left;
                }
                else {
                    say 'merged:   ', $kid.id, ' ',$kid.name, ' -> ', self.id, ' ', self.name;
                }
                self.content = $kid.content.flat;
                self.kids.append( $kid.kids.flat );
                self.del-kid(0);
            }
            else {
                say 'skipped:  ', $kid.id, ' ',$kid.name, ' -> ', self.id, ' ', self.name if $DEBUG;
            }
        }
    }



    submethod TWEAK {

        $!wisp      ||= Wisp.new(:thing($!thing<>),:notwhom);

        # direct .name, direct .key, mop.name or type.
        #self.name   ||= try $!thing.?name || $!thing.?key  || $!wisp.mop.var-name || $!wisp.mop.name || $!type;

        self.name   ||= $!wisp.whom;
        $!type      ||= $!wisp.what;


        if self.name.^name ne 'Str' {

            # e.g. BOOTStr

            say '';
            say 'type : ', $!thing.^name;
            say 'type type: ', $!type.^name;
            say 'name type: ', self.name.^name;
            try say '?name ', ($!thing.?name).^name;
            try say '?key  ', ($!thing.?key ).^name;
            say 'var-name ', ($!wisp.mop.var-name).^name;
            say 'name ', ($!wisp.mop.name ).^name;

            say 'dumping';
            dd $!thing;

            try put $!thing.name;
            #put $!thing.type;

            say '--';

            self.name = 'BOOTStr';

        }


        #@!content.append( $!thing.?descr || $!wisp.gist || $!thing.gist ) unless @!content;
        @!content.append( '- ' ~ ($!wisp.gist || $!thing.gist) ) unless @!content;


    }



    our sub create-tree ( Mu \x, $parent = Nil ) {

        %GROKED = ();

        ##say 'create-tree: ', $x.^name, $x.raku;
        #
        ## we basically need to split pod.contents into:
        ## 1. Content for THIS NODE - only simple things like Array of Str
        ## 2. --or-- KID Nodes
        ## You probably shouldn't have both @!content and .kids... <-- thing about this
        #
        #if $x ~~ Array {
        #
        #    #say ' creating node';
        #    my $wisp = Wisp.new(:thing($x));
        #    my \args  = \( :thing($x), :content($wisp.detail,) );
        #
        #    # Create ROOT node or add ourselves as a kid to an existing node.
        #    my $node = $parent ?? $parent.add-kid( |args ) !! $?CLASS.new( |args );
        #
        #    # a list of things to grok
        #    #for $x.sort(&sort-any) -> $y {
        #    for $x -> $y {
        #        create-tree( $y<>, $node );
        #    }
        #
        #}
        ##elsif $x ~~ Pair and $x.value ~~ Hash {
        ##    # Create ROOT node or add ourselves as a kid to an existing node.
        ##    my \args  = \( :thing(Cargo.new($x.key)), );
        ##    my $node = $parent ?? $parent.add-kid( |args ) !! $?CLASS.new( |args );
        ##    my $grok = _grok( $x.value, $node );
        ##    $node //= $grok;
        ##}
        #else {
        #    #say 'calling _grok';
        #    # We are a thing to grok, so we add our detail here.
        #    my $grok = _grok( $x, $node );
        #    $node //= $grok;
        #}

        _grok( x, $parent );

    }

    #---------------------------------------------------------------------------
    multi sub _grok ( CompUnit::Repository::Distribution \x , $parent ) {

        say 'grok Distributon: ', x.gist.substr(0,100) if $DEBUG;

        my \args = \( :thing(x), :content(x.Str,) );
        my $node = $parent ?? $parent.add-kid( |args ) !! $?CLASS.new( |args );

        #_grok( x.dist, $node );
        $node.add-kid( :name('dist.Str'), :thing(x.dist.Str) );
        $node.add-kid( :name('dist.meta-file'), :thing(x.dist.meta-file), :content(x.dist.meta-file.Str) );
        $node.add-kid( :name('dist.prefix'), :thing(x.dist.prefix),:content(x.dist.meta-file.Str) );

        #        dist
        $node.add-kid( :name($_), :thing(x."$_"() ) )
            for <
                id
                dist-id
            >;

        my $meta = $node.add-kid( :name('Meta'), :thing(Nil) );
        $meta.add-kid( :name($_.key), :thing($_.value) )
            for x.meta.pairs.sort;

        $parent // $node

    }

    #---------------------------------------------------------------------------
    multi sub _grok ( Array \x , $parent ) {

        #return $node if %GROKED{$x.WHICH}++;
        say 'grok Array: ', x.elems, ' elements' if $DEBUG;

        my \args = \( :thing(x), :content( ( x.^name, 'with', x.elems, 'elements').join(' '), ) );
        my $node = $parent ?? $parent.add-kid( |args ) !! $?CLASS.new( |args );

        for x -> $y {
            #say 'grokking array element: ', $y.raku.substr(0,80);
            _grok( $y<>, $node );
        }

        $parent // $node

    }

    #---------------------------------------------------------------------------
    multi sub _grok ( Mu \x where { $_.HOW ~~ ( Metamodel::ModuleHOW | Metamodel::PackageHOW ) }, $parent ) {

        say 'grok Package/Module: ', x if $DEBUG;

        my \args = \( :thing(x), );
        my $node = $parent ?? $parent.add-kid( |args ) !! $?CLASS.new( |args );

        #if $x.HOW ~~ Metamodel::ModuleHOW  {
        #    say 'dumping module';
        #    say 'raku       ', x.?raku;
        #    say 'ver        ', try x.^ver;
        #    say 'version    ', try x.^version;
        #    say 'auth       ', x.?auth;
        #    say 'api        ', try x.^api;
        #    say 'name       ', x.^name;
        #    say 'shortname ', x.^shortname;
        #    say '';

        # Not yet working -
        $node.add-kid( :name( 'shortname' ), :thing( x.shortname  )  ) if try x.api;
        $node.add-kid( :name( 'ver'       ), :thing( x.ver        )  ) if try x.ver;
        $node.add-kid( :name( 'version'   ), :thing( x.version    )  ) if try x.version;
        $node.add-kid( :name( 'auth'      ), :thing( x.auth       )  ) if try x.auth;
        $node.add-kid( :name( 'api'       ), :thing( x.api        )  ) if try x.api;

        $node.add-kid( :name( 'shortname' ), :thing( x.^shortname )  ); # if try x.^api;
        $node.add-kid( :name( 'ver'       ), :thing( x.^ver       )  ) if try x.^ver;
        $node.add-kid( :name( 'version'   ), :thing( x.^version   )  ) if try x.^version;
        $node.add-kid( :name( 'auth'      ), :thing( x.^auth      )  ) if try x.^auth;
        $node.add-kid( :name( 'api'       ), :thing( x.^api       )  ) if try x.^api;

        #}

        my $mop = Grok::Moppet.new(:thing(x));
        _grok( $_, $node ) for $mop.knows;

        grok(x) if $mop.exports;

        $parent // $node;



    }


    #---------------------------------------------------------------------------
    multi sub _grok ( CompUnit \x , $parent ) {

        say 'grok CompUnit: ', x.short-name if $DEBUG;

        my \args = \( :thing(x), :content(x.short-name,) );
        my $node = $parent ?? $parent.add-kid( |args ) !! $?CLASS.new( |args );
        #say 'created ', $node.id, ' ', $node.name;

        $node.add-kid( :name('repo.prefix'), :thing(x.repo.prefix), :content(x.repo.prefix.Str,) )
            if try x.repo.prefix;

        #        repo
        for <
                short-name
                repo-id
                auth
                version
                api
                from
        > -> $x {
            $node.add-kid( :name($x), :thing(x."$x"() ) );
        }

        # delve into the distribution associated with this run/compunit
        _grok( x.distribution, $node );

        # delve into the namespaces associated with this run/compunit
        for x.handle.globalish-package.values -> $namespace {
            #say 'namespace: ', $namespace, $namespace.^name, $namespace.HOW.^name;
            #@things.append( $namespace );
            _grok( $namespace, $node );
        }



        $parent // $node

    }


    #---------------------------------------------------------------------------
    multi sub _grok ( Pair:D \x, $parent ) {

        #return $node if %GROKED{$x.WHICH}++;

        say 'grok - Pair ', x if $DEBUG;


        my $wv = Wisp.new(:thing(x.value));

        my $name = x.key.subst(/^\&/,''); # sub-names, sigh

        my $node;

        if  $name ne short-name($wv.mop.var-name) and
            $name ne short-name($wv.mop.name) {
            # We only create a Pair node if the value does NOT have a name

            say 'key: ', $name, ' not in ', $wv.mop.var-name.raku , ' or ', $wv.mop.name.raku, ' - ', $wv.mop.type ;

            my \args = \( :thing(x) );
            $node = $parent ?? $parent.add-kid( |args ) !! $?CLASS.new( |args );
        }
        else {
            #say 'skipped pair node: ', x.gist;
        }

        # EXPORT<ALL>(...) and EXPORT<DEFAULT>(...) seem to screw this all up

        #say 'pair-value is: ', x.value.^name, ' - ', x.value.raku;


        _grok( x.value, $node // $parent );

        $parent // $node

    }

    #---------------------------------------------------------------------------
    # Grok Mu - fallback
    multi sub _grok ( Mu \x, $parent ) is default {

        #return $node if %GROKED{$x.WHICH}++;
        say 'grok Mu: ', x.gist if $DEBUG;

        #say ' grok Mu node: ', ($x.gist || $x.raku);

        my $wisp    = Wisp.new(:thing(x));
        my $mop     = $wisp.mop;

        my \args = \( :thing(x) ); # no content...
        my $node = $parent ?? $parent.add-kid( |args ) !! $?CLASS.new( |args );

        if $mop.parents.grep({ not $_ =:= Any and not $_ =:= Mu }) {
            _grok(
                Cargo.new(
                    :name('Parents'),
                    :values( $mop.parents ),
                ),
               $node,
            )
        }

        if $mop.roles {
            _grok(
                Cargo.new(
                    :name('Roles'),
                    :values( $mop.roles ),
                ),
               $node,
            )
        }

        if $mop.exports {
            _grok(
                Cargo.new(
                    :name('Exports'),
                    :values( $mop.exports ),
                ),
               $node,
            )
        }

        # Knows AFTER exports to supress duplicate-knows
        #if $mop.knows {
        #    _grok(
        #        Cargo.new(
        #            :name('Knows'),
        #            :parts( $mop.knows ),
        #        ),
        #       $node,
        #    )
        #}



        if $mop.attributes {
            _grok(
                Cargo.new(
                    :name('Attributes'),
                    :values( $mop.attributes ),
                ),
               $node,
            )
        }

        if $mop.methods {
            _grok(
                Cargo.new(
                    :name('Methods'),
                    :values( $mop.methods ),
                ),
               $node,
            )
        }

        $node;
    }


    #---------------------------------------------------------------------------
    # We use the Cargo class to package things up for easier grokking
    # It has .name .descr .thing .values .parts
    multi sub _grok ( Skry::Cargo:D \x, $parent ) {

        #return $node if %GROKED{$x.WHICH}++;

        say 'grok Cargo: ', x.name, ' ', x.descr if $DEBUG;

        my \args = \(
                    :name(x.name),
                    :thing(x.thing),
                    :content( x.descr // () ),
                    );

        my $node = $parent ?? $parent.add-kid( |args ) !! $?CLASS.new( |args );

        for x.values -> $y {

            if $y ~~ Pair {
                $node.add-kid(
                    :name($y.key<>),
                    :thing($y.value<>),
                );
            }
            else {
                $node.add-kid(
                    :thing($y<>),
                );
            }
        }

        for x.parts -> $y {
            _grok( $y ~~ Pair ?? $y.value<> !! $y<>, $node );
        }

        $parent // $node

    }

    #---------------------------------------------------------------------------
    #| .defined and is-core-class($_)
    multi sub _grok ( Mu:D \x where { is-core-class($_) }, $parent ) {

        #return $node if %GROKED{$x.WHICH}++;

        say 'grok CORE:: ', x.gist.substr(0,100) if $DEBUG;
        say 'is-core-class: ', is-core-class(x);

        my $wisp    = Wisp.new(:thing(x));
        my $mop     = $wisp.mop;


        my \args = \( :thing(x) );
        my $node = $parent ?? $parent.add-kid( |args ) !! $?CLASS.new( |args );

        if x ~~ Hash and x.elems {
            my $nx = $node.add-kid(
                                :thing(Cargo.new('Values')),
                            );
            for x.pairs -> $y {
                my $wy = Wisp.new(:thing($y<>));
                $nx.add-kid(
                    :thing($y<>),
                );
            }

        }

        $parent // $node
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

        $content        ||= "{$!thing.elems} elems" if $!thing ~~ Array;
        #try $content    ||= ".contents {$!thing.?contents.elems} elems" if $!thing.?contents;

        # Show empty strings with quotes
        $content = $content.raku if $content ~~ / ^^ \s+ $$ /;

        ( $leading, $content, $trailing ).grep(*.so).join(' ');

    }

}