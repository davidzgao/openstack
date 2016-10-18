(function() {
  'use strict';
  var RegisterController, controllerBase, crypto, emailSender, openclient, redis, storage, userController, util,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  openclient = require("openclient");

  controllerBase = require('../controller').ControllerBase;

  emailSender = require('../../utils/email').EmailSender;

  userController = require('../keystone/usersController');

  redis = require('ecutils').redis;

  storage = require('ecutils').storage;

  crypto = require('crypto');

  util = require('../../utils/utils').utils;


  /**
    * Register controller.
   */

  RegisterController = (function(_super) {
    __extends(RegisterController, _super);

    RegisterController.prototype.debug = true;

    function RegisterController() {
      var options;
      options = {
        service: 'workflow',
        profile: 'register'
      };
      RegisterController.__super__.constructor.call(this, options);
      this.redisClient = redis.connect({
        'redis_host': redisConf.host
      });
    }

    RegisterController.prototype.getClient = function(req, obj) {
      var baseUrl, version, workflow;
      baseUrl = global.cloudAPIs.register.baseUrl;
      obj.baseUrl = baseUrl;
      version = global.cloudAPIs.version[obj.service];
      workflow = openclient.getAPI("openstack", obj.service, version);
      obj.client = new workflow({
        url: baseUrl,
        debug: obj.debug
      });
      return obj.client;
    };

    RegisterController.prototype.config = function(app) {
      var checkExpire, obj, passwordReset, passwordRetrieve, register, validate;
      obj = this;
      register = this.register;
      validate = this.validate;
      checkExpire = this.checkExpire;
      passwordRetrieve = this.retrieve;
      passwordReset = this.passwordReset;
      app.get("/" + this.profile, function(req, res) {
        return validate(req, res, obj);
      });
      app.post("/" + this.profile, function(req, res) {
        return register(req, res, obj);
      });
      app.post("/password/reset", function(req, res) {
        return passwordReset(req, res, obj);
      });
      app.post("/password/reset/check", function(req, res) {
        return checkExpire(req, res, obj);
      });
      app.post("/password/retrieve", function(req, res) {
        return passwordRetrieve(req, res, obj);
      });
      this.debug = 'production' !== app.get('env');
      this.storage = new storage.Storage({
        redis_client: this.redisClient,
        debug: this.debug
      });
    };

    RegisterController.prototype.validate = function(req, res, obj) {
      var client;
      client = obj.getClient(req, obj);
      return client['register'].validate(req.query, function(err, data) {
        if (err) {
          return res.send(err, err.status);
        } else {
          return res.send(data);
        }
      });
    };

    RegisterController.prototype.register = function(req, res, obj) {
      var client, params;
      params = {
        data: req.body
      };
      client = obj.getClient(req, obj);
      return client['register'].register(params, function(err, data) {
        if (err) {
          return res.send(err, err.status);
        } else {
          return res.send(data);
        }
      });
    };

    RegisterController.checkEmail = function(userList, email) {
      var adminUser, has, isAdmin, matchedUser, user, _i, _len;
      has = false;
      matchedUser = void 0;
      adminUser = global.adminUserConf.name;
      isAdmin = false;
      for (_i = 0, _len = userList.length; _i < _len; _i++) {
        user = userList[_i];
        if (user.name === adminUser) {
          isAdmin = true;
          break;
        }
        if (email === user.email) {
          has = true;
          matchedUser = user;
          break;
        }
      }
      return {
        has: has,
        matchedUser: matchedUser,
        isAdmin: isAdmin
      };
    };

    RegisterController.createURLHash = function(userId, expireAt) {
      var combinationHash, combinationStr, currentDate, md5Encoder, urlExpireHours, urlParams, urlSecureKey;
      Date.prototype.addHours = function(hours) {
        this.setHours(this.getHours() + hours);
        return this;
      };
      md5Encoder = crypto.createHash("md5");
      currentDate = new Date();
      urlExpireHours = global.passwordResetConf["URLExpireHours"];
      urlSecureKey = global.passwordResetConf["URLSecureKey"];
      if (!expireAt) {
        expireAt = currentDate.addHours(urlExpireHours).getTime();
      }
      combinationStr = userId + expireAt + urlSecureKey;
      combinationHash = util.urlHashEncode(md5Encoder, combinationStr);
      combinationHash = encodeURI(combinationHash);
      combinationHash = combinationHash.replace(/[\/]/g, "a");
      combinationHash = combinationHash.replace(/[\+]/g, "a");
      urlParams = {
        hash: combinationHash,
        expireAt: expireAt
      };
      return urlParams;
    };

    RegisterController.prototype.retrieve = function(req, res, obj) {
      var client;
      client = obj.getClient(req, obj);
      return obj.storage.getObjects({
        resource_type: 'users',
        query: {},
        debug: obj.debug
      }, function(err, users) {
        var emailOptions, expireAt, hash, hostURL, judge, link, mailContent, mailSubject, mailTips, markUpURL, matchedUser, urlParams, userId;
        judge = RegisterController.checkEmail(users.data, req.body.email);
        if (judge.has === false) {
          if (judge.isAdmin) {
            res.send({
              error: 'The password of admin could not to reset!'
            }, 400);
          }
          return res.send({
            error: 'email not exist'
          }, 400);
        } else {
          matchedUser = judge.matchedUser;
          userId = matchedUser.id;
          urlParams = RegisterController.createURLHash(userId);
          hash = urlParams.hash;
          expireAt = urlParams.expireAt;
          hostURL = req.headers.referer + "#/reset/";
          markUpURL = "" + hostURL + userId + "/" + expireAt + "/" + hash;
          mailSubject = i18n.__("Reset password");
          mailContent = i18n.__("Please click link to reset password: ");
          mailTips = i18n.__("This is a auto-send mail, please don't reply.");
          link = i18n.__("Reset password");
          emailOptions = {
            to: matchedUser.email,
            subject: mailSubject,
            text: '',
            html: "<p>" + mailContent + "<a href='" + markUpURL + "'>" + link + "</a></p><p>" + mailTips + "</p>"
          };
          return (new emailSender(emailOptions)).sendMail(function(err, response) {
            return res.send({}, 202);
          });
        }
      });
    };

    RegisterController.prototype.passwordReset = function(req, res, obj) {
      var adminUser, currentDate, expirAt, hashFailed, hashFromURL, keystone, keystoneClient, password, tenant_name, timeExpired, urlParams, userId, username;
      timeExpired = true;
      hashFailed = true;
      currentDate = (new Date()).getTime();
      expirAt = req.body.params.expirAt;
      if (currentDate < expirAt) {
        timeExpired = false;
      }
      userId = req.body.params.userId;
      urlParams = RegisterController.createURLHash(userId, expirAt);
      hashFromURL = req.body.params.hash;
      if (urlParams.hash === hashFromURL) {
        hashFailed = false;
      } else {
        hashFailed = true;
      }
      if (timeExpired || hashFailed) {
        res.send({
          error: "Url check failed!"
        }, 401);
        return;
      }
      adminUser = global.adminUserConf;
      username = adminUser.username;
      password = adminUser.password;
      tenant_name = adminUser.tenant;
      keystone = openclient.getAPI("openstack", "identity", cloudAPIs.version.identity);
      keystoneClient = new keystone({
        url: cloudAPIs.keystone.authUrl,
        debug: obj.debug
      });
      return keystoneClient.authenticate({
        username: username,
        password: password,
        project: tenant_name
      }, function(err, scopedToken) {
        var callback, options, userCtrl;
        userCtrl = new userController();
        callback = function(res, err, data) {
          if (err) {
            logger.error("Failed to reset password!");
            res.send(err, 400);
          } else {
            res.send({}, 202);
          }
        };
        options = {
          req: req,
          obj: userCtrl,
          token: scopedToken.token,
          tenant_id: scopedToken.token.tenant.id,
          callback: callback,
          res: res
        };
        return userCtrl.update_password(options);
      });
    };

    RegisterController.prototype.checkExpire = function(req, res, obj) {
      var currentDate, expirAt, hashFailed, hashFromURL, timeExpired, urlParams, userId;
      timeExpired = true;
      hashFailed = true;
      currentDate = (new Date()).getTime();
      expirAt = req.body.expirAt;
      if (currentDate < expirAt) {
        timeExpired = false;
      }
      userId = req.body.userId;
      urlParams = RegisterController.createURLHash(userId, expirAt);
      hashFromURL = req.body.hash;
      if (urlParams.hash === hashFromURL) {
        hashFailed = false;
      } else {
        hashFailed = true;
      }
      if (timeExpired === false && hashFailed === false) {
        return res.send({
          success: 'ok'
        }, 200);
      } else if (timeExpired === true) {
        return res.send({
          error: 'time expired'
        }, 400);
      } else if (hashFailed === true) {
        return res.send({
          error: 'URL error'
        }, 401);
      }
    };

    return RegisterController;

  })(controllerBase);

  module.exports = RegisterController;

}).call(this);

//# sourceMappingURL=registerController.js.map
