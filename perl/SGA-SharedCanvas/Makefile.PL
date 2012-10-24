#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install 1.02;
use Module::Install::Catalyst; # Complain loudly if you don't have
                               # Catalyst::Devel installed or haven't said
                               # 'make dist' to create a standalone tarball.

name 'SGA-SharedCanvas';
all_from 'lib/SGA/SharedCanvas.pm';

requires 'Catalyst::Runtime' => '5.90012';

requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Plugin::StackTrace';
requires 'Catalyst::Plugin::StatusMessage';
requires 'Catalyst::Plugin::Session';
requires 'Catalyst::Plugin::Session::State::Cookie';
requires 'Catalyst::Plugin::Session::Store::FastMmap';
requires 'Catalyst::Plugin::Unicode::Encoding';

requires 'Catalyst::Action::RenderView';
requires 'Catalyst::Action::REST';

requires 'Catalyst::Model::DBIC::Schema';

requires 'Catalyst::View::TT';

requires 'CatalystX::RoleApplicator';

requires 'Moose';
requires 'MooseX::MethodAttributes::Role';
requires 'MooseX::MarkAsMethods' => '0.13';
requires 'MooseX::NonMoose' => '0.16';
requires 'MooseX::Singleton' => '0.29';

requires 'Config::General';
requires 'Data::UUID';
requires 'Data::Verifier';
requires 'DateTime';
requires 'DBIx::Class';
requires 'DBIx::Class::Schema::Loader';
requires 'JSON';
requires 'Lingua::EN::Inflect';
requires 'Set::Scalar';
requires 'String::CamelCase';

requires 'namespace::autoclean';

test_requires 'Test::More' => '0.88';
catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
