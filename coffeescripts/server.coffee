http       = require 'http'
engine     = require 'engine.io'
brow       = require 'browserver'
nodeStatic = require 'node-static'

fileServer = new nodeStatic.Server('./public')

requestHandler = (req, resp) ->
  req.addListener 'end', ->
    fileServer.serve req, resp

httpServer = http.createServer requestHandler
wsServer   = engine.attach httpServer
browServer = new brow.Server

browServer.listen wsServer
browServer.listen httpServer

httpServer.listen 8000, ->
  {port, address} = do @address

  console.log "Factory server: http://#{address}:#{port}"

