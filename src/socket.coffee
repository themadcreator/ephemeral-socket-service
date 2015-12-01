Busboy       = require 'busboy'
EventEmitter = require 'events'

class EphemeralSocket extends EventEmitter
  constructor : (@req, @res) ->

  ###
  When this socket is requested, we start accepting data from transmitter's
  HTTP POST and pipe it directly to the receiver's HTTP GET.

  No data is stored to disk, however it does touch memory on its way through
  the server.
  ###
  pipe : (res) ->
    @requested = true

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
    if not @requested
      @emit('timeout')
      @close()

  close : ->
    delete @req
    delete @res
    delete @id
    @removeAllListeners()

module.exports = EphemeralSocket
