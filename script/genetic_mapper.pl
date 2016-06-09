#!/usr/bin/perl
# $Revision: 0.7 $
# $Date: 2016/06/09 $
# $Id: genetic_mapper.pl $
# $Author: Michael Bekaert $
#
# Vectorial Genetic Map Drawer
# Copyright (C) 2012-2016 Bekaert M <michael.bekaert@stir.ac.uk>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# POD documentation - main docs before the code

=head1 NAME

Genetic-mapper - SVG Genetic Map Drawer

=head1 SYNOPSIS

  # Command line help
  ..:: Vectorial Genetic Map Drawer ::..
  
  Usage: ./genetic_mapper.pl [options] --map=<map.tsv>
  
  Options
   --map <genetic map file>
         The input file must be a text file with at least the marker name (ID), linkage
         group (LG) and the position (POS) separeted by tabulations. Additionally a
         logarithm of odds (LOD score) can be provided. Any extra parameter will be
         ignored.
           ID     LG    POS     LOD
           M19    12    0.01    0.45068
           M18    12    1.14    0.00014
           M40    12    11.48   0.25284
    --chr <string>
         Draw only the specified chromosome/linkage group.
    --delim <character>
         Use <character> as the field delimiter character instead of the tab character.
    --bar
         Use a coloured visualisation with a dark bar at the marker position.
    --plot
         Rather than a list of marker names, it plots a circle. If the LOD-score is
         provided a dark disk fills the circle proportionality to its value.
    --var
         If specified with --bar or --plot the size of the bar/circle is proportional to
         the number of markers.
    --col
         If --plot is specified and if more that one LOD-score column is available specify
         the column number [default 1 (first LOD-score column)].
    --square
         Small squares are used rather than names (incompatible with --plot).
    --pos
         The marker positions are indicated on the left site of the chromosome.
    --compact
         A more compact chromosome is used (incompatible with --bar).
    --karyotype=<karyotype.file>
         Specify a karytype to scale the physical chromosme. Rather than using genetic
         distances, expect nucleotide position in the map file.
          FORMAT: "chr - ID LABEL START END COMMENT"
    --scale= ]0,+oo[
         Change the scale of the figure [default x10].
    --horizontal
         Rotate the figure by 90 degrees.
    --verbose
         Become chatty.


  # stylish
  ./genetic_mapper.pl --var --compact --plot --map=map.tsv > lg13.svg

  # Classic publication style
  ./genetic_mapper.pl --pos --chr=13 --map=map.tsv > lg13.svg


=head1 DESCRIPTION

Perl script for creating a publication-ready vectorial genetic/linkage map in Scalable
Vector Graphics (SVG) format. The resulting file can either be submitted for publication
and edited with any vectorial drawing software like Inkscape and Abobe Illustrator(R).

The input file must be a text file with at least the marker name (ID), linkage group (LG)
and the position (POS) separeted by tabulations. Additionally a logarithm of odds (LOD
score) can be provided. Any extra parameter will be ignored.

	ID<tab>LG<tab>POS<tab>LOD
	13519  12     0       0.250840894
	2718   12     1.0     0.250840893
	11040  12     1.6     0.252843341
	...


=head1 FEEDBACK

User feedback is an integral part of the evolution of this modules. Send your comments
and suggestions preferably to author.

=head1 AUTHOR

B<Michael Bekaert> (michael.bekaert@stir.ac.uk)

The latest version of genetic_mapper.pl is available at

  https://github.com/pseudogene/genetic-mapper

=head1 LICENSE

Copyright 2012-2016 - Michael Bekaert

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

use strict;
use warnings;
use Scalar::Util qw(looks_like_number);
use Getopt::Long;

#----------------------------------------------------------
our ($VERSION) = 0.7;

#----------------------------------------------------------
my ($verbose, $shify, $delim, $horizontal, $bar, $square, $var, $pflag, $scale, $compact, $column, $plot, $font, $karyotype, $map, $chr) = (0, 30, '\t', 0, 0, 0, 0, 0, 10, 0, 1, 0);
GetOptions(
           'm|map=s'         => \$map,
           'delim:s'         => \$delim,
           'k|karyotype:s'   => \$karyotype,
           'scale:f'         => \$scale,
           'horizontal!'     => \$horizontal,
           'bar!'            => \$bar,
           'square!'         => \$square,
           'var!'            => \$var,
           'p|pos|position!' => \$pflag,
           'compact!'        => \$compact,
           'plot!'           => \$plot,
           'col:i'           => \$column,
           'c|chr:s'         => \$chr,
           'v|verbose!'      => \$verbose
          );
my $yshift = ($pflag ? 150 : 0);
my @font = ('Helvetica', 4, 13, 10);
if ($scale > 0 && defined $map && -r $map && (open my $IN, q{<}, $map) && defined $column && $column > 0)
{
    my (@clips,       @final);
    my (%chromosomes, %max);
    my ($maxmax,      $maxlog);
    <$IN>;
    while (<$IN>)
    {
        next if (m/^#/);
        chomp;
        my @data = split m/$delim/;
        if (scalar @data > 2 && defined $data[1] && (!defined $chr || $data[1] eq $chr))
        {
            my $chromosomeid = (looks_like_number($data[1]) ? sprintf("%02.0f", int($data[1] * 10) / 10) : $data[1]);
            my $location = int($data[2] * 1000);
            if (!exists $chromosomes{$chromosomeid}{$location}) { @{$chromosomes{$chromosomeid}{$location}} = ($data[0], 1, (exists($data[2 + $column]) && looks_like_number($data[2 + $column]) ? $data[2 + $column] : -1)); }
            else
            {
                $chromosomes{$chromosomeid}{$location}[0] .= q{,} . $data[0];
                $chromosomes{$chromosomeid}{$location}[1] += 1;
                $chromosomes{$chromosomeid}{$location}[2] += (exists($data[2 + $column]) && looks_like_number($data[2 + $column]) ? $data[2 + $column] : 0);
            }
            if (!exists $max{$chromosomeid} || $max{$chromosomeid} < $location / 1000)
            {
                $max{$chromosomeid} = $location / 1000;
                $maxmax = $max{$chromosomeid} if (!defined $maxmax || $maxmax < $max{$chromosomeid});
            }
            $maxlog = $data[3] if (exists($data[2 + $column]) && looks_like_number($data[2 + $column]) && length($data[2 + $column]) > 0 && (!defined $maxlog || $maxlog < $data[2 + $column]));
        }
    }
    close $IN;
    if (defined $karyotype && -r $karyotype && (open my $KIN, q{<}, $karyotype))
    {
        while (<$KIN>)
        {
            chomp;
            my @data = split m/ /;
            if (scalar @data > 5 && defined $data[0] && $data[0] eq 'chr' && defined $data[2] && defined $data[5] && exists $max{(looks_like_number($data[2]) ? sprintf("%02.0f", int($data[2] * 10) / 10) : $data[2])})
            {
                $max{(looks_like_number($data[2]) ? sprintf("%02.0f", int($data[2] * 10) / 10) : $data[2])} = $data[5];
                $maxmax = $max{(looks_like_number($data[2]) ? int($data[2] * 10) / 10 : $data[2])} if (!defined $maxmax || $maxmax < $max{(looks_like_number($data[2]) ? sprintf("%02.0f", int($data[2] * 10) / 10) : $data[2])});
            }
        }
        close $KIN;
    }
    if (scalar keys %chromosomes > 0)
    {
        my $i = 0;
        foreach my $chrnum (sort { $a cmp $b } keys %chromosomes)
        {
            $yshift += (($pflag ? 100 : 0) + 300) if ($i++ > 0);
            print {*STDERR} '***** Linkage Group ', $chrnum, " *****\n" if ($verbose);
            my (@locussite, @legend);
            my $plast = -999;
            foreach my $locus (sort { int($a) <=> int($b) } keys %{$chromosomes{$chrnum}})
            {
                my $locus2 = int($locus) / 1000;
                print {*STDERR} $locus2, "\t", $chromosomes{$chrnum}{$locus}[0], "\t", (defined $chromosomes{$chrnum}{$locus}[2] ? $chromosomes{$chrnum}{$locus}[2] : q{}), "\n" if ($verbose);
                my $size = 5 + ($var ? ($chromosomes{$chrnum}{$locus}[1] * 0.05 * $scale) : 0);
                my $position = ($locus2 >= ($plast + ($font[2] / $scale)) ? $locus2 : $plast + ($font[2] / $scale));
                my $shpos = ($position - $locus2) * $scale;
                if ($bar)
                {
                    push @locussite, '   <path class="locus" d="M' . $yshift . q{ } . ($shify + ($locus2 * $scale) + ($size / 2)) . 'h40v-' . $size . 'h-40z"/>';
                    if ($pflag)
                    {
                        push @legend, '  <path class="line" d="M' . ($yshift - 5 - 12 - 39) . q{,} . ($shify + ($locus2 * $scale) + ($shpos)) . 'h12,l39,-' . ($shpos) . 'l0,0' . 'h54l39,' . ($shpos) . 'l0,0h12"/>';
                        push @legend, '  <path class="whiteline" d="M' . ($yshift + 5) . q{,} . ($shify + ($locus2 * $scale)) . 'h34"/>' if ($locus2 > 0 && $locus2 < $max{$chrnum});
                    }
                    else
                    {
                        push @legend, '  <path class="line" d="M' . ($yshift + 22) . q{,} . ($shify + ($locus2 * $scale)) . 'h27l39,' . ($shpos) . 'l0,0h12"/>';
                        push @legend, '  <path class="whiteline" d="M' . ($yshift + 22) . q{,} . ($shify + ($locus2 * $scale)) . 'h17"/>' if ($locus2 > 0 && $locus2 < $max{$chrnum});
                    }
                }
                else
                {
                    if ($pflag) { push @legend, '  <path class="line" d="M' . ($yshift - 5 - 12 - 39) . q{,} . ($shify + ($locus2 * $scale) + ($shpos)) . 'h12,l39,-' . ($shpos) . 'l0,0' . 'h54l39,' . ($shpos) . 'l0,0h12"/>'; }
                    else        { push @legend, '  <path class="line" d="M' . ($yshift + 22) . q{,} . ($shify + ($locus2 * $scale)) . 'h27l39,' . ($shpos) . 'l0,0h12"/>'; }
                }
                if ($pflag) { push @legend, '  <text class="text" text-anchor="end" x="' . ($yshift - 105 + 41) . '" y="' . ($shify + ($locus2 * $scale) + $shpos + $font[1]) . '">' . $locus2 . '</text>'; }
                if ($plot)
                {
                    push @legend,
                        "  <g opacity=\"0.7\">\n   <circle fill=\"none\" stroke=\"#000000\" stroke-width=\"0.25\" cx=\""
                      . ($yshift + ($var ? 125 : 115))
                      . '" cy="'
                      . ($shify + ($locus2 * $scale) + $shpos) . '" r="'
                      . $size
                      . "\"/>\n   <circle cx=\""
                      . ($yshift + ($var ? 125 : 115))
                      . '" cy="'
                      . ($shify + ($locus2 * $scale) + $shpos) . '" r="'
                      . (length($chromosomes{$chrnum}{$locus}[2]) > 0 ? ($chromosomes{$chrnum}{$locus}[2] > 0 ? ((($chromosomes{$chrnum}{$locus}[2] / $chromosomes{$chrnum}{$locus}[1]) * $size) / $maxlog) : $size) : 0)
                      . "\"/>\n  </g>";
                }
                elsif ($square)
                {
                    push @legend, '  <g opacity="0.7">';
                    for my $i (1 .. $chromosomes{$chrnum}{$locus}[1]) { push @legend, '   <rect x="' . ($yshift + 105 + $i * 4) . '" y="' . ($shify + ($locus2 * $scale) + $shpos - 3) . '" width="2" height="7" />'; }
                    push @legend, '  </g>';
                }
                else { push @legend, '  <text class="text" x="' . ($yshift + 105) . '" y="' . ($shify + ($locus2 * $scale) + $shpos + $font[1]) . '">' . $chromosomes{$chrnum}{$locus}[0] . '</text>'; }
                $plast = $position;
            }
            if ($bar) {
                push @clips,
                  '  <clipPath id="clip_'
                  . $chrnum
                  . "\">\n   <path d=\"M"
                  . ($yshift + 5) . q{ }
                  . ($shify + ($max{$chrnum} * $scale) - 15.37)
                  . 'c0 22.7 34 22.7 34 0v-'
                  . (($max{$chrnum} * $scale) - 30.7)
                  . "c0 -22.7 -34 -22.7 -34 0z\"/>\n  </clipPath>";
            }
            push @final, ' <g id="Layer_' . $chrnum . '">';
            push @final, '  <text class="text" style="font-size:' . ((3 * $font[3]) / 2) . 'pt;" text-anchor="middle" x="' . ($yshift + 22) . '" y="' . ((($shify + ((3 * $font[3]) / 2)) / 2) - $font[1]) . '">' . $chrnum . '</text>';
            if ($bar) { push @final, '   <g id="locii_' . $chrnum . '" clip-path="url(#clip_' . $chrnum . ")\">\n  <rect x=\"" . $yshift . '" y="0" width="40" height="' . ((2 * $shify) + ($max{$chrnum} * $scale)) . '" fill="url(#bgrad)"/>'; }
            else
            {

                if ($compact)
                {
                    push @final,
                        '  <g id="locii_'
                      . $chrnum
                      . "\">\n   <path d=\"M"
                      . ($yshift + 12) . q{,}
                      . ($shify + ($max{$chrnum} * $scale) - 5.37)
                      . 'c0,15.37,20,15.37,20,0V'
                      . (($shify + ($max{$chrnum} * $scale) - 5.37) - (($max{$chrnum} * $scale) - 10.7))
                      . 'c0-15.33-20-15.33-20,0V'
                      . ($shify + ($max{$chrnum} * $scale) - 10.37) . 'z"/>';
                }
                else
                {
                    push @final,
                        '  <g id="locii_'
                      . $chrnum
                      . "\">\n   <path class=\"line\" style=\"stroke-width:3;\" d=\"M"
                      . ($yshift + 5) . q{ }
                      . ($shify + ($max{$chrnum} * $scale) - 15.37)
                      . 'c0 22.7 34 22.7 34 0v-'
                      . (($max{$chrnum} * $scale) - 30.7)
                      . 'c0 -22.7 -34 -22.7 -34 0z"/>';
                }
            }
            push @final, @locussite;
            push @final, '  </g>';
            push @final, @legend;
            push @final, ' </g>';
        }
        print {*STDOUT} "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\" \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">\n";

        #remove the  * 2
        print {*STDOUT} '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="', ($horizontal ? ((2 * $shify) + ($maxmax * 2 * $scale)) . '" height="' . ($yshift + 250) : ($yshift + 250) . '" height="' . ((2 * $shify) + ($maxmax * $scale))),
          "\">\n";
        print {*STDOUT} " <defs>\n";
        if ($bar) { print {*STDOUT} join("\n", @clips), "\n"; }
        print {*STDOUT} "  <style type=\"text/css\">\n   .text { font-size: ", $font[3], 'pt; fill: #000; font-family: ', $font[0], "; }\n   .line { stroke:#000; stroke-width:", ($compact ? '0.75' : '1'), "; fill:none; }\n";
        if ($bar) { print {*STDOUT} "   .whiteline { stroke:#fff; stroke-width:1.5; fill:none; }\n   .locus { fill:url(#lograd); }\n"; }
        print {*STDOUT} "  </style>\n";
        if ($bar)
        {
            print {*STDOUT}
              "  <linearGradient id=\"bgrad\" x1=\"0%\" y1=\"0%\" x2=\"100%\" y2=\"0%\">\n   <stop offset=\"0%\"   style=\"stop-color:#BBA\"/>\n   <stop offset=\"50%\"  style=\"stop-color:#FFE\"/>\n   <stop offset=\"100%\" style=\"stop-color:#BBA\"/>\n  </linearGradient>\n  <linearGradient id=\"lograd\" x1=\"0%\" y1=\"0%\" x2=\"100%\" y2=\"0%\">\n   <stop offset=\"0%\"   style=\"stop-color:#000\"/>\n   <stop offset=\"50%\"  style=\"stop-color:#666\"/>\n   <stop offset=\"100%\" style=\"stop-color:#000\"/>\n  </linearGradient>\n";
        }
        print {*STDOUT} " </defs>\n";
        print {*STDOUT} ' <g id="main" transform="rotate(-90 0 0) translate(-', ($yshift + 250), ")\">\n" if ($horizontal);
        print {*STDOUT} join("\n", @final), "\n";
        print {*STDOUT} " </g>\n" if ($horizontal);
        print {*STDOUT} "</svg>\n";
    }
}
else
{
    print {*STDERR}
      "\n..:: Vectorial Genetic Map Drawer ::..\n\nUsage: ./genetic_mapper.pl [options] --map=<map.tsv>\n\nOptions\n --map <genetic map file>\n       The input file must be a text file with at least the marker name (ID), linkage\n       group (LG) and the position (POS) separeted by tabulations. Additionally a\n       logarithm of odds (LOD score) can be provided. Any extra parameter will be ignored.\n         ID     LG    POS     LOD\n         M19    12    0.01    0.45068\n         M18    12    1.14    0.00014\n         M40    12    11.48   0.25284\n  --chr <string>\n       Draw only the specified chromosome/linkage group.\n  --delim <character>\n       Use <character> as the field delimiter character instead of the tab character.\n  --bar\n       Use a coloured visualisation with a dark bar at the marker position.\n  --plot\n       Rather than a list of marker names, it plots a circle. If the LOD-score is provided\n       a dark disk fills the circle proportionality to its value.\n  --var\n       If specified with --bar or --plot the size of the bar/circle is proportional to the\n       number of markers.\n  --col\n       If --plot is specified and if more that one LOD-score column is available specify\n       the column number [default 1 (first LOD-score column)].\n  --square\n       Small squares are used rather than names (incompatible with --plot).\n  --pos\n       The marker positions are indicated on the left site of the chromosome.\n  --compact\n       A more compact chromosome is used (incompatible with --bar).\n  --karyotype=<karyotype.file>\n       Specify a karytype to scale the physical chromosme. Rather than using genetic\n       distances, expect nucleotide position in the map file.\n        FORMAT: \"chr - ID LABEL START END COMMENT\"\n  --scale= ]0,+oo[\n       Change the scale of the figure [default x",
      $scale, "].\n  --horizontal\n       Rotate the figure by 90 degrees.\n  --verbose\n       Become chatty.\n\n";
}
