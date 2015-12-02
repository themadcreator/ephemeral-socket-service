EphemeralSocket  = require './socket'
EphemeralStorage = require './storage'
SocketIds        = require './ids'
EventEmitter     = require 'events'
url              = require 'url'
_                = require 'lodash'


class EphemeralSocketService extends EventEmitter
  @DEFAULTS : {
    ttl             : 600     # 10 minutes
    maxUploadBytes  : 1 << 30 # 1 GB
    reservations    : false
    requiredReferer : null
    ids             : SocketIds
  }

  constructor : (@options = {}) ->
    _.defaults(@options, EphemeralSocketService.DEFAULTS)

    @socketStorage = new EphemeralStorage(@options.ttl)
    @socketIds     = @options.ids

  ###
  Creates a new socket. We do not resume the transmitter's HTTP POST stream
  until the socket is requested by a receiver's HTTP GET.
  ###
  openSocket : (req, res, next) =>
    # Create new socket and store it
    socket = EphemeralSocket.open(req, res)
    socketId = @_initializeSocket(socket)

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
    socketId = @_initializeSocket(socket)

    # Fire event
    @emit 'socket:reserved', req, res, socketId

  ###
  Connected to a reserved socket
  ###
  openReservedSocket : (req, res, next) =>
    # Open the reserved socket
    {socketId} = req.params
    socket = @socketStorage.get(socketId)
    return next() unless socket?
    return next() if socket.state isnt EphemeralSocket.State.RESERVED
    socket.open(req, res)

    # Fire event
    {query} = url.parse(req.url, true)
    @emit 'socket:opened', socket, socketId, query

  ###
  When this socket is requested, we pipe data from the transmitter's HTTP POST
  to the receiver's HTTP GET.
  ###
  tapSocket : (req, res, next) =>
    # Start piping socket through
    socket = @socketStorage.extract(req.params.socketId)
    return next() unless socket?
    socket.pipe(res)

    # Fire event
    @emit 'socket:connected', socket
    return

  maxUploadMiddleware : (req, res, next) =>
    if @options.maxUploadBytes > 0 and parseInt(req.headers['content-length']) > @options.maxUploadBytes
      @emit 'error:max-upload', req, res
    else
      next()
    return

  refererMiddleware : (req, res, next) =>
    if @options.requiredReferer? and req.headers.referer isnt @options.requiredReferer
      @emit 'error:referer', req, res
    else
      next()
    return

  notFoundMiddleware : (req, res) =>
    @emit "error:not-found", req, res
    return

  _initializeSocket : (socket) ->
    # Create new socketID and store the socket
    socketId = @socketIds.generate()
    while @socketStorage.contains(socketId)
      socketId = @socketIds.generate()
    @socketStorage.push(socketId, socket)

    # Connect socket events. These are later removed by socket.close()
    socket.on 'progress', (stats) => @emit 'socket:progress', socket, stats
    socket.on 'end', (stats) => @emit 'socket:end', socket, stats
    socket.on 'timeout', => @emit 'socket:timeout', socket
    socket.on 'error', (message) => @emit 'error:socket', socket, message

    return socketId


module.exports = EphemeralSocketService
