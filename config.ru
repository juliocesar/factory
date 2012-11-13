# A config.ru useful for serving static sites from the "Bamboo" heroku stack.
#
# Interface:
#
#   Url Path | Action
#   -------- | -------------------------------------------------------------
#   /        | contents of: index.html OR
#            | contents of: 404.html OR
#            | default 404 message
#            |
#   /foo     | contents of: foo.html OR
#            | contents of: 404.html OR
#            | default 404 message
#            |
#   /foo/    | contents of: foo/index.html OR
#            | redirect to: /foo
#            |
#   /$X      | contents of: $X OR
#            | contents of: $X.html OR
#            | contents of: 404.html OR
#            | default 404 message
#
# All responses have a 15min cache time set. This means the site will _not_
# update "instantly" for viewers with a stale cache in their browser. Even
# though heroku flushes the varnish cache after each deploy. Coment out
# first line of `cache` function to turn this off.
#
# Note all files in the same dir as `config.ru` (including `config.ru` itself)
# can be served. Nothing is blocked. If a file shouldn't be public then it
# shouldn't be in this dir.
#
# To test this config locally run `rackup --port 8080`

require 'rack'

module StaticApp ; extend self

  FileServer = Rack::File.new Dir.pwd

  def call(env)
    # Serve the file if it exists
    resp = FileServer.call(env)
    return cache(resp) unless not_found?(resp)

    # If path ends with '/' then append 'index.html' and serve that file if it
    # exists otherwise strip the trailing slash and redirect
    if env['PATH_INFO'][-1] == ?/
      resp = FileServer.call(rewrite_path(env, 'index.html'))
      resp = not_found?(resp) ? redirect(path[0...-1]) : cache(resp)
      return resp
    end

    # Append '.html' and serve that file if it exists
    resp = FileServer.call(rewrite_path(env, '.html'))
    return cache(resp) unless not_found?(resp)

    # Serve not found
    not_found
  end

  def rewrite_path(env, newpath)
    env.merge('PATH_INFO' => env['PATH_INFO'] + newpath)
  end

  def cache(resp)
    resp[1]['Cache-Control'] = "public, max-age=#{15 * 60}" # 15min
    resp
  end

  def redirect(path)
    [ 301, { 'Content-Type' => 'text/plain', 'Location' => path }, ["redirecting to #{path}"] ]
  end

  def not_found
    not_found_file = Dir.pwd + '/404.html'
    body = File.exists?(not_found_file) ? File.open(not_found_file) : ['Not Found']
    [ 404, { 'Content-Type' => 'text/plain' }, body ]
  end

  def not_found?(resp)
    resp[0] == 404
  end

end

run StaticApp
