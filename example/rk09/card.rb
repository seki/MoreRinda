require 'drb/drb'

ro = DRbObject.new_with_uri(ARGV.shift)

name = ARGV.shift || 'your_nick'
url = ARGV.shift || 'http://www.druby.org'
desc = ARGV.shift || 'no comment is good comment'

p ro.exchange(name, url, desc)

