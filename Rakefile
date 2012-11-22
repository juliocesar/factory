# Runs the development suite. Sadly, I can't seem to grab stderr
# from each thread and output to the parent's stderr
task :run do
  threads = []
  threads << Thread.start { `rackup -p 4567` }
  threads << Thread.start { `compass watch sass/factory.scss --css-dir public/stylesheets` }
  threads << Thread.start { `coffee --watch -o public/javascripts --compile coffeescripts` }

  at_exit { threads.map { |thread| thread.kill } }

  sleep
end

# Syntax check SASS and CoffeeScripts
task :check do
  `sass --compass -c sass/factory.scss`
  `coffee -o public/javascripts -c coffeescripts/factory.coffee`
end
