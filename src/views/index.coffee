doctype 5
html lang:'en', ->
  head ->
    title 'scrundle.me!'
    meta charset:'utf-8'
    meta name:"viewport", content:"width=device-width, initial-scale=1.0"
    link rel:'stylesheet', href:'/css/bootstrap.min.css'
    link rel:'stylesheet', href:'/css/index.css'

  body ->

    div class:'container main', ->
 
    script type:'text/javascript',src:'/js/utils.js'
    script type:'text/javascript',src:'/ck.js'
    script type:'text/javascript',src:'/js/bootstrap.min.js'
    script type:'text/javascript',src:'/socket.io/socket.io.js'
    script type:'text/javascript',src:'/js/client.js'