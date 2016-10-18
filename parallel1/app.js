'use strict';

// default port for this app.js
var PORT = 4000;
var HOST = '0.0.0.0';
var VIEW_FILE = './etc/view.json';
var PROGRAME = 'parallel';

/**
 * Options Initialization
 */
var opt = require('node-getopt').create([
  ['h' , 'host=' + HOST     , 'Listening host, default is ' + HOST],
  ['p' , 'port=' + PORT     , 'Starting port, default is ' + PORT],
  ['f' , 'file=' + VIEW_FILE, 'view config file, default is ' + VIEW_FILE],
  ['h' , 'help'             , 'display this help'],
  ['v' , 'version'          , 'show version']
])
.bindHelp()
.parseSystem();

var packageJson = require('./package.json');

var port = PORT;
var host = HOST;
var view_file = VIEW_FILE;
var options = opt['options'];
var optionsKeys = Object.keys(options);

for(var i in optionsKeys) {
    switch(optionsKeys[i]) {
        case 'host':
            host = options['host'];
            break;
        case 'port':
            port = options['port'];
            break;
        case 'file':
            view_file = options['file'];
            break;
        case 'version':
            console.info(packageJson.version);
            process.exit(0);
            break;
        default:
            break;
    }
}

var express = require('express')
  , session = require('express-session')
  , bodyParser = require('body-parser')
  , nconf = require('nconf')
  , favicon = require('static-favicon')
  , fs = require('fs')
  , log = require('ecutils').log
  , path = require('path')
  , cors = require('./utils/cors')
  , log4js = require('log4js')
  , emailConf = require('./utils/get_email_config')
  , i18n = require('i18n');

// load configuration file
var configFile = '/etc/' + PROGRAME + '/config.json';
if(! fs.existsSync(configFile)) {
    configFile = './etc/config.json';
}
var conf = nconf.file({file: configFile});

i18n.configure({
  locales: ["en_US", "zh_CN"],
  defaultLocale: "zh_CN",
  directory: "./locale",
  updateFiles: false,
  indent: "\t",
  extension: ".json"
});
global.i18n = i18n;

var app = express();

module.exports = app;

// logger settings
var logOptions = {
    'logLevel': ('production' === app.get('env'))? 'INFO' : 'ALL',
    'logFile': 'logs/' + app.get('env') + '.log',
    'category': PROGRAME
};

var logger = log.initLogger(logOptions);
global.logger = logger;
app.use(log4js.connectLogger(logger));

// Add allow cors host
global.allowHosts = conf.get('crossSite')['allowHosts'];

// Set admin/member role name.
global.adminProject = conf.get("adminProject") || "admin";
global.memberRole = conf.get("memberRole") || "Member";

// Use global to save cloud configurations
global.cloudAPIs = conf.get('openstack');
global.redisConf = conf.get('redis');
global.emailConf = conf.get('email');
global.passwordResetConf = conf.get('passwordResetConf');
global.adminUserConf = conf.get('adminUser');
global.storageConf = conf.get('storageBackends');
global.waitVolumeCreatedMins = conf.get('waitVolumeCreatedMins');

// get email configs from options API
// The default value is set in config.json
// While options API meet error, the default value
// will be used.
emailConf();

// use redis as default session store
// NOTE(ZhengYue): Adapt to express 3.x version.
var RedisStore = require('connect-redis')(express);
var redisConf = conf.get('redis');

// load view configuration file
var view_conf = nconf.file({file: view_file});

logger.info('Use Redis as default session store, connecting %s:%s',
        redisConf.host, redisConf.port);
app.use(express.cookieParser());

app.use(session({
  store: new RedisStore({
    host: redisConf.host,
    port: redisConf.port,
    db: redisConf.db,
    pass: redisConf.pass
  }),
  name: view_conf.get('project') || PROGRAME,
  secret: '3a9d609e387d29bd81c7cb4c7231c2b5',
  resave: false,
  saveUninitialized: false
}));

app.set('port', port);

// view engine setup
var view_path = view_conf.get('view_path') || 'views';
if(view_path.substr(0, 1) != '/') {
    view_path = path.join(__dirname, view_path);
}
app.set('views', view_path);
app.set('view engine', 'ejs');

app.use(cors);
app.use(favicon(path.join(view_path, 'favicon.ico')));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded());
app.use(express.methodOverride());
app.use(express.static(view_path));

var router = require('./router');
router.setup(app);

/// catch 404 and forward to error handler
app.use(function(req, res, next) {
    res.status(404);
    next(req, res)
});

/// error handlers

// development error handler
// will print stacktrace
if (app.get('env') === 'development') {
    app.use(function(err, req, res) {
        res.status(err.status || 500);
        res.render('error', {
            message: err.message,
            error: err
        });
    });
}

// production error handler
// no stacktraces leaked to user
app.use(function(err, req, res) {
    res.status(err.status || 500);
    res.render('error', {
        message: err.message,
        error: {}
    });
});

var server = app.listen(app.get('port'), host, function() {
    logger.info('Express [%s] server listening on http://%s:%s',
        app.get('env'), host, server.address().port);
});
