'use strict';

var http = require('http');

module.exports = function () {
  var baseUrl = global.cloudAPIs.register.baseUrl;
  var reqUrl = baseUrl + "/options"
  http.get(reqUrl, function (resp) {
    var size = 0;
    var chunks = [];
    resp.on('data', function (chunk) {
      size += chunk.length;
      chunks.push(chunk);
    });
    resp.on('end', function () {
      var _ref, _i, _len, i, data;
      var emailConf = {};
      data = Buffer.concat(chunks, size).toString();
      data = JSON.parse(data);
      if (data.options) {
        _ref = data.options.list;
        for(_i = 0, _len = _ref.length; _i < _len; _i++) {
          i = _ref[_i];
          switch (i.key) {
            case "smtp_server":
              emailConf.smtp_server = i.value;
              break;
            case "email_sender":
              emailConf.sender = i.value;
              break;
            case "email_sender_password":
              emailConf.password = i.value;
              break;
            case "email_sender_name":
              emailConf.sender_name = i.value;
              break;
            case "site_name":
              emailConf.site_display_name = i.value;
              break;
          }
        }
        global.emailConf = emailConf;
      } else {
        logger.error("Meet error when try to get %s", reqUrl);
        logger.info("Email configs is according to config.json.");
      }
    });
  }).on('error', function (err) {
      logger.error("Meet %s when try to get %s", err.code, reqUrl);
      logger.info("Email configs is according to config.json.");
  })
}
