// Generated by CoffeeScript 1.3.3
var Bundler, app, baseDir, ck, db, express, mongoose, mongooseAuth, store, _;

express = require('express');

store = new express.session.MemoryStore();

ck = require('coffeekup');

_ = require('underscore');

db = require('./db');

mongoose = db.mongoose;

Bundler = require('./bundler');

baseDir = __dirname.replace('/src/srv', '');

mongooseAuth = require('mongoose-auth');

app = express.createServer();

app.configure(function() {
  app.use(express.methodOverride());
  app.use(express.cookieParser());
  app.use(express.session({
    secret: 'keyboardCat',
    key: 'express.sid',
    store: store
  }));
  app.use(express.bodyParser());
  app.use(mongooseAuth.middleware());
  app.use(express["static"]("" + baseDir + "/pub"));
  app.set('views', "" + baseDir + "/src/views");
  app.set('view options', {
    layout: false
  });
  app.set('view engine', 'coffee');
  app.register('.coffee', require('coffeekup').adapters.express);
  return app.use(express.errorHandler());
});

mongooseAuth.helpExpress(app);

app.store = store;

app.get('/', function(req, res) {
  console.log('req.session: ', req.session.id);
  req.session.user = req.user;
  return res.render('index', {
    user: req.user,
    session: req.session
  });
});

app.get('/favicon.ico', function(req, res) {
  return res.sendfile("" + baseDir + "/pub/img/favicon.ico");
});

app.get('/ck.js', function(req, res) {
  return res.sendfile("" + baseDir + "/node_modules/coffeekup/lib/coffeekup.js");
});

app.get('/github/callback', function(req, res) {
  return res.redirect('/');
});

app.get('/twitter/callback', function(req, res) {
  return res.redirect('/');
});

app.get(/^\/js\/([^e]+)(\/(.+)\.js)?/, function(req, res) {
  var bd;
  bd = new Bundler();
  bd.getBundle(req.params[0].split('/'));
  return bd.on('bundle', function(bundle) {
    return res.send(bundle, {
      'Content-type': 'text/javascript'
    });
  });
});

app.get('/s', function(req, res) {
  return store.get(req.session.id, function(e, s) {
    return res.json({
      id: req.session.id,
      ck: req.cookies,
      e: e,
      s: s
    });
  });
});

app.listen(4401);

module.exports = app;
