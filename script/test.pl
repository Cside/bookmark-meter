#!/usr/bin/env perl
use common::sense;
use XML::Atom::Client;
use URI::Escape qw(uri_escape_utf8);
use AnyEvent;
use AnyEvent::HTTP;
use Data::Dumper::Concise;

sub p($) { warn Dumper $_[0] }

my $BASE_URL = 'http://b.hatena.ne.jp/Cside/atomfeed?tag=' . uri_escape_utf8('あとで読む');

my @urls = get_urls();
my @atoms = fetch_atoms(@urls);
my @ids = get_ids_by_atoms(@atoms);

sub get_urls {
    my $parser = XML::Atom::Client->new;
    my $feed = $parser->getFeed($BASE_URL);

    my ($count) = $feed->title =~ /\((\d+)\)$/;
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
    	say "Start $url";
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
        die 'Error';
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
