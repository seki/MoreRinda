require 'rbconfig'
require 'fileutils'

dest = RbConfig::CONFIG['sitelibdir'] + '/rinda'
src = ['lib/rinda/eval.rb']

FileUtils.mkdir_p(dest, {:verbose => true})
src.each do |s|
  FileUtils.install(s, dest, {:verbose => true, :mode => 0644})
end
                  
