// Generated by CoffeeScript 1.3.3
var Bundler, Script, User, app, ck, db, express, io, mongoose, mongooseAuth, store, _;

express = require('express');

store = new express.session.MemoryStore();

ck = require('coffeekup');

_ = require('underscore');

db = require('./src/srv/db');

User = db.User;

Script = db.Script;

mongoose = db.mongoose;

Bundler = require('./src/srv/bundler');

mongooseAuth = require('mongoose-auth');

app = express.createServer();

io = require('socket.io').listen(app);

app.configure(function() {
  app.use(express.methodOverride());
  app.use(express["static"]("" + __dirname + "/pub"));
  app.use(express.bodyParser());
  app.use(express.cookieParser());
  app.use(express.session({
    secret: 'keyboardCat',
    key: 'express.sid',
    store: store
  }));
  app.use(mongooseAuth.middleware());
  app.set('views', "" + __dirname + "/src/views");
  app.set('view options', {
    layout: false
  });
  app.set('view engine', 'coffee');
  app.register('.coffee', require('coffeekup').adapters.express);
  return app.use(express.errorHandler());
});

app.get('/', function(req, res) {
  return res.render('index', {
    user: req.user,
    session: req.session
  });
});

app.get('/favicon.ico', function(req, res) {
  return res.sendfile("" + __dirname + "/pub/img/favicon.ico");
});

app.get('/ck.js', function(req, res) {
  return res.sendfile("" + __dirname + "/node_modules/coffeekup/lib/coffeekup.js");
});

app.get('/github/callback', function(req, res) {
  console.log(req.query);
  return res.redirect('/');
});

app.get('/twitter/callback', function(req, res) {
  console.log(req.query);
  return res.redirect('/');
});

app.get(/^\/js\/([^e]+)(\/(.+)\.js)?/, function(req, res) {
  var bd;
  console.log(req.params);
  bd = new Bundler();
  bd.getBundle(req.params[0].split('/'));
  return bd.on('bundle', function(bundle) {
    return res.send(bundle, {
      'Content-type': 'text/javascript'
    });
  });
});

io.sockets.on('connection', function(socket) {
  socket.on('script', function(data, cb) {
    var code, list, q,
      _this = this;
    console.log('read: ', JSON.stringify(data));
    switch (data.method) {
      case 'codeExists':
        if ((code = data.code)) {
          return Script.findOne({
            code: code
          }, function(err, script) {
            console.log('hi: ', script);
            return cb(script);
          });
        }
        break;
      case 'read':
        if ((code = data.options.code)) {
          return Script.findOne({
            code: code
          }, function(err, script) {
            return _this.emit('script', 'read', script);
          });
        } else if ((list = data.options.list)) {
          return Script.list(list, function(err, matchingScripts) {
            console.log('sending ', _.pluck(matchingScripts, 'code'));
            return _this.emit('script', 'read', matchingScripts);
          });
        } else if ((q = data.options.query)) {
          return Script.search(q, function(err, matchingScripts) {
            console.log('sending ', _.pluck(matchingScripts, 'code'));
            return _this.emit('script', 'read', matchingScripts);
          });
        } else {
          return Script.find(function(err, scripts) {
            return _this.emit('script', 'read', scripts);
          });
        }
    }
  });
  return socket.on('scrundle', function(codes) {
    var bd,
      _this = this;
    console.log('recv:', codes);
    bd = new Bundler();
    bd.getBundle(codes);
    bd.on('bundle', function(bundle) {
      return _this.emit('scrundle:source', bundle);
    });
    return bd.on('progress', function(count) {
      return _this.emit('scrundle:progress', count);
    });
  });
});

mongooseAuth.helpExpress(app);

app.listen(4444);
