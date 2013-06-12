UserList = new Meteor.Collection 'userList'
Rooms = new Meteor.Collection 'rooms'
Tools = new Meteor.Collection 'tools'
DrawingHistory = new Meteor.Collection 'drawingHistory'
Connections = new Meteor.Collection 'connections'
Chat = new Meteor.Collection 'chat'

Meteor.startup ->
  Meteor.publish 'rooms' , ->
    Rooms.find()
    
  Meteor.publish 'tools' , ->
    Tools.find()
    
  Meteor.publish 'drawingHistory' , ( roomId ) ->
    DrawingHistory.find { room: roomId }
    
  Meteor.publish 'userList' , ( roomId ) ->
    UserList.find { roomId: roomId }
  
  Meteor.publish 'chat' , ( roomId ) ->
    Chat.find { room: roomId }
  
  # server code: heartbeat method
  Meteor.methods keepalive: (userId) ->
    Connections.insert userId: userId unless Connections.findOne userId: userId
    Connections.update userId: userId,
      $set:
        last_seen: ( new Date() ).getTime()
  
  # clear all connections + users on server restart
  UserList.remove {}
  Connections.remove {}
  #DrawingHistory.remove {}
  
  # server code: clean up dead clients after 10 seconds
  Meteor.setInterval ->
    now = ( new Date() ).getTime()
    
    #  stores the userId of Users and _id of Connectios to be removed at the end
    removeId = remove_id = []
    
    Connections.find( last_seen:
      $lt: ( now - 10 * 1000 )
    ).forEach (user) ->
      removeId.push user.userId
      remove_id.push user._id
    
    #  instead of removing 1 by 1, we remove them all at once
    if removeId.length
      Meteor._debug removeId
      UserList.remove userId:
        $in: removeId
      
      DrawingHistory.remove sid:
        $in: removeId
      
      Connections.remove _id:
        $in: remove_id
    
  , 5000









