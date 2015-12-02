require('coffee-script/register');
EphemeralSocketService = require('./src/service.coffee');

module.exports = {
  "create" : function(options){
    return new EphemeralSocketService(options);
  },
  "init" : function(expressApp, serviceOptions) {
    var service = new EphemeralSocketService(serviceOptions);

    // Normal cURL usage
    expressApp.post('/', service.openSocket);
    expressApp.get('/:socketId(' + service.socketIds.pattern + ')', service.tapSocket);

    // Reserve-then-post usage for XHR
    if (serviceOptions.reservationReferer){
      expressApp.get('/reserve', function(req, res, next) {
        if (req.headers.referer != serviceOptions.reservationReferer){
          service.errorInvalidReferrer(req, res);
        } else {
          next();
        }
      });
    }
    expressApp.get('/reserve', service.reserveSocket);
    expressApp.post('/reserve/:socketId(' + service.socketIds.pattern + ')', service.openReservedSocket);

    // Catch all for 404
    expressApp.all(service.errorSocketNotFound);
    return service;
  }
};
