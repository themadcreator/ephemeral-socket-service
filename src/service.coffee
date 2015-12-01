EphemeralSocket  = require './socket'
EphemeralStorage = require './storage'
SocketIds        = require './ids'
EventEmitter     = require 'events'

class EphemeralSocketService extends EventEmitter
  constructor : (options = {}) ->
    @socketStorage = new EphemeralStorage(options.ttl)
    @socketIds     = options.ids ? SocketIds

  ###
  Creates a new socket. We do not resume the transmitter's HTTP POST stream
  until the socket is requested by a receiver's HTTP GET.
  ###
  openSocket : (req, res, next) =>
    # Create new socket and store in socket table
    socket = new EphemeralSocket(req, res)
    socketId = @socketIds.generate()
    @socketStorage.push(socketId, socket)

    # Fire event
    @emit 'socket:created', socket, socketId
    return

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

module.exports = EphemeralSocketService
