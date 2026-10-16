$pdf_mode = 4;  # lualatex
$lualatex = "lualatex -interaction=nonstopmode -file-line-error -synctex=1 %O %S";
$out_dir = "build";

# Package directories. run-tests sets MSTEX_ROOT to an absolute path; in an editor it defaults to "..".
my $root = $ENV{MSTEX_ROOT} // "..";
$ENV{TEXINPUTS} = join(":", map { "$root/$_" } qw(beamerthemejoby draft-tools revision-number)) . ":" . ($ENV{TEXINPUTS} // "");
