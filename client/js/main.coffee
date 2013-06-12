this.UserList = new Meteor.Collection 'userList'
this.Rooms = new Meteor.Collection 'rooms'
this.Tools = new Meteor.Collection 'tools'
this.DrawingHistory = new Meteor.Collection 'drawingHistory'
this.Chat = new Meteor.Collection 'chat'

roomHandle = undefined
shortcut = true

Meteor.subscribe 'rooms'
Meteor.subscribe 'tools'

Deps.autorun ->
  Meteor.subscribe 'userList' , Session.get 'current_room'
  Meteor.subscribe 'drawingHistory' , Session.get 'current_room'
  Meteor.subscribe 'chat' , Session.get 'current_room'

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
  
  Session.set 'current_room' , data.roomId
  #Session.set 'name' , Meteor.user().profile.name
  #Session.set 'user_id' , Meteor.userId()
  
  #  temporary
  Session.set 'name' , 'Marius'
  Session.set 'user_id' , Meteor.uuid()
  
  UserList.insert
    roomId: data.roomId
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
    roomId:null
    password:null
    width:null
    height:null
    background:null
  
  $this = $ e.target
  page = $this.closest( 'section.modal' ).attr 'data-page'
  
  $.map $this.serializeArray() , ( i ) ->
    form[ i.name ] = i.value
  
  #  Check if the room already exists
  exists = Rooms.find( { name : form.name , password : form.password } ).fetch()
  
  #  if it exists, notify the user
  if exists.length
    if page is 'create'
      dialog 'That Room + Password combination already exists'
    
    else if page is 'join'
      #  build the canvas using the found data
      buildNVCanvas exists[ 0 ]        
  
  #  if no room of that name/pass exists
  else
    if page is 'create'
      form.roomId = Session.get 'user_id' #  set the room creator
      
      #  push the room to the collection
      Rooms.insert form , ( error ) ->
        if not error
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
      $('#rname').val 'shortcut'
      #$('#options-form')[0]._submit() # can't fake submit
    , 250
  , 500
  
    
    
    
    
    
    
    
    
      