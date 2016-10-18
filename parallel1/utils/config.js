'use strict';

var _ = require('lodash'),
    glob = require('glob');

module.exports.getGlobbedFiles = function(globPatterns, removeRoot) {
  var _this = this;
  var output = [];

  glob(globPatterns, {
  sync:true
  }, function(err, files){
  if (removeRoot) {
    files = files.map(function(file) {
      return file.replace(removeRoot, '');
    });
  }

  output = files;
  })
  return output;
}
