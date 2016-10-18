(function() {
  "use strict";
  var crypto, http, openclient, redis, register, storage, utils, _organize_catalog,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  openclient = require("openclient");

  utils = require('../../utils/utils').utils;

  crypto = require('crypto');

  storage = require('ecutils').storage;

  redis = require('ecutils').redis;

  register = require('../../node_modules/openclient/workflow/versions');

  http = require('http');

  _organize_catalog = function(session, serviceCatalog) {

    /*
     *  Save organized endpoints into req.session
     *  req.session.regions:
     *    type: list
     *    example:
     *      [{
     *        name: 'region1'
     *        endpoints: []
     *      }]
     *
     *  Set the frist to active
     */
    var endpoint, key, preRegionName, region, regionObj, regions, regionsMap, service, value, _i, _j, _k, _len, _len1, _len2, _ref, _ref1;
    preRegionName = null;
    if (session.regions) {
      _ref = session.regions;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        region = _ref[_i];
        if (region.active) {
          preRegionName = region.name;
          break;
        }
      }
    }
    regionsMap = {};
    if (serviceCatalog) {
      for (_j = 0, _len1 = serviceCatalog.length; _j < _len1; _j++) {
        service = serviceCatalog[_j];
        _ref1 = service.endpoints;
        for (_k = 0, _len2 = _ref1.length; _k < _len2; _k++) {
          endpoint = _ref1[_k];
          endpoint.service_name = service.name;
          endpoint.type = service.type;
          if (regionsMap[endpoint.region]) {
            regionsMap[endpoint.region].push(endpoint);
          } else {
            regionsMap[endpoint.region] = [endpoint];
          }
        }
      }
    }
    regions = [];
    for (key in regionsMap) {
      value = regionsMap[key];
      regionObj = {
        name: key,
        endpoints: value
      };
      if (preRegionName) {
        if (key === preRegionName) {
          regionObj.active = true;
          session.current_region = regionObj.name;
        }
      }
      regions.push(regionObj);
    }
    if (regions.length > 0 && !preRegionName) {
      regions[0].active = true;
      session.current_region = regions[0].name;
    }
    return session.regions = regions;
  };


  /*
  Get user scoped token via keystone API.
  
  NOTE(zhengyue): The project used is the first at project
                  list from API call.
  
  Example:
      POST /login
  
  Body:
     {username: 'Bob', password: 'Bob-secret'}
  
  @param require the staandard http request
  @param response the standard http response
   */

  exports.login = function(req, res) {
    var assgineMemberRole, keystone, keystoneClient, requireNormal;
    keystone = openclient.getAPI("openstack", "identity", cloudAPIs.version.identity);
    keystoneClient = new keystone({
      url: cloudAPIs.keystone.authUrl,
      debug: true
    });
    assgineMemberRole = function(token) {
      var baseUrl, catalog, client;
      catalog = token.service_catalog;
      baseUrl = utils.getURLByCatalog(catalog, 'identity', true);
      client = new keystone({
        url: baseUrl,
        scoped_token: token.scoped_token,
        tenant: token.tenant.id,
        debug: true
      });
      return client.roles.all({
        success: function(roles) {
          var defaultMemberRoleName, memberRoleId, params, role, _i, _len;
          memberRoleId = null;
          defaultMemberRoleName = "Member";
          if (cloudAPIs.member_role) {
            defaultMemberRoleName = cloudAPIs.member_role;
          }
          for (_i = 0, _len = roles.length; _i < _len; _i++) {
            role = roles[_i];
            if (role.name === defaultMemberRoleName) {
              memberRoleId = role.id;
              break;
            }
          }
          if (memberRoleId) {
            params = {
              headers: {
                "Content-length": 0
              },
              endpoint_type: 'identity',
              project: token.tenant.id,
              user: token.user.id,
              role: memberRoleId,
              data: {}
            };
            return client.user_roles.create(params, function(err, data) {
              if (err) {
                return logger.error("Failed to assgine member role");
              }
            });
          }
        }
      });
    };
    requireNormal = req.body.normal;
    keystoneClient.authenticate({
      username: req.body.username,
      password: req.body.password
    }, function(err, unscopedToken) {
      var baseUrl, query, registerClient, registerValidate;
      if (err) {
        if (err.status === 401) {
          baseUrl = global.cloudAPIs.register.baseUrl;
          query = {
            name: req.body.username
          };
          registerValidate = register[register.current];
          registerClient = new registerValidate({
            url: baseUrl,
            debug: true
          });
          registerClient['register'].validate(query, function(err, data) {
            var debugInfo, openstackServices, redisClient, storageClient;
            if (err) {
              return res.send(err, err.status || 500);
            } else {
              if (data.has === 1) {
                redisClient = redis.connect({
                  'redis_host': redisConf.host
                });
                debugInfo = true;
                storageClient = new storage.Storage({
                  redis_client: redisClient,
                  debug: debugInfo
                });
                openstackServices = ['nova', 'heat', 'gossip', 'cinder', 'neutron', 'econe', 'glance', 'highland', 'ceilometer'];
                return storageClient.getObjects({
                  resource_type: 'users',
                  debug: debugInfo
                }, function(err, users) {
                  var user, _i, _len, _ref;
                  if (users) {
                    _ref = users.data;
                    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                      user = _ref[_i];
                      if (__indexOf.call(openstackServices, user) >= 0) {
                        continue;
                      } else {
                        if (user.username === req.body.username) {
                          if (user.enabled === 'false') {
                            res.send("User has been disabled.", 401);
                            return;
                          } else {
                            res.send("Username and password are not match!", 401);
                            return;
                          }
                          break;
                        }
                      }
                    }
                  } else {
                    return res.send(err, err.status || 500);
                  }
                });
              } else if (data.has === 0) {
                res.send("User is not exist.", 401);
              } else {
                res.send("User in the workflow.", 401);
              }
            }
          });
        } else {
          res.send(err, err.status || 500);
          return;
        }
      }
      if (unscopedToken) {
        keystoneClient.projects.all({
          username: req.body.username,
          password: req.body.password,
          token: unscopedToken.token.id,
          success: function(projects) {
            var isAdmin, permiPros, pro, project, projectEnabled, _i, _j, _len, _len1;
            project = void 0;
            if (requireNormal) {
              permiPros = [];
              projectEnabled = void 0;
              for (_i = 0, _len = projects.length; _i < _len; _i++) {
                pro = projects[_i];
                if (pro.name === global.adminProject || pro.enabled === false) {
                  continue;
                }
                permiPros.push(pro);
              }
              if (!permiPros.length) {
                res.send("No available projects.", 402);
                return;
              }
              project = permiPros[0];
            } else {
              isAdmin = false;
              for (_j = 0, _len1 = projects.length; _j < _len1; _j++) {
                pro = projects[_j];
                if (pro.name === global.adminProject) {
                  project = pro;
                  isAdmin = true;
                  break;
                }
              }
              if (!isAdmin) {
                res.send("Not admin user", 402);
                return;
              }
            }
            return keystoneClient.authenticate({
              username: req.body.username,
              password: req.body.password,
              project: project.name,
              success: function(token) {
                var catalog, client, defaultMemberRoleName, encryptedPassword, noMemberRole, password, role, roles, sha1Hash, _k, _len2;
                roles = token.user.roles;
                if (!roles || !roles.length) {
                  res.send("No available roles", 402);
                  return;
                }
                noMemberRole = true;
                defaultMemberRoleName = "Member";
                if (cloudAPIs.member_role) {
                  defaultMemberRoleName = cloudAPIs.member_role;
                }
                for (_k = 0, _len2 = roles.length; _k < _len2; _k++) {
                  role = roles[_k];
                  if (role.name === defaultMemberRoleName) {
                    noMemberRole = false;
                  }
                }
                if (noMemberRole) {
                  assgineMemberRole(token);
                }
                if (requireNormal) {
                  req.session.projects = permiPros;
                  req.session.token = token.scoped_token;
                  req.session.serviceCatalog = token.service_catalog;
                  _organize_catalog(req.session, req.session.serviceCatalog);
                  req.session.user = token.user;
                  req.session.tenant = token.tenant;
                  password = req.body.password;
                  sha1Hash = crypto.createHash('sha1');
                  encryptedPassword = sha1Hash.update(password).digest('hex');
                  req.session.password = encryptedPassword;
                  res.send({
                    success: 'success'
                  });
                  return;
                }
                catalog = token.service_catalog;
                baseUrl = utils.getURLByCatalog(catalog, 'identity', true);
                client = new keystone({
                  url: baseUrl,
                  scoped_token: token.scoped_token,
                  tenant: token.tenant.id,
                  debug: true
                });
                return client.roles.all({
                  success: function(roles) {
                    var roleDict, _l, _len3;
                    roleDict = {};
                    for (_l = 0, _len3 = roles.length; _l < _len3; _l++) {
                      role = roles[_l];
                      roleDict[role.name] = role.id;
                    }
                    req.session.roles = roleDict;
                    req.session.token = token.scoped_token;
                    req.session.serviceCatalog = token.service_catalog;
                    _organize_catalog(req.session, req.session.serviceCatalog);
                    req.session.user = token.user;
                    req.session.tenant = token.tenant;
                    req.session.adminBack = {
                      token: token.scoped_token,
                      tenant: token.tenant,
                      serviceCatalog: token.service_catalog,
                      regions: req.session.regions
                    };
                    password = req.body.password;
                    sha1Hash = crypto.createHash('sha1');
                    encryptedPassword = sha1Hash.update(password).digest('hex');
                    req.session.password = encryptedPassword;
                    req.session.save();
                    return res.send({
                      success: 'success'
                    });
                  },
                  error: function(err) {
                    return res.send("can not get roles: " + err, 500);
                  }
                });
              },
              error: function(err) {
                return res.send(err, err.status || 500);
              }
            });
          },
          error: function(err) {
            return res.send(err, err.status || 500);
          }
        });
      }
    });
  };


  /*
  Check user is login or not.
  
  @param require the staandard http request
  @param response the standard http response
   */

  exports.isLogin = function(req, res, next) {
    var currentTime, expiredAt;
    if (req.session.token) {
      expiredAt = Date.parse(req.session.token.expires);
      currentTime = new Date().getTime();
      if ((expiredAt - currentTime) > 0) {
        next();
      } else {
        res.send({
          "error": "need login"
        }, 401);
      }
    } else {
      res.send({
        "error": "need login"
      }, 401);
    }
  };


  /*
  User logout.
  
  @param require the staandard http request
  @param response the standard http response
   */

  exports.logout = function(req, res) {
    req.session.destroy();
    res.send({
      'logout': 'success'
    }, 200);
  };

  module.exports.organize_catalog = _organize_catalog;

}).call(this);

//# sourceMappingURL=login.js.map
