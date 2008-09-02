use inc::Module::Install;

name     'Template-Teeny';
all_from 'lib/Template/Teeny.pm';
author   'Scott McWhirter <konobi@cpan.org>';

build_requires 'Test::More';

auto_install;

WriteAll;

