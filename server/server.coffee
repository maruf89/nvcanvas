UserList = new Meteor.Collection 'userList'
Rooms = new Meteor.Collection 'rooms'
Tools = new Meteor.Collection 'tools'
DrawingHistory = new Meteor.Collection 'drawingHistory'
Connections = new Meteor.Collection 'connections'
Chat = new Meteor.Collection 'chat'
now = null

Meteor.startup ->
  Meteor.publish 'rooms' , ( roomName , password ) ->
    Rooms.find { name: roomName , password: password }
    
  Meteor.publish 'tools' , ->
    Tools.find()
    
  Meteor.publish 'drawingHistory' , ( roomId , password ) ->
    DrawingHistory.find { roomId: roomId , password: password } , { fields: { 'roomId':0 , 'password':0 } }
    
  Meteor.publish 'userList' , ( roomId , password ) ->
    #Meteor._debug arguments
    UserList.find { roomId: roomId , password: password } , { fields: { 'name':1 , 'userId':1 } }
  
  Meteor.publish 'chat' , ( roomId , password ) ->
    Chat.find { roomId: roomId, password: password } , { fields: { 'name':1 , 'userId':1 } }
  
  # server code: heartbeat method
  Meteor.methods keepalive: (userId) ->
    Connections.insert userId: userId unless Connections.findOne userId: userId
    Connections.update userId: userId,
      $set:
        last_seen: now = ( new Date() ).getTime()
  
  # clear all connections + users on server restart
  #UserList.remove {}
  #Connections.remove {}
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
  
  #  remove all old stuff
  Meteor.setInterval ->
    #  reuse the instance of now because we know that the previous timer is updating it within
    #  the same interval 60 % 5 = 0
    UserList.find().forEach ( user ) ->
      if not Connections.findOne { 'userId' : user.userId }
        Meteor._debug "Connection missing for #{user._id}"
        UserList.remove user._id
  , 60000









