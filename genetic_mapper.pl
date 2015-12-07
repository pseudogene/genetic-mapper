#!/usr/bin/perl
# $Revision: 0.4 $
# $Date: 2013/02/15 $
# $Id: genetic_mapper.pl $
# $Author: Michael Bekaert $
#
# SVG Genetic Map Drawer
# Copyright 2012-2013 Bekaert M <mbekaert@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
# POD documentation - main docs before the code

=head1 NAME

Genetic-mapper - SVG Genetic Map Drawer

=head1 SYNOPSIS

  # Command line help
  ..:: SVG Genetic Map Drawer ::..
  > Standalone program version 0.4 <

  Usage: genetic_mapper.pl [-options] --map=<map.csv>

   Options
     --chr=<name>
           Draw only the specified chromosome/linkage group.
     --bar
           Use a coloured visualisation with a dark bar at the marker position.
     --plot
           Rather than a list marker names, plots a circle. If the LOD-score is
           provided a dark disk fill the circle proportionality to its value.
     --var
           If specified with --bar or --plot the size of the bar/circle is
           proportional to the number of markers.
     --square
           Small squares are used rather than names (incompatible with --plot).
     --pos
           The marker positions are indicated on the left site of the chromosome.
     --compact
           A more compact/stylish chromosome is used (incompatible with --bar).
     --karyotype=<karyotype.file>
           Specify a karytype to scale the physical chromosme. Rather than using
           genetic distances, expect nucleotide position in than map file.
           FORMAT: "chr - ID LABEL START END COMMENT"
     --scale= ]0,+oo[
           Change the scale of the figure (default x10).
     --verbose
           Become chatty.


  # stylish
  ./genetic_mapper.pl --var --compact --plot --map=map.csv > lg13.svg

  # Classic publication style
  ./genetic_mapper.pl --pos --chr=13 --map=map.csv > lg13.svg

=head1 DESCRIPTION

Perl script for creating a publication-ready genetic/linkage map in SVG format. The
resulting file can either be submitted for publication and edited with any vectorial
drawing software like Inkscape and Abobe Illustrator.

The input file must be a CSV file with at least the marker name (ID), linkage group (Chr)
and the position (Pos). Additionally a LOD score or p-value can be provided. Any extra
parameter will be ignore.

	ID,Chr,Pos,LOD
	13519,12,0,0.250840894
	2718,12,1.0,0.250840893
	11040,12,1.6,0.252843341
	...


=head1 FEEDBACK

User feedback is an integral part of the evolution of this modules. Send your
comments and suggestions preferably to author.

=head1 AUTHOR

B<Michael Bekaert> (mbekaert@gmail.com)

The latest version of genetic_mapper.pl is available at

  http://genetic-mapper.googlecode.com/

=head1 LICENSE

Copyright 2012-2013 - Michael Bekaert

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.

=cut

use strict;
use warnings;
use Getopt::Long;

#----------------------------------------------------------
our ($VERSION) = 0.4;

#----------------------------------------------------------
my ($verbose, $shify, $bar, $square, $var, $pflag, $scale, $compact, $plot, $font, $karyotype, $map, $chr) = (0, 30, 0, 0, 0, 0, 10, 0, 0);
GetOptions('m|map=s' => \$map, 'k|karyotype:s' => \$karyotype, 'scale:f' => \$scale, 'bar!' => \$bar, 'square!' => \$square, 'var!' => \$var, 'p|pos|position!' => \$pflag, 'compact!' => \$compact, 'plot!' => \$plot, 'c|chr:s' => \$chr, 'v|verbose!' => \$verbose);
my $yshift = ($pflag ? 100 : 0);

my @font   = ('Helvetica', 4, 13, 10);
#my @font=('InaiMathi',4,13,11);
#my @font=('Optima',4,13,10);
#my @font=('Lucida Console',4,13,10);
#my @font=('Myriad Pro',4,13,10);

if ($scale>0 && defined $map && -r $map && (open my $IN, '<', $map))
{
    my (@clips,       @final);
    my (%chromosomes, %max);
    my ($maxmax,      $maxlog);
    <$IN>;
    while (<$IN>)
    {
        chomp;
        my @data = split m/,/;
        if (scalar @data > 2 && defined $data[1] && (!defined $chr || $data[1] eq $chr))
        {
		    my $location = int($data[2] * 1000);
            if (!exists $chromosomes{$data[1]}{$location}) { @{$chromosomes{$data[1]}{$location}} = ($data[0], 1, (exists($data[3]) ? $data[3] : -1)); }
            else
            {
                $chromosomes{$data[1]}{$location}[0] .= q{,} . $data[0];
                $chromosomes{$data[1]}{$location}[1] += 1;
                $chromosomes{$data[1]}{$location}[2] += (exists($data[3]) ? $data[3] : 0);
            }
            if (!exists $max{$data[1]} || $max{$data[1]} < $location / 1000)
            {
                $max{$data[1]} = $location / 1000;
                $maxmax = $max{$data[1]} if (!defined $maxmax || $maxmax < $max{$data[1]});
            }
            $maxlog = $data[3] if (!defined $maxlog || $maxlog < $data[3]);
        }
    }
    close $IN;
    if (defined $karyotype && -r $karyotype && (open my $KIN, '<', $karyotype))
    {
        while (<$KIN>)
        {
            chomp;
            my @data = split m/ /;
            if (scalar @data > 5 && defined $data[0] && $data[0] eq 'chr' && defined $data[2] && defined $data[5] && exists $max{$data[2]})
            {
                $max{$data[2]} = $data[5];
                $maxmax = $max{$data[2]} if (!defined $maxmax || $maxmax < $max{$data[2]});
            }
        }
        close $KIN;
    }
    if (scalar keys %chromosomes > 0)
    {
        my $i = 0;
        foreach my $chrnum (sort { $a eq $b } keys %chromosomes)
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
                      . ($chromosomes{$chrnum}{$locus}[2] > 0 ? ((($chromosomes{$chrnum}{$locus}[2] / $chromosomes{$chrnum}{$locus}[1]) * $size) / $maxlog) : $size)
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
                        '  <g id="locii_' . $chrnum . "\">\n   <path d=\"M"
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
                        '  <g id="locii_' . $chrnum . "\">\n   <path class=\"line\" style=\"stroke-width:3;\" d=\"M"
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
        print {*STDOUT} '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="', (($yshift + 300)), '" height="', ((2 * $shify) + ($maxmax * $scale)), "\">\n";
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
        print {*STDOUT} join("\n", @final), "\n";
        print {*STDOUT} "</svg>\n";
    }
} else {
    print {*STDERR} "\n  ..:: SVG Genetic Map Drawer ::..\n  > Standalone program version $VERSION <\n\n  Usage: $0 [-options] --map=<map.csv>\n\n   Options\n     --chr <string>\n           Draw only the specified chromosome/linkage group.\n     --bar\n           Use a coloured visualisation with a bark bar at the marker position.\n     --plot\n           Rather than a list marker names, plots a circle. If the LOD-score is\n           provided a dark disk fill the circle proportionality to its value.\n     --var\n           If specified with --bar or --plot the size of the bar/circle is\n           proportional to the number of markers.\n     --square\n           Small squares are used rather than names (incompatible with --plot).\n     --pos\n           The marker positions are indicated on the left site of the chromosome.\n     --compact\n           A more compact/stylish chromosome is used (incompatible with --bar).\n     --karyotype=<karyotype.file>\n           Specify a karytype to scale the physical chromosme. Rather than using\n           genetic distances, expect nucleotide position in than map file.\n           FORMAT: \"chr - ID LABEL START END COMMENT\"\n     --scale= ]0,+oo[\n           Change the scale of the figure (default x10).\n     --verbose\n           Become chatty.\n\n";
}
