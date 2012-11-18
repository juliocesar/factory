require 'rack'

module StaticApp ; extend self

  FileServer = Rack::File.new Dir.pwd + '/public'

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

    # If PATH_INFO is not a file name with an extension, it's probably
    # a path we got taken to by the JS app, so just serve index.html
    if File.extname(env['PATH_INFO']) == ''
      resp = FileServer.call(rewrite_to_index(env))
      return cache(resp) unless not_found?(resp)
    end

    # Serve not found
    not_found
  end

  def rewrite_to_index(env)
    env['PATH_INFO'] = '/index.html'
    env
  end

  def rewrite_path(env, newpath)
    env.merge('PATH_INFO' => env['PATH_INFO'] + newpath)
  end

  def cache(resp)
    return resp # disable caching
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
