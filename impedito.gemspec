Kernel.load 'lib/impedito/version.rb'

Gem::Specification.new {|s|
	s.name         = 'impedito'
	s.version      = Impedito.version
	s.author       = 'meh.'
	s.email        = 'meh@paranoici.org'
	s.homepage     = 'http://github.com/meh/impedito'
	s.platform     = Gem::Platform::RUBY
	s.summary      = 'The "impedito" music player.'

	s.files         = `git ls-files`.split("\n")
	s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
	s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
	s.require_paths = ['lib']

	s.add_dependency 'mpd'
	s.add_dependency 'ncursesw'
}
