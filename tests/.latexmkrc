$pdf_mode = 4;  # lualatex
$lualatex = "lualatex -interaction=nonstopmode -file-line-error -synctex=1 %O %S";
$out_dir = "build";

# Package directories. run-tests sets MSTEX_ROOT to an absolute path; in an editor it defaults to "..".
my $root = $ENV{MSTEX_ROOT} // "..";
$ENV{TEXINPUTS} = join(":", map { "$root/$_" } qw(beamerthemejoby draft-tools revision-number)) . ":" . ($ENV{TEXINPUTS} // "");

# glossaries: run makeglossaries when the .glo/.acn files change.
add_cus_dep('glo', 'gls', 0, 'run_makeglossaries');
add_cus_dep('acn', 'acr', 0, 'run_makeglossaries');
sub run_makeglossaries {
    my ($base_name, $path) = fileparse($_[0]);
    my @args = ("-d", $path, $base_name);
    return system("makeglossaries", @args);
}
