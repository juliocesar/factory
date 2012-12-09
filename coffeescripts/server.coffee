http       = require 'http'
engine     = require 'engine.io'
brow       = require 'browserver'
router     = require 'browserver-router'
nodeStatic = require 'node-static'

# Use node-static for serving files from ./public
fileServer = new nodeStatic.Server('./public')

# Create a WebSocket, http, and browServer instances
httpServer = http.createServer()
wsServer   = engine.attach httpServer

browServer = new brow.Server
browServer.listen httpServer, hostname: '*.localhost'
browServer.listen wsServer


httpServer.on 'request', router

  # Serve all assets with node-static
  '/favicon.ico':
    GET: (req, res) -> fileServer.serve req, res
  '/stylesheets/:file':
    GET: (req, res) -> fileServer.serve req, res
  '/javascripts/:file':
    GET: (req, res) -> fileServer.serve req, res
  '/font/:file':
    GET: (req, res) -> fileServer.serve req, res

  # Serve index.html and let Backbone.Router handle what  to display
  # on the client
  '/':
    GET: (req, res) -> fileServer.serveFile '/index.html', 200, {}, req, res
  '/:id':
    GET: (req, res) -> fileServer.serveFile '/index.html', 200, {}, req, res
  '/:id/:slide':
    GET: (req, res) -> fileServer.serveFile '/index.html', 200, {}, req, res

# Listen for connections
httpServer.listen 8000, ->
  {port, address} = do @address

  console.log "Factory server: http://#{address}:#{port}"

