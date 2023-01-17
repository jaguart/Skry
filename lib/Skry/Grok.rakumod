use v6;

use Kaolin::Utils :CompUnit-from-file;

use Skry::Cargo;


#| Grok helper
class Skry::Grok {

    #------------------------------------------------------------------------------
    our sub load-from-file ( IO::Path:D $file --> Array ) {

        my $comp = CompUnit-from-file( $file );
        my $dist = $comp.distribution;

        my @things =
            $comp,
            #$dist,
            ;

        #for $comp.handle.globalish-package.values -> $namespace {
        #    @things.append( $namespace );
        #}

        @things;

    }


}