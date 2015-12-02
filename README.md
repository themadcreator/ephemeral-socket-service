# Ephemeral Socket Service

This express middleware allows you to accept incoming HTTP POST requests that will be piped through to later HTTP GET requests.

# Why would I want to?

The server acts as a file sharing service but the data is never stored on the server. Instead, the incoming HTTP POST is accepted and then stalled until the HTTP GET request is made. In order to know what URL to use for the HTTP GET request, we write a partial response to the HTTP POST but do not close the stream.

# Usage

1. Create an express server.
1. Attach this middleware.
1. Respond to events on middleware to create your service.

Here is how it might look:

```coffeescript

# Create express server
express = require 'express'
app     = express()

# Initialize middleware
service = require('ephemeral-socket-service').attach(app)

# Respond to events
service.on 'socket:opened', (socket, socketId, query) ->
  socket.res.writeHead(200)
  socket.res.write("Ephemeral socket open with ID #{socketId}")

service.on 'socket:end', (socket, stats) ->
  socket.res?.write('\n\nUpload complete. Socket deleted.\n')
  socket.res?.end()

service.on 'socket:timeout', (socket) ->
  socket.res?.write('\n\nTimed out. No one requested your socket.\n')
  socket.res?.end()

service.on 'error:not-found', (req, res) ->
  res.status(404).send('Not found')

# Serve
app.set('port', 9000)
server = app.listen(app.get('port'), ->
  console.log('Listening on %s', server.address().port)
)

```

# Options

`EphemeralSocketService.attach()` takes an option hash as its second argument. The available options are:

| key | default | description |
| --- | ------- | ----------- |
| ttl | `600` | Time (in seconds) that a socket may stay open before it times out |
| maxUploadBytes | 2^30 (1 GB) | Set the max number of bytes allowed to be piped through a socket. HTTP POSTs will be rejected with a 413 status code if they exceed this limit |
| reservations | `false` | Adds `/reserve` middleware to allow users to create an ephemeral socket before creating an HTTP POST. This is useful when scripting this service within a web browser as most don't support streaming HTTP POST responses. |
| requiredReferer | `null` | RECOMMENDED if you are using reservations. If defined with a string like "http://localhost:9000", this will restrict reservations to that specific referer. |
| ids | `{...}` | An object for creating the socket IDs. See `ids.coffee` |
