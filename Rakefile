task :run do
  threads = []
  threads << Thread.start { `rackup -p 4567` }
  threads << Thread.start { `compass watch --sass-dir sass --css-dir public/css` }

  at_exit { threads.map { |thread| thread.kill } }

  sleep
end
