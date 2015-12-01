require('coffee-script/register');
EphemeralSocketService = require('./src/service.coffee');

module.exports = {
  "create" : function(options){
    return new EphemeralSocketService(options);
  },
  "init" : function(expressApp, serviceOptions) {
    var service = new EphemeralSocketService(serviceOptions);
    // Normal cURL usage:
    expressApp.post('/', service.openSocket);
    expressApp.get('/:socketId(' + service.socketIds.pattern + ')', service.tapSocket);
    // Reserve-then-post usage for XHR
    expressApp.get('/reserve', service.reserveSocket);
    expressApp.post('/reserve/:socketId(' + service.socketIds.pattern + ')', service.openReservedSocket);
    expressApp.all(service.socketNotFound);
    return service;
  }
};
