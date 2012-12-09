# Development time tasks
# ======================

# Runs the development suite. I can't seem to grab stderr from each thread and
# output to the parent's stderr...
task :suite do
  threads = []
  threads << Thread.start { `coffee coffeescripts/server.coffee` }
  threads << Thread.start { `compass watch sass/factory.scss --css-dir public/stylesheets` }
  threads << Thread.start { `coffee --watch -o public/javascripts --compile coffeescripts/factory.coffee` }

  at_exit { threads.map &:kill }

  sleep
end

# Syntax check SASS and CoffeeScripts
task :check do
  `sass --compass -c sass/factory.scss`
  `coffee -o public/javascripts -c coffeescripts/factory.coffee`
end
