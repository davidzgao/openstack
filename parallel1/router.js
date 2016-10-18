'use strict';
var utils = require('./utils/config'),
    path = require('path');
/**
 * Routes all API requests to particular functions.
 */

var index = require('./routes')
  , login = require('./routes/keystone/login');

module.exports.setup = function(app) {
    app.get('/', index.index);
    app.get('/auth', index.auth);
    app.get('/endpoints', index.endpoints);
    app.post('/login', login.login);
    app.get('/switch/:project_id', index.switchProject);
    app.get('/services', index.service);
    app.get('/userProjects', index.userProjects);

    // Globbing controller files
    // by getGlobbedFiles which in./utils/config.js
    // and instantiate the controller object
    var files = utils.getGlobbedFiles('./routes/*/*.js');
    files.forEach(function(modelPath) {
      // TODO(LiuHaoBo): Optimize the file filter.
      if (modelPath != './routes/controller.js' &&
          modelPath != './routes/index.js' &&
          modelPath != './routes/keystone/login.js') {
        (new (require(path.resolve(modelPath)))()).config(app);
      }
    });

    app.get('/logout', login.logout);
};
