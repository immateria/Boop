# {
#     "api": 1,
#     "name": "Perl Reverse",
#     "description": "Reverses your text using Perl",
#     "author": "Codex",
#     "icon": "rotate-left",
#     "tags": "reverse,perl"
# }

sub main {
    my ($state) = @_;
    if ($state->{text}) {
        $state->{text} = reverse $state->{text};
    }
}
1;
