#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;
my ($input, $output) = (q{}, q{});
if (open my $out, q{>}, 'test.tsv')
{
    while (<DATA>)
    {
        last if (m/^#/);
        print {$out} $_;
    }
    close $out;
    system './script/genetic_mapper.pl --pos --split --map=test.tsv > test.svg';
    unlink 'test.tsv';
    if (open my $in, q{<}, 'test.svg')
    {
        while (<$in>)
        {
            chomp;
            $input .= $_;
        }
        close $in;
    }
    unlink 'test.svg';
    while (<DATA>)
    {
        chomp;
        $output .= $_;
    }
}
ok($input eq $output, 'tutorial map');
done_testing();
__DATA__
ID	LD	Pos	LOD
13519	12	0	0.250840894
2718	12	1.0	0.250840893
8888	12	1.0	0.357741452
11040	12	1.6	0.252843341
#
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="400" height="76">
 <defs>
  <style type="text/css">
   .text { font-size: 10pt; fill: #000; font-family: Helvetica; }
   .line { stroke:#000; stroke-width:1; fill:none; }
  </style>
 </defs>
 <g id="Layer_12">
  <text class="text" style="font-size:15pt;" text-anchor="middle" x="172" y="18.5">12</text>
  <g id="locii_12">
   <path class="line" style="stroke-width:3;" d="M155 30.63c0 22.7 34 22.7 34 0v--14.7c0 -22.7 -34 -22.7 -34 0z"/>
  </g>
  <path class="line" d="M94,30h12,l39,-0l0,0h54l39,0l0,0h12"/>
  <text class="text" text-anchor="end" x="86" y="34">0</text>
  <text class="text" x="255" y="34">13519</text>
  <path class="line" d="M94,43h12,l39,-3l0,0h54l39,3l0,0h12"/>
  <text class="text" text-anchor="end" x="86" y="47">1</text>
  <text class="text" x="255" y="47">2718</text>
  <path class="line" d="M172,40h27l39,16l0,0h12"/>
  <text class="text" x="255" y="60">8888</text>
  <path class="line" d="M94,69h12,l39,-23l0,0h54l39,23l0,0h12"/>
  <text class="text" text-anchor="end" x="86" y="73">1.6</text>
  <text class="text" x="255" y="73">11040</text>
 </g>
</svg>
