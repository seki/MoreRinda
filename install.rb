require 'rbconfig'
require 'fileutils'

dest = RbConfig::CONFIG['sitelibdir'] + '/rinda'
src = %w(lib/rinda/eval.rb		lib/rinda/tokyotuplestore.rb
lib/rinda/inspect.rb		lib/rinda/tuplestore.rb
lib/rinda/njet.rb		lib/rinda/version.rb
lib/rinda/ptuplespace.rb)

FileUtils.mkdir_p(dest, {:verbose => true})
src.each do |s|
  FileUtils.install(s, dest, {:verbose => true, :mode => 0644})
end
                  
