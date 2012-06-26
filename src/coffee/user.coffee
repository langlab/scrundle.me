

# add an edit view to the Script module
# for logged-in users only

module 'Scrundle.User.Script', (exports)->
  
  exports.Views = Views = {}

  userSync = (method,model,options)->
    @io ?= window.sock
    console.log 'myscript sync: ',method,model,options

    @io.emit 'myScript', {method: method, model: model, options: options}, (response)=>
      options.success response


  class Model extends Scrundle.Script.Model
    sync: userSync


  class Collection extends Scrundle.Script.Collection
    model: Model
    sync: userSync
      


  class Views.ListItem extends Backbone.View
    tagName:'tr'

    events:
      'click': ->
        @trigger 'edit', @model

    template: ->
      td "#{@get('code')}"
      td "#{@get('title')}"
      td "#{@get('description')}"

    render: ->
      @$el.html ck.render @template, @model
      @


  class Views.MyScripts extends Backbone.View
    tagName:'section'
    className:'user-scripts'

    template: ->
      div class:'row', ->
        div class:'container span5 pull-left', ->
          div class:'page-header', ->
            h2 ->
              span class:'icon-briefcase icon-large steps'
              text ' My scripts'

          div class:'user-list-view span5', ->
            table class:'table', ->
              tbody ->

        div class:'user-edit-view span6', ->


                    
    addListItem: (script)->
      script.listView = new Views.ListItem { model: script }
      script.listView.render().$el.appendTo @$('.user-list-view tbody')
      script.listView.on 'edit', (selectedScript)=>
        @editItem selectedScript
      @
    

    editItem: (script)->
      # select in the list
      @$('.user-list-view tr').removeClass('sel')
      script.listView.$el.addClass('sel')

      # open the edit view
      @detailView?.remove()
      @detailView = new Views.DetailItem { model: script }
      @detailView.render().$el.appendTo @$('.user-edit-view')
      @


    render: ->
      @$el.html ck.render @template
      @collection.each (script)=>
        @addListItem script
      @


  # script edit view
  class Views.DetailItem extends Backbone.View
    
    tagName:'form'
    className:'edit-view well form-horizontal'

    initialize: ->
      @model.on 'change', (m)=>
        console.log 'changed: ',m
        @model.listView.render()

    urlTemplate: ->
      fieldset class:'control-group', ->
        input type:'text', class:'span2', placeholder:'script url'

    events:
      'keyup input.title, input.code': ->
        @updateTitle()
        @checkCode()
      'change input, textarea': ->
        changes =
          title: @$('input.title').val()
          description: @$('textarea.description').val()
          docs: @$('input.docs').val()
          versions: 
            latest: @$('input.latest').val()

        @model.save changes, {
          success: (model,resp)=>
            console.log 'save resp: ',resp
        }

    checkCode: ->

      codeError= (errText)->
        if errText then @$('.control-group.code').addClass('error') else @$('.control-group.code').removeClass('error')
        @$('.code .help-block').text errText

        # checkCode returns the error or empty/falsy string
        errText


      if @$('input.code').val() is ''
        codeError 'You must enter a code.'
      else
        @model.isCodeValid @$('input.code').val(), (codeAvailable)=>
          console.log codeAvailable
          alreadyExists = not codeAvailable
          if alreadyExists
            codeError 'This code already exists. Try another' 
          else
            codeError ''
           
    updateTitle: (e)->
      @$('.title-label').text( @$('input.title').val() ? 'New script' )
      @$('.code-label').text( if (code = @$('input.code').val()) then " (#{ code })" else '' )

    template: ->  
      div class:'page-header', ->
        h3 ->
          span class:'title-label', "#{ @get('title') ? 'New script' }"
          if (code = @get('code'))?
            span class:'code-label', " (#{ code })"
      fieldset class:'', ->
        div class:'control-group title', ->
          label class:'control-label', 'Title:'
          div class:'controls', ->
            input type:'text',class:'title span3',placeholder:'title',value:"#{ @get('title') ? ''}"
        div class:'control-group code', ->
          label class:'control-label', 'Code:'
          div class:'controls', ->
            input type:'text',class:'code span1',placeholder:'code',value:"#{ @get('code') ? '' }"
            span class:'help-inline', 'unique code < 5 characters'
        div class:'control-group', ->
          label class:'control-label', 'Script (latest):'
          div class:'controls', ->
            input type:'text',class:'latest',placeholder:'script url',value:"#{ @getLatestScriptURL() ? '' }"
            span class:'help-inline', ''
        div class:'control-group', ->
          label class:'control-label', 'Docs:'
          div class:'controls', ->
            input type:'text',class:'docs',placeholder:'docs url',value:"#{ @getLatestScriptURL() ? '' }"
            span class:'help-inline', ''
        div class:'control-group', ->
          label class:'control-label', 'Description:'
          div class:'controls', ->
            textarea class:'description', placeholder:'script description...', "#{ @get('description') ? '' }"

        div class:'modal-footer', ->
          button class:'btn cancel', 'Cancel'
          button class:'btn btn-danger delete', 'Delete'
          button class:'btn btn-success save', 'Save'

    render: ->
      @$el.html ck.render @template, @model
      @delegateEvents()
      @


  class Views.List extends Backbone.View

    tagName: 'div'
    className: 'user-list-view span6'

    template: ->
      
      

    render: ->
      @$el.html ck.render @template, @
      @

  exports.Model = Model
  exports.Collection = Collection


# models and views
# only used by an authorized user

module 'Scrundle.User', (exports, top)->

  class Model extends Backbone.Model
    initialize: ->
      @myScripts = new Scrundle.User.Script.Collection()
      @myScripts.fetch {mine:true}

    getName: ->
      @get('twit').name

    getIconUrl: ->
      @get('twit').profileImageUrl

  exports.Model = Model


    



$ ->
  
  Scrundle.app.user = new Scrundle.User.Model window.user
  Scrundle.app.session = window.session

  Scrundle.app.views.navBar.login(Scrundle.app.user)


  # route for listing user scripts
  Scrundle.app.route 'mine','mine', ->
    @closeViews()
    Scrundle.app.views.myScripts = new Scrundle.User.Script.Views.MyScripts {collection: Scrundle.app.user.myScripts}
    Scrundle.app.views.myScripts.render().open()

