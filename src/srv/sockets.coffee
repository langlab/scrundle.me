
db = require './db'
User = db.User
Script = db.Script
mongoose = db.mongoose
_ = require 'underscore'
io = require 'socket.io'
Bundler = require './bundler'

module.exports = (app)->
  
  sio = io.listen app
  
  sio.set 'authorization', (data, accept)->
      # check if there's a cookie header
      #console.log data.headers
      if (data.headers.cookie)
          
          # if there is, parse the cookie
          cookieStr = _.find data.headers.cookie.split(';'), (i)-> /express\.sid/.test(i)
          ssid = unescape cookieStr?.split('=')[1]
          # note that you will need to use the same key to grad the
          # session id, as you specified in the Express setup.
          data.sessionId = ssid
          app.store.get ssid, (err,sess)->
            data.session = sess
            data.userId = sess?.user?._id
      else
         # if there isn't, turn down the connection with a message
         # and leave the function.
         return accept('No cookie transmitted.', false)
      # accept the incoming connection
      accept(null, true)

  sio.sockets.on 'connection', (socket)->
    console.log 'session: ', socket.handshake.session
    socket.set 'userId', socket.handshake.userId
    # receive data from backbone sync
    
    socket.on 'script', (data,cb)->
      console.log 'sync: ',JSON.stringify data
      
      switch data.method
        
        when 'read'
          if (data.id?)
            Script.findById data.id, (err,script)=>
              @emit 'script', 'read', script
          else if (list = data.options.list)
            Script.list list, (err,matchingScripts)=>
              console.log 'sending ',_.pluck matchingScripts, 'code'
              @emit 'script', 'read', matchingScripts
          else if (q = data.options.query)
            Script.search q, (err, matchingScripts)=>
              console.log 'sending ',_.pluck matchingScripts, 'code'
              @emit 'script', 'read', matchingScripts
          else
            Script.find (err,scripts)=>
              @emit 'script', 'read', scripts

    socket.on 'myScript', (data, cb)->
      
      switch data.method

        when 'read'
          Script.getForUser socket.handshake.userId, (err,myScripts)=>
            cb(myScripts)
        
        when 'update'
          console.log 'updating ',data.model
          id = data.model._id
          delete data.model._id
          delete data.model._author
          Script.update { _id: id }, {$set: data.model}, (err,resp)=>
            console.log 'update resp:',resp

        when 'codeExists'
          Script.findOne { code: code }, (err,script)=>
            console.log 'hi: ',script
            cb(script)




    # request for a script bundle
    socket.on 'scrundle', (codes)->
      console.log 'recv:',codes
      bd = new Bundler()

      bd.getBundle codes

      bd.on 'bundle', (bundle)=>
        @emit 'scrundle:source', bundle

      bd.on 'progress', (count)=>
        @emit 'scrundle:progress', count

  sio