doctype 5
html lang:'en', ->
  head ->
    title 'scrundle.me!'
    meta charset:'utf-8'
    meta name:"viewport", content:"width=device-width, initial-scale=1.0"
    link rel:'stylesheet', href:'/css/bootstrap.css'
    link rel:'stylesheet', href:'/css/index.css'

  body ->
    div class:'navbar navbar-fixed-top', ->
      div class:'navbar-inner', ->
        div class:'container', ->
          a class:'brand', 'scrundle.me'
          ul class:'nav', ->
            li ->
              a href:'#', 'About'
            li ->
              a href:'#finder-view', 'Find & Bundle Scripts'
            li ->
              a href:'#why', 'Why?'
          ul class:'nav pull-right user-info', ->
            li class:"divider-vertical"
            li ->
              a href:'/auth/twitter', ->
                i class:'icon-twitter-sign'
                text ' Sign in'

    div class:'container main', ->
            
    script type:'text/javascript',src:'/js/utils.js'
    script type:'text/javascript',src:'/ck.js'
    script type:'text/javascript',src:'/js/bootstrap.min.js'
    script type:'text/javascript',src:'/socket.io/socket.io.js'

    # this will bootstrap session data into the global namespace
    if @session
      script id:'sessionBootstrap', type:'text/javascript', """
        window.session = #{JSON.stringify @session}; 
        window.user = #{JSON.stringify @user}; 
        setTimeout(function() { $('#sessionBootstrap').remove(); }, 3000 );
      """
    
    # client-side app for all users
    script type:'text/javascript',src:'/js/client.js'
    
    # only include if user is signed in
    if @user 
      script type:'text/javascript',src: '/js/user.js'

