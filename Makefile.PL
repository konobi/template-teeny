use inc::Module::Install;

name     'Template-Teeny';
all_from 'lib/Template/Teeny.pm';
author   'Scott McWhirter <konobi@cpan.org>';

build_requires 'Test::More';
build_requires 'Test::Deep';
build_requires 'Test::Differences';
build_requires 'IO::Scalar';

requires 'Moose' => '0.57';

auto_install;

WriteAll;

