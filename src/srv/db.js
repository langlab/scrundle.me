// Generated by CoffeeScript 1.3.3
var ObjectId, Schema, Script, ScriptSchema, User, UserSchema, mongoose, mongooseAuth;

mongoose = require('mongoose');

mongoose.connect('mongodb://localhost/scrundle');

Schema = mongoose.Schema;

ObjectId = Schema.ObjectId;

mongooseAuth = require('mongoose-auth');

UserSchema = new Schema({});

UserSchema.plugin(mongooseAuth, {
  everymodule: {
    everyauth: {
      User: function() {
        return User;
      }
    }
  },
  twitter: {
    everyauth: {
      myHostname: 'http://dev.scrundle.me',
      consumerKey: 'aoMCcJR62q9GYRAP9OOUQ',
      consumerSecret: 'oT133ULqySY3H55xWQHa7nA5iV7a1UzAFJMnubyw',
      callbackPath: '/twitter/callback',
      redirectPath: '/',
      moduleTimeout: 15000
    }
  },
  github: {
    everyauth: {
      myHostname: 'http://dev.scrundle.me',
      appId: 'd1db5a91b494ce515816',
      callbackPath: '/github/callback',
      appSecret: 'ccf4ed6bb7fdaace5dec7316bfc36dc8f2e7116b',
      redirectPath: '/',
      moduleTimeout: 15000
    }
  }
});

ScriptSchema = new Schema({
  _author: {
    type: ObjectId,
    ref: 'User',
    "default": "4fe39dd2444ddc0c03000001"
  },
  code: String,
  title: String,
  description: String,
  versions: {},
  uses: Number
});

ScriptSchema.statics = {
  getForUser: function(authorId, cb) {
    var _this = this;
    return this.find({
      _author: authorId
    }).sort('uses', -1).exec(function(err, scripts) {
      return cb(err, scripts);
    });
  },
  search: function(term, cb) {
    var _this = this;
    return this.find({
      $or: [
        {
          title: {
            $regex: term,
            $options: 'i'
          }
        }, {
          description: {
            $regex: term,
            $options: 'i'
          }
        }, {
          code: {
            $regex: term,
            $options: 'i'
          }
        }
      ]
    }).sort('uses', -1).exec(function(err, scripts) {
      return cb(err, scripts);
    });
  },
  list: function(list, cb) {
    var _this = this;
    return this.find().where('code')["in"](list).exec(function(err, scripts) {
      return cb(err, scripts);
    });
  }
};

Script = mongoose.model('script', ScriptSchema);

User = mongoose.model('user', UserSchema);

module.exports = {
  mongoose: mongoose,
  Script: Script,
  User: User
};
