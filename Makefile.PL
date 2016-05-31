use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => 'Genetic_Mapper',
    AUTHOR => 'Michaël Bekaert (michael.bekaert@stir.ac.uk)',
    ABSTRACT => 'SVG Genetic Map Drawer',
    LICENSE => 'gpl_3',
    PREREQ_PM => { 'Getopt::Long' => 0, 'Scalar::Util' => 0 },
    VERSION_FROM => 'script/genetic_mapper.pl',
    EXE_FILES => [ 'script/genetic_mapper.pl' ],
    META_MERGE => {
        resources => {
            repository  => {
                url  => 'git://github.com/pseudogene/genetic-mapper.git',
                web  => 'https://github.com/pseudogene/genetic-mapper',
                type => 'git',
            },
        }, 
    },
);