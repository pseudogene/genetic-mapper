Genetic-mapper v0.6 - SVG Genetic Map Drawer

[![Build Status](https://travis-ci.org/pseudogene/genetic-mapper.svg?branch=master)](https://travis-ci.org/pseudogene/genetic-mapper)

#Genetic-mapper

Genetic-mapper is a perl script able to draw publication-ready vectorial genetic maps.

##Description

Perl script for creating a publication-ready genetic/linkage map in SVG format. The resulting file can either be submitted for publication and edited with any vectorial drawing software like Inkscape and Abobe Illustrator.

The input file must be a CSV file with at least the marker name (ID), linkage group (Chr) and the position (Pos). Additionally a LOD score or p-value can be provided. Any extra parameter will be ignore.

```
map.csv

ID,Chr,Pos,LOD
13519,12,0,0.250840894
2718,12,1.0,0.250840893
11040,12,1.6,0.252843341
...
```

##Installation (optional)

You can directly use the script `script/genetic_mapper.pl` or install it in your system using:

```
git clone https://github.com/pseudogene/genetic-mapper.git
cd genetic-mapper
perl Makefile.pl
make
make test
sudo make install
```

##Examples

```
# stylish
./genetic_mapper.pl --var --compact --plot --map=map.csv > lg.svg

# Classic publication style
./genetic_mapper.pl --pos --chr=13 --map=map.csv > lg13.svg
```

![LG13](lg13.png "LG13 stylish or classic")