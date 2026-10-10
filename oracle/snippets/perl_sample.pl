#!/usr/bin/perl
use strict;
use warnings;
use JSON::XS qw(encode_json);

# Сервис пользователей
package UserService;

our $VERSION = '1.0';
my $counter = 0;

sub new {
    my ($class, %args) = @_;
    my $self = bless { name => $args{name} // 'anon', items => [] }, $class;
    return $self;
}

sub add_item {
    my ($self, $item) = @_;
    push @{ $self->{items} }, $item if defined $item && $item ne '';
    return scalar @{ $self->{items} };
}

sub to_json {
    my ($self) = @_;
    return encode_json($self);
}

package main;

my $svc = UserService->new(name => 'Олег');
$svc->add_item($_) for qw(a b c);
my @sorted = sort { $a <=> $b } map { length } @{ $svc->{items} };
my %h = (x => 1, y => [2, 3]);
print "$svc->{name}: ", $svc->add_item('d'), " $VERSION\n" if @sorted > 2;
my $re = qr/^\w+[-_]?\d{2,}$/i;
print "match\n" if 'abc-12' =~ $re;
