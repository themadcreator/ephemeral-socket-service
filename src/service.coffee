EphemeralSocket  = require './socket'
EphemeralStorage = require './storage'
SocketIds        = require './ids'
EventEmitter     = require 'events'
url              = require 'url'

class EphemeralSocketService extends EventEmitter
  constructor : (options = {}) ->
    @socketStorage = new EphemeralStorage(options.ttl)
    @socketIds     = options.ids ? SocketIds

  ###
  Creates a new socket. We do not resume the transmitter's HTTP POST stream
  until the socket is requested by a receiver's HTTP GET.
  ###
  openSocket : (req, res, next) =>
    # Create new socket and store it
    socket = EphemeralSocket.open(req, res)
    socketId = @_storeSocket(socket)

    # Fire event
    {query} = url.parse(req.url, true)
    @emit 'socket:opened', socket, socketId, query
    return

  ###
  Creates a new disconnected socket.
  ###
  reserveSocket : (req, res, next) =>
    # Create new socket and store it
    socket   = EphemeralSocket.reserve()
    socketId = @_storeSocket(socket)

    # Fire event
    @emit 'socket:reserved', req, res, socketId

  ###
  Connected to a reserved socket
  ###
  openReservedSocket : (req, res, next) =>
    {socketId} = req.params
    socket = @socketStorage.get(socketId)
    return next() unless socket?
    socket.open(req, res)

    # Fire event
    {query} = url.parse(req.url, true)
    @emit 'socket:opened', socket, socketId, query

  ###
  When this socket is requested, we pipe data from the transmitter's HTTP POST
  to the receiver's HTTP GET.
  ###
  tapSocket : (req, res, next) =>
    socket = @socketStorage.extract(req.params.socketId)
    return next() unless socket?

    # Re-fire socket events
    socket.on 'progress', (stats) => @emit 'socket:progress', socket, stats
    socket.on 'end', (stats) => @emit 'socket:end', socket, stats
    socket.on 'timeout', => @emit 'socket:timeout', socket
    socket.pipe(res)

    # Fire event
    @emit 'socket:connected', socket
    return

  socketNotFound : (req, res) ->
    @emit 'socket:not-found', req, res

  _storeSocket : (socket) ->
    while true
      socketId = @socketIds.generate()
      continue if @socketStorage.contains(socketId)
      @socketStorage.push(socketId, socket)
      return socketId


module.exports = EphemeralSocketService
