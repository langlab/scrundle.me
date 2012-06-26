# models and views
# only used by an authorized user

module 'Scrundle.User', (exports, top)->

  class Model extends Backbone.Model
    initialize: ->
      @myScripts = new Scrundle.Script.Collection()
      @myScripts.fetch {mine:true}

    getName: ->
      @get('twit').name

    getIconUrl: ->
      @get('twit').profileImageUrl

  exports.Model = Model


    

# add an edit view to the Script module
# for logged-in users only

module 'Scrundle.User.Script', (exports)->
  
  exports.Views = Views = {}

  class Views.Edit extends Backbone.View
    
    tagName:'div'
    className:'edit-view modal hide'

    urlTemplate: ->
      fieldset class:'control-group', ->
        input type:'text', class:'span2', placeholder:'script url'

    events:
      'keyup input.title, input.code': ->
        @updateTitle()
        @checkCode()

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
      div class:'modal-header', ->
        h3 ->
          span class:'title-label', "#{ @get('title') ? 'New script' }"
          if (code = @get('code'))?
            span class:'code-label', " (#{ code })"
      div class:'modal-body', ->
        form class:'edit-form form-inline', ->
          fieldset class:'control-group code', ->
            div class:'controls', ->
              input type:'text',class:'code span1',placeholder:'code',value:"#{ @get('code') ? '' }"
              p class:'help-block'
          fieldset class:'control-group title', ->
            div class:'controls', ->
              input type:'text',class:'title span3',placeholder:'title',value:"#{ @get('title') ? ''}"
          fieldset class:'control-group', ->
            textarea class:'description', placeholder:'script description...', "#{ @get('description') ? '' }"

      div class:'modal-footer', ->
        button class:'btn btn-success save', 'save'

    render: ->
      @$el.html ck.render @template, @model
      @

    open: ->
      @$el.modal 'show'
      @delegateEvents()
      @

  class Views.List

    tagName: 'table'
    className: 'user-list-view table'

    render: ->






$ ->
  
  
  
  Scrundle.app.user = new Scrundle.User.Model window.user
  Scrundle.app.session = window.session

  Scrundle.app.views.navBar.login(Scrundle.app.user)


  # route for listing user scripts
  Scrundle.app.route 'mine','myScripts', ->
    @closeViews()
    Scrundle.app.views.myScripts = new Scrundle.User.Script.Views.List()

  # route for editing a script
  Scrundle.app.route 'edit/:id','editOne', (code)->
    @closeViews()
    eModel = @views.editView.model = new Scrundle.Script.Model()
    if id
      eModel.set '_id', id
      eModel.fetch {
        success: =>
          console.log eModel
          @views.editView.render( ).open('body')
        error: (err)=>
          console.log err
          eModel.set '_id', null
          eModel.render().open('body')
      }
    else
      @views.editView.render().open('body')
    @
