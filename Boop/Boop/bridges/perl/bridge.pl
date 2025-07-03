#!/usr/bin/env perl
use strict;
use warnings;
use JSON::PP;
use Encode;
use File::Spec;

my $MODULE_EXT = $ENV{BOOP_MODULE_EXT} || '.pl';
my $SCRIPT_DIR = $ENV{BOOP_SCRIPT_DIR} || '';
my $LIB_DIR = $ENV{BOOP_LIB_DIR} || '';

my $state_json = $ENV{BOOP_STATE} || '{}';
my $data = decode_json($state_json);

package State;
sub new {
    my ($class, $d) = @_;
    my $self = {
        text => $d->{text},
        fullText => $d->{fullText},
        selection => $d->{selection},
        network => $d->{network},
        inserts => [],
        messages => []
    };
    bless $self, $class;
    return $self;
}
sub post_info { my ($s,$m)=@_; push @{$s->{messages}}, {type=>'info', message=>$m}; }
sub post_error { my ($s,$m)=@_; push @{$s->{messages}}, {type=>'error', message=>$m}; }
sub insert { my ($s,$v)=@_; push @{$s->{inserts}}, $v; }
sub fetch {
    my ($s,$url,$method,$body)=@_;
    return undef unless $s->{network};
    my @cmd = ('curl','-sL');
    push @cmd,('-X',$method) if defined $method && $method ne 'GET';
    push @cmd,('--data',$body) if defined $body;
    push @cmd,$url;
    my $out = `@cmd`;
    if ($?==0){ return Encode::decode('UTF-8',$out); }
    else { $s->post_error('Failed to fetch'); return undef; }
}
sub to_hash { my $s=shift; return { text=>$s->{text}, fullText=>$s->{fullText}, selection=>$s->{selection}, inserts=>$s->{inserts}, messages=>$s->{messages} }; }
1;

package main;

sub boop_require {
    my ($path) = @_;
    my $p = $path;
    $p .= $MODULE_EXT unless $p =~ /\Q$MODULE_EXT\E$/;
    my $full;
    if ($p =~ /^\@boop\//) {
        $full = File::Spec->catfile($LIB_DIR, substr($p,6));
    } else {
        $full = File::Spec->catfile($SCRIPT_DIR, $p);
    }
    if (-e $full) {
        do $full;
    } else {
        CORE::require($path);
    }
}
my $script = shift @ARGV;
my $state = State->new($data);
boop_require("./$script");
State::post_error($state,'No main function') unless defined &main;
main($state) if defined &main;
print encode_json($state->to_hash);
