require('coffee-script/register');
EphemeralSocketService = require('./src/service.coffee');

module.exports = {
  "create" : function(options){
    return new EphemeralSocketService(options);
  },
  "init" : function(expressApp, serviceOptions) {
    var service = new EphemeralSocketService(serviceOptions);
    expressApp.post('/', service.openSocket);
    expressApp.get('/:socketId(' + service.socketIds.pattern + ')', service.tapSocket);
    expressApp.all(service.socketNotFound);
    return service;
  }
};
