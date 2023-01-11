use v6.d+;

use nqp;

#| Pod helper
class Skry::Pod {

    #------------------------------------------------------------------------------
    #| create Hash from NQP BOOTContext
    sub BOOTContext(Mu \context) {
        my $hash := nqp::hash;
        my \iterator := nqp::iterator(context);
        nqp::while(
          iterator,
          nqp::bindkey(
            $hash,
            nqp::iterkey_s(nqp::shift(iterator)),
            nqp::iterval(iterator)
          )
        );
        #note context.^name ~ '(' ~ nqp::substr(nqp::hllize($hash).raku.chop,1) ~ ')';
        $hash;
    }

    #------------------------------------------------------------------------------
    our sub load-from-file ( IO::Path:D $file ) {

        # irc: <nine> $*REPO might be better
        # Jeff 08-Jan-2023 and hoorah, no global name clash :)
        # ...because... it returns THE EXISTING UNIT IF ALREADY LOADED :)
        #
        # rakudo/src/core.c/Process.pm6 70
        # rakudo/src/core.c/CompUnit/RepositoryRegistry.pm6 125 -
        #   $next-repo := CompUnit::Repository::AbsolutePath.new(
        #       :next-repo(CompUnit::Repository::NQP.new(
        #           :next-repo(CompUnit::Repository::Perl5.new(
        #   #?if jvm
        #           :next-repo(CompUnit::Repository::JavaRuntime.new)
        # rakudo/src/core.c/CompUnit/Repository/FileSystem.pm6 150 <--
        BOOTContext( $*REPO.load( $file.IO ).unit )<$=pod>;
    }


}