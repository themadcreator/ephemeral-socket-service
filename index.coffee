EphemeralSocketService = require './src/service.coffee'

module.exports = {
  create : (options) ->
    return new EphemeralSocketService(options)

  attach : (expressApp, options) ->
    service = new EphemeralSocketService(options)

    expressApp.post('/', service.maxUploadMiddleware)
    expressApp.post('/', service.openSocket)
    expressApp.get("/:socketId(#{service.socketIds.pattern})", service.tapSocket)

    if service.options.reservations
      expressApp.get('/reserve', service.refererMiddleware)
      expressApp.get('/reserve', service.reserveSocket)
      expressApp.post("/reserve/:socketId(#{service.socketIds.pattern})", service.maxUploadMiddleware)
      expressApp.post("/reserve/:socketId(#{service.socketIds.pattern})", service.openReservedSocket)

    expressApp.all(service.notFoundMiddleware)
    return service
}
