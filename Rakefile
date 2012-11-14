task :run do
  threads = []
  threads << Thread.start { `rackup -p 4567` }
  threads << Thread.start { `compass watch sass/factory.scss --css-dir public/stylesheets` }
  threads << Thread.start { `coffee --watch -o public/javascripts --compile coffeescripts` }

  at_exit { threads.map { |thread| thread.kill } }

  sleep
end
