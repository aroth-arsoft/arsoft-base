#!/usr/bin/ruby1.9.1
require File.dirname(__FILE__) + '/lib/svn2git/migration'

migration = Svn2Git::Migration.new(ARGV)
migration.run!
