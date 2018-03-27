package Util;
use common::sense;

use XML::Atom::Client;
use URI::Escape qw(uri_escape_utf8);
use AnyEvent;
use AnyEvent::HTTP;
use Data::Dumper::Concise;

my $DEBUG = 1;

sub p($) { warn Dumper $_[0] }
sub debug($) { say $_[0] if $DEBUG }

my $BASE_URL = 'http://b.hatena.ne.jp/Cside/atomfeed?tag=' . uri_escape_utf8('あとで読む');

my $count = get_unread_count();
my @urls = get_urls($count);
my @atoms = fetch_atoms(@urls);
my @ids = get_ids_by_atoms(@atoms);

sub get_unread_count {
    my $parser = XML::Atom::Client->new;
    my $feed = $parser->getFeed($BASE_URL);

    my ($count) = $feed->title =~ /\((\d+)\)$/;
    if ($count !~ /^[0-9]+$/) {
        die 'Not a integer';
    }
    debug "Current unreads: $count";

    return $count;
}

sub get_urls {
    my ($count) = @_;

    my $offset = 0;
    my $limit  = 20;

    my @urls;
    while ($offset < $count) {
        push @urls, (
            ($offset == 0) ? $BASE_URL
                           : "$BASE_URL&of=$offset"
        );
        $offset += $limit;
    }

    return @urls;
}

sub fetch_atoms {
    my (@urls) = @_;

    my @atoms; 
    my $cv = AnyEvent->condvar;
    for my $url (@urls) {
    	debug "Start $url";
    	$cv->begin;
    	http_get $url, sub {
    		my ($content, $headers) = @_;
            if ($headers->{Status} == 200) {
                push @atoms, $content;
            }
    		$cv->end;
    	};
    }
    $cv->recv;

    if (scalar(@urls) != scalar(@atoms)) {
        die 'URL fetch error';
    }
    return @atoms
}

sub get_ids_by_atoms {
    my (@atoms) = @_;
    my @ids;
    for my $atom (@atoms) {
        my $feed = XML::Atom::Feed->new(\$atom);
        for my $entry ($feed->entries) {
            push @ids, $entry->link->href;
        }
    }
    return @ids;
}

1;