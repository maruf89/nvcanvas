this.UserList = new Meteor.Collection 'userList'
this.Room = new Meteor.Collection 'rooms'
this.Tools = new Meteor.Collection 'tools'
this.DrawingHistory = new Meteor.Collection 'drawingHistory'
this.Chat = new Meteor.Collection 'chat'

roomHandle = undefined
shortcut = true


Meteor.subscribe 'tools'

Deps.autorun ->
  Meteor.subscribe 'userList' , Session.get( 'current_room' ) , Session.get( 'room_password' )
  Meteor.subscribe 'drawingHistory' , Session.get( 'current_room' ) , Session.get( 'room_password' )
  Meteor.subscribe 'chat' , Session.get( 'current_room' ) , Session.get( 'room_password' )

dialog = ( message ) ->
  alert message

$(document).on 'click' , '.modal a.x-out' , ->
  $('section.modal').fadeOut 'fast' , -> $(this).remove()

NVC = undefined

Template.init.events
  "click a.button": ( e , T ) ->
    $this = $ e.target
    
    # if not Meteor.userId()
#       alert 'You must first login'
#       return false
    
    fragment = Meteor.render ->
      Template[ $this.attr( 'action' ) + 'Room' ]()
    
    $('body').append fragment


buildNVCanvas = ( data ) ->
  #  hide everything
  $('#login, section.modal').fadeOut 'fast' , -> $(this).remove()
  
  Session.set 'current_room' , data._id
  Session.set 'room_password' , data.password
  #Session.set 'name' , Meteor.user().profile.name
  #Session.set 'user_id' , Meteor.userId()
  
  #  temporary
  Session.set 'name' , 'Marius'
  Session.set 'user_id' , Meteor.uuid()
  
  UserList.insert
    roomId: data._id
    password:data.password
    userId: Session.get 'user_id'
    name: Session.get 'name'
  
  #  render the canvas
  fragment = Meteor.render ->
    Template[ 'utilities' ]()
  
  $('body').append fragment
  
  #  unleash the NVCanvas
  NVC = new NVCanvas.get data
  keepAlive()


goToRoom = ( e , T ) ->
  e.preventDefault()
  form =
    password:null
    width:null
    height:null
    background:null
  
  $this = $ e.target
  page = $this.closest( 'section.modal' ).attr 'data-page'
  
  $.map $this.serializeArray() , ( i ) ->
    form[ i.name ] = i.value
  
  #  Check if the room already exists
  Meteor.subscribe 'rooms' , form.name , form.password , ( exists ) ->
    #  if it exists, notify the user
    if exists = Room.findOne()
      if page is 'create'
        dialog 'That Room + Password combination already exists'
      
      else if page is 'join'
        #  build the canvas using the found data
        buildNVCanvas exists
    
    #  if no room of that name/pass exists
    else
      if page is 'create'
        
        #  push the room to the collection
        roomId = Room.insert form , ( error ) ->
          if not error
            form._id = roomId
            buildNVCanvas form
            
          else
            console.log error
      
      else
        dialog 'No room with that name/password combination exists'
  
  

Template.createRoom.events
  "submit #options-form": goToRoom

Template.joinRoom.events
  "submit #options-form": goToRoom

Template.toolBlock.helpers
  tools: ->
    Tools.find()

Template.userBlock.helpers
  users: ->
    UserList.find()

Template.videoBlock.helpers
  users: ->
    UserList.find()

Template.chatBlock.helpers
  messages: ->
    Chat.find {} , { sort: { time: -1 } }

Template.gaAnalytics.rendered = ->
  if not window._gaq?
    window._gaq = []
    _gaq.push(['_setAccount', 'UA-41737651-1'])
    _gaq.push(['_trackPageview'])
    ( ->
      ga = document.createElement('script');
      ga.async = true;
      gajs = '.google-analytics.com/ga.js'
      ga.src = if 'https:' is document.location.protocol
        'https://ssl'+gajs
      else 'http://www'+gajs
      s = document.getElementsByTagName( 'script' )[0];
      s.parentNode.insertBefore ga, s
    )()

keepAlive = ->
  Meteor.setInterval ->
    Meteor.call 'keepalive' , Session.get 'user_id'
  , 5000

if shortcut
  setTimeout ->
    evt = document.createEvent "MouseEvents"
    evt.initMouseEvent('click',true,true,window,0, 0, 0, 0, 0,false,false,false,false,0,null);
    $('a[action="join"]')[0].dispatchEvent evt
    setTimeout ->
      $('#rname').val 'test'
      $('#rpassword').val 'test'
      #$('#options-form')[0]._submit() # can't fake submit
    , 250
  , 500
  
    
    
    
    
    
    
    
    
      