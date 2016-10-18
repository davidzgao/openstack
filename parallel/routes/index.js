(function() {
  'use strict';
  var openclient, organize_catalog, utils;

  openclient = require('openclient');

  utils = require('../utils/utils').utils;

  organize_catalog = require('./keystone/login').organize_catalog;

  exports.index = function(req, res) {
    return res.sendFile('index.html');
  };

  exports.endpoints = function(req, res) {
    var currentRegion, region, _i, _len, _ref, _results;
    currentRegion = req.session.current_region;
    if (req.session.regions) {
      _ref = req.session.regions;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        region = _ref[_i];
        if (region.name === currentRegion) {
          res.send(region.endpoints);
          break;
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    }
  };

  exports.auth = function(req, res) {
    var back, currentTime, expiredAt, messageAuth, region, regions, service, services, userData, _i, _j, _k, _len, _len1, _len2, _ref, _ref1;
    if (req.query.dash === "admin") {
      if (req.session.adminBack) {
        back = req.session.adminBack;
        req.session.token = back.token;
        req.session.tenant = back.tenant;
        req.session.serviceCatalog = back.serviceCatalog;
        organize_catalog(req.session, req.session.serviceCatalog);
        messageAuth = "" + back.token.id + "H" + back.tenant.id;
        req.session.save();
      }
    }
    if (req.session.token) {
      expiredAt = Date.parse(req.session.token.expires);
      currentTime = new Date().getTime();
      if (expiredAt > currentTime) {
        if (req.query.getService) {
          services = [];
          regions = req.session.regions;
          if (regions) {
            for (_i = 0, _len = regions.length; _i < _len; _i++) {
              region = regions[_i];
              if (region.active) {
                _ref = region.endpoints;
                for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
                  service = _ref[_j];
                  services.push(service.type);
                }
              }
            }
          } else {
            _ref1 = req.session.serviceCatalog;
            for (_k = 0, _len2 = _ref1.length; _k < _len2; _k++) {
              service = _ref1[_k];
              services.push(service.type);
            }
          }
          return res.send(services);
        } else {
          messageAuth = "" + req.session.token.id;
          messageAuth += "H" + req.session.tenant.id;
          userData = {
            auth: messageAuth,
            user: req.session.user,
            project: req.session.tenant
          };
          if (req.query.unicorn) {
            userData.projects = req.session.projects;
          }
          return res.send(userData);
        }
      } else {
        req.session.destroy();
        return res.send({
          "error": "need login"
        }, 401);
      }
    } else {
      req.session.destroy();
      return res.send({
        "error": "need login"
      }, 401);
    }
  };

  exports.service = function(req, res) {
    var endpoint, item, service, services, url, _i, _len, _ref;
    services = [];
    if (!req.session.serviceCatalog) {
      res.send("No service available.", 404);
      return;
    }
    _ref = req.session.serviceCatalog;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      service = _ref[_i];
      endpoint = service.endpoints[0];
      url = endpoint.publicURL;
      item = {
        name: service.name,
        type: service.type,
        host: url,
        region: endpoint.region
      };
      services.push(item);
    }
    return res.send(services);
  };

  exports.userProjects = function(req, res) {
    var currentTime, expiredAt, item, project, projects, _i, _len, _ref;
    projects = [];
    if (!req.session.token) {
      res.send("User was unauthorized.", 401);
      return;
    } else {
      expiredAt = Date.parse(req.session.token.expires);
      currentTime = new Date().getTime();
      if (expiredAt < currentTime) {
        res.send({
          "error": "need login"
        }, 401);
        return;
      }
    }
    if (!req.session.projects) {
      res.send("No projects available.", 404);
      return;
    }
    _ref = req.session.projects;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      project = _ref[_i];
      if (!project.enabled) {
        continue;
      }
      item = {
        name: project.name,
        id: project.id
      };
      projects.push(item);
    }
    return res.send(projects);
  };

  exports.switchProject = function(req, res) {
    var baseUrl, catalog, keystone, keystoneClient, projectId, session, tenant, token;
    projectId = req.params['project_id'];
    session = req.session;
    keystone = openclient.getAPI("openstack", "identity", cloudAPIs.version.identity);
    if (!session.adminBack) {
      tenant = session.tenant;
      token = session.token;
      catalog = session.serviceCatalog;
      baseUrl = utils.getURLByCatalog(catalog, 'identity', true);
      keystoneClient = new keystone({
        url: baseUrl,
        scoped_token: token,
        tenant: tenant.id,
        debug: true
      });
      keystoneClient.authenticate({
        token: session.token.id,
        project_id: projectId,
        success: function(token) {
          var auth;
          req.session.token = token.scoped_token;
          req.session.tenant = token.tenant;
          req.session.serviceCatalog = token.service_catalog;
          organize_catalog(req.session, req.session.serviceCatalog);
          req.session.save();
          auth = "" + req.session.token.id + "H" + req.session.tenant.id;
          return res.send({
            auth: auth,
            user: req.session.user,
            project: req.session.tenant
          });
        },
        error: function(err) {
          return res.send("authenticat error: " + err, 500);
        }
      });
      return;
    }
    tenant = session.adminBack.tenant;
    token = session.adminBack.token;
    catalog = session.adminBack.serviceCatalog;
    baseUrl = utils.getURLByCatalog(catalog, 'identity', true);
    keystoneClient = new keystone({
      url: baseUrl,
      scoped_token: token,
      tenant: tenant.id,
      debug: true
    });
    if (!session.roles) {
      res.send("can not get roles", 500);
    }
    return keystoneClient.user_roles.create({
      project: projectId,
      user: session.user.id,
      role: session.roles[global.memberRole],
      success: function() {
        return keystoneClient.authenticate({
          token: session.token.id,
          project_id: projectId,
          success: function(token) {
            if (!req.session.adminBack) {
              req.session.adminBack = {
                token: req.session.token,
                tenant: req.session.tenant,
                serviceCatalog: req.session.serviceCatalog,
                regions: req.session.regions
              };
            }
            req.session.token = token.scoped_token;
            req.session.tenant = token.tenant;
            req.session.serviceCatalog = token.service_catalog;
            organize_catalog(req.session, req.session.serviceCatalog);
            req.session.save();
            return res.send({
              auth: req.session.token.id,
              user: req.session.user,
              project: req.session.tenant
            });
          },
          error: function(err) {
            return res.send("authenticat error: " + err, 500);
          }
        });
      },
      error: function(err) {
        if (err.status === 409) {
          return keystoneClient.authenticate({
            token: session.token.id,
            project_id: projectId,
            success: function(token) {
              var auth;
              if (!req.session.adminBack) {
                req.session.adminBack = {
                  token: req.session.token,
                  tenant: req.session.tenant,
                  serviceCatalog: req.session.serviceCatalog,
                  regions: req.session.regions
                };
              }
              req.session.token = token.scoped_token;
              req.session.tenant = token.tenant;
              req.session.serviceCatalog = token.service_catalog;
              organize_catalog(req.session, req.session.serviceCatalog);
              req.session.save();
              auth = "" + req.session.token.id + "H" + req.session.tenant.id;
              return res.send({
                auth: auth,
                user: req.session.user,
                project: req.session.tenant
              });
            },
            error: function(err) {
              return res.send("authenticat error: " + err, 500);
            }
          });
        } else {
          return res.send("authenticat error: " + err, 500);
        }
      }
    });
  };

}).call(this);

//# sourceMappingURL=index.js.map
