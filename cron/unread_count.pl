#!/usr/bin/env perl
use common::sense;
use lib 'lib';
use Midoku::Utils qw(get_unread_count tweet);

my $count = get_unread_count();

my $msg = "未読は $count 件です。\nhttp://b.hatena.ne.jp/Cside/%E3%81%82%E3%81%A8%E3%81%A7%E8%AA%AD%E3%82%80/";
tweet($msg);