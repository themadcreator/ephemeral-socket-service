Busboy       = require 'busboy'
EventEmitter = require 'events'

class EphemeralSocket extends EventEmitter
  @State :
    RESERVED  : 'reserved'
    OPEN      : 'open'
    REQUESTED : 'requested'
    CLOSED    : 'closed'

  @open : (req, res) ->
    return new EphemeralSocket(EphemeralSocket.State.OPEN).open(req, res)

  @reserve : () ->
    return new EphemeralSocket(EphemeralSocket.State.RESERVED)

  constructor : (@state) ->
    @state = EphemeralSocket.State.RESERVED

  open : (@req, @res) ->
    @state = EphemeralSocket.State.OPEN
    return @

  ###
  When this socket is requested, we start accepting data from transmitter's
  HTTP POST and pipe it directly to the receiver's HTTP GET.

  No data is stored to disk, however it does touch memory on its way through
  the server.
  ###
  pipe : (res) ->
    if @state isnt EphemeralSocket.State.OPEN or not @req?
      throw new Error('Invalid state transition')

    @state = EphemeralSocket.State.REQUESTED

    busboy = new Busboy({headers : @req.headers})
    stats  = {bytes : 0}

    busboy.on('file', (fieldname, fileStream) =>

      fileStream.on('data', (data) =>
        stats.bytes += data.length
        @emit('progress', stats)
      )

      fileStream.on('end', =>
        @emit('end', stats)
        @close()
      )

      # Pipe file stream to receiver's HTTP GET
      fileStream.pipe(res)
    )

    # Pipe transmitter's HTTP POST to busboy
    @req.pipe(busboy)

  timeout : ->
    if @state isnt EphemeralSocket.State.CLOSED
      @emit('timeout')
      @close()

  close : ->
    @state = EphemeralSocket.State.CLOSED
    delete @req
    delete @res
    @removeAllListeners()

module.exports = EphemeralSocket
