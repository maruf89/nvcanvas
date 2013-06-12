class window.NVCanvas
  _instance = undefined # Must be declared here to force the closure on the class
  @get: (args) -> # Must be a static method
    _instance ?= new _NVCanvas args

class _NVCanvas
  _t = undefined
  doc = undefined
  REM = undefined
  
  constructor: ( data ) ->
    _t = @
    doc = $ document
    
    REM = +$('html').css('font-size').split('px')[0]

    @imgData ?= data.imgData
    @data = data
    @sid = Session.get 'user_id'
    @users = {}
    
    @attr =
      s:
        strokeStyle:'#000'
        lineWidth:1
        fillStyle:'#000'
      type:'pencil'
    
    #  set the default tool on load
    @type = new @Tools.pencil @attr , 1
    
    #  on mongo db init, load all the tools
    if Tools.find().count() is 0
      Tools.insert { name:x } for x of @Tools
    
    @sendObj =
      sid:@sid
      room:@data.roomId
    
    #  will store the undo/redo states
    @undo = []
    @redo = []
    
    #  initiate the page splitter
    @distributeUtilites()
    
    UserList.find().observe
      added: ( user ) ->
        _t.setupCanvas user.userId unless Session.equals 'user_id' , user.userId
      removed: ( user ) ->
        1
    
    @drawingHistory()
  
  
  

#    ----------------------------                   $UI SETUP                 ----------------------------
  
  
  
  distributeUtilites: =>
    $('#canvasWrapper').splitter
      splitHorizontal:true
      outline:true
      sizeBottom:150
    
    $('#topPanel').splitter
      splitVertical:true
      outline:true
      sizeLeft:125
      maxLeft:125
    
    $('#rightPanel').splitter
      splitVertical:true
      outline:true
      sizeRight:200
      maxRight:200
    
    $('#userWindow').splitter
      splitHorizontal:true
      outline:true
      sizeTop:300
      minTop:26
      minBottom:27
    
    @setupCanvas @sid, true

    @toolbarFunctions()
    
    @onResize()
    
    @chatFunctions()
    
    @initVideo()
  
  
  
  

 
#    ------------------       CANVAS $SETUP          ---------------------
  




  
  setupCanvas: ( user , me ) ->
    specs = @data
    inner = undefined
    container = undefined
    
    #  check if we're setting up a new persons canvas or ours
    if not me then container = doc.find '#container'
    else
      inner = $('<section id="canvasInner" />').css
        marginLeft: -specs.width >> 1
        marginTop: -specs.height >> 1
        width: specs.width
        height: specs.height
        background: specs.background
      
      container = $('<div id="container" />').appendTo inner
      
    canvas = $("<canvas id='#{user}' width='#{specs.width}' height='#{specs.height}' />").css
      background: 'rgba(0,0,0,0)'
      zIndex: if me then 5 else 1
    .appendTo container
    
    if me
      @canvas = canvas
      @_canvas = "##{@sid}"
      inner.appendTo $ '#screen'
      @initCanvas()
      @canvasHotkeys()
      
      @userLayers()
    else
      @users[ user ] = {}
      @users[ user ].tool = '' #  will store the name of the Tool
      @users[ user ].canvas = canvas
      @users[ user ].ctx = canvas[0].getContext '2d'
      @users[ user ].undo = []
      @users[ user ].redo = []

  initCanvas: ->
    @ctx = @canvas[0].getContext '2d'
    
    doc.on "mousedown.canvasDraw" , @_canvas , ( e ) =>
      if @canvasKey and @canvasKey.freeze then return false
      @canvasMouseDown e
    .on "mouseup.canvasDraw" , @_canvas , ( e ) =>
      if @canvasKey and @canvasKey.freeze then return false
      
      @canvasMouseUp e
  
      
      
#    ----------------------------                   $DRAWING FUNCTIONS                ----------------------------





  defineCanvasStyles: (attributes, user) ->
    $.each attributes.s, (i,v) =>
       user.ctx[i] = v
  
  Draw:
    move:1
    end:1
  
  canvasMouseDown: (event) ->
    @offset = $(@canvas).offset()
    _x = @offset.left
    _y = @offset.top
    x = event.pageX - _x
    y = event.pageY - _y
    
    @defineCanvasStyles @attr, @
       
    @ctx.moveTo event.pageX - _x, event.pageY - _y
    @ctx.beginPath()
    
    # save the current canvas to allow CMD + Z
    @saveUndoState()
    
    data = $.extend
      event:'mousedown'
      x:x
      y:y
      time: ( new Date() ).getTime()
      attributes:@attr,
      @sendObj
    
    DrawingHistory.insert data , ( err ) ->
      if err
        console.log 'error storing mousedown canvas event data to drawingHistory'
    
    @type.mousedown x,y,@
    
    if @Draw.move
      doc.on "mousemove.canvasDraw" , @_canvas , ( e ) =>
        x = e.pageX - _x
        y = e.pageY - _y
        
        data = $.extend
          event:'mousemove'
          x:x
          y:y
          time: ( new Date() ).getTime()
          @sendObj
        
        DrawingHistory.insert data , ( err ) ->
          if err
            console.log 'error storing mousemove canvas event data to drawingHistory'
        
        @type.mousemove x,y
    
  canvasMouseUp: ( e ) ->
    x = e.pageX - @offset.left
    y = e.pageY - @offset.top
    doc.off "mousemove.canvasDraw" , @_canvas
    
    data = $.extend
      x: x
      y: y
      time: ( new Date() ).getTime()
      event:'mouseup'
      @sendObj
    
    DrawingHistory.insert data , ( err ) ->
      if err
        console.log 'error storing mousedown canvas event data to drawingHistory'
    
    @type.mouseup x,y
  
  saveUndoState: ( user = @ ) ->
    data = user.ctx.getImageData( 0 , 0 , @data.width , @data.height )
    
    user.undo.length = 2
    user.undo.unshift data
  
  saveRedoState: ( user = @ ) ->
    data = user.ctx.getImageData( 0 , 0 , @data.width , @data.height )
    
    user.redo.length = 2
    user.redo.unshift data




  
  
 
#    ------------------        $HOTKEYS          ---------------------
  
  
  canvasHotkeys: ->
    @canvasKey = {}
    
    $(':input,textarea').focus =>
      @canvasKey.textFocus = true
    .blur =>
      @canvasKey.textFocus = false
    
    doc.on 'mouseenter' , @_canvas , =>
      @canvasKey.active = true
    .on 'mouseleave', @_canvas , =>
      @canvasKey.active = false
    
    doc.on 'keydown.canvasHotkey' , (eve) =>
      container = $ '#canvasInner'
      
      
      #       $MOVE CANVAS
      
      if eve.which is 32 and not @canvasKey.textFocus and @canvasKey.active
        @canvasKey.freeze = true
        container.css 'cursor' , 'move'
        
        doc.on 'mousedown.canvasMove' , @_canvas , (ev) =>
          startPos = container.position()
          cx = +container.css('margin-left').split('px')[0]
          cy = +container.css('margin-top').split('px')[0]
          
          ex = ev.pageX
          ey = ev.pageY
          
          doc.on 'mousemove.canvasMove', (e) =>
            dx = e.pageX - ex
            dy = e.pageY - ey
            
            container.css
              marginLeft: cx + dx
              marginTop: cy + dy
        
        doc.on 'mouseup.canvasMove' , @_canvas , =>
          @offset = container.offset()
          startPos = container.position()
          doc.off 'mousemove.canvasMove'
        
        doc.on 'keyup.canvasMove', =>
          doc.off '.canvasMove'
          $(container).css 'cursor','crosshair'
          @canvasKey.freeze = false


  
  
  
  
#    ----------------------------                   $HISTORY                 ----------------------------






  drawingHistory: =>
    DrawingHistory.find( {} , { sort: { time: -1 } } ).observeChanges
      added: ( id , data ) =>
        @setupUserDraw data unless Session.equals 'user_id' , data.sid
          
  setupUserDraw: ( data ) ->
    return false unless @users[ data.sid ]
    user = @users[ data.sid ]
    
    #  if a new tool type is set, recreate it
    if data.attributes?.type? and user.tool isnt data.attributes.type
      #  update the tool name each time it changes so this doesn't keep creating new
      #  copies Tools of the same tool
      user.tool = data.attributes.type
      
      user.type = new @Tools[ user.tool ] data.attributes # lastly init it
    
    user.type[ data.event ] data.x , data.y , user
    
    
    
    
    
    
#    ----------------------------                   $USERS                 ----------------------------




  
  userLayers: ->
    # set the first layer to current users layer
    $('#canvas-layers li').attr 'ref', @sid
    
    # bind functions
    doc.on 'click' , '#canvas-layers li a' , ->
      $this = $ this
      switch $this.attr 'type'
        when 'visibility'
          $this.toggleClass('layer-show')
          
          if $('#canvas-layers').find( 'li a.layer-solo' ).length then return false
          id = $this.parent().attr 'ref'
          target = $ "canvas##{id}"
          
          if $this.hasClass 'layer-show' then target.css 'display' , 'block'
          else target.css 'display' , 'none'
          
        when 'solo'
          $this.toggleClass 'layer-solo'
          _true = 'block'
          _false = 'none'
          
          if $('#canvas-layers').find( 'li a.layer-solo' ).length
            batch = $('#canvas-layers li a[type="solo"]')
            _class = 'layer-solo'
            
          else
            batch = $('#canvas-layers').find 'li a[type="visibility"]'
            _class = 'layer-show'
          
          $.each batch , ( i , v ) ->
            $v = $ v
            id = $v.parent().attr 'ref'
            target = $ "canvas##{id}"
            
            if $v.hasClass _class then target.css 'display' ,  _true
            else target.css 'display' , _false
            
            
            
            

#    ----------------------------                   $CHAT                 ----------------------------



  
  chatFunctions: ->
    doc.on 'submit' , '#chat-input' , ( e ) =>
      e.preventDefault()
      input = $('#chat-input').find( '.input' )
      message = input.val()
      input.val ''
      
      data =
        user: Session.get 'name'
        userId: Session.get 'user_id'
        message: message
        room: Session.get 'current_room'
        time: ( new Date() ).getTime()
      
      Chat.insert data , ( err ) ->
        if err then console.log 'Error sending chat message'
  
  
  chatMessageFormat: ( data ) ->
    message = data.message
    type = data.type
    switch type
      when 'I','emote' then style = "color:yellow;font-style:italic"
      when 'general' then style = "color:#fff"
      when 'users' then style = "color:#575a5d"
      when 'me' then style = "color:#ccc"
      when 'swoon' then style = "color:green"
      when 'private' then style = "color:fuchsia"
    
    "<p style=#{style}>#{message}</p>"





#    ----------------------------                   $TOOL BAR                 ---------------------------- 



  
  
  Tools:
    'pencil': (attr, me) ->
      if me then _t.Draw.move = 1
      
      @attr = attr
      
      @mousedown = ( x , y , user ) ->
        @user = user
        @user.ctx.globalCompositeOperation = 'source-over'
        
        _t.defineCanvasStyles @attr, @user
        
        @user.ctx.lineJoin = 'round'
        @user.ctx.beginPath()
        @user.ctx.moveTo x,y
      
      @mousemove = ( x , y ) ->
        @user.ctx.lineTo x,y
        @user.ctx.stroke()
        
      @mouseup = ( x , y ) ->
        @user.ctx.closePath()
      
      this
    
    'eraser': (_, me) ->
      if me then _t.Draw.move = 1
      
      @mousedown = (x,y,user) ->
        @user = user
        @user.ctx.globalCompositeOperation = 'destination-out'
        
        @user.ctx.beginPath()
        @user.ctx.moveTo x,y
      
      @mousemove = (x,y) ->
        @user.ctx.lineTo x,y
        @user.ctx.stroke()
        
      @mouseup = (x,y) ->
        @user.ctx.closePath()
      
      this
    
    'paint': (attr,me) ->
      if me then _t.Draw.move = 1
      
      @attr = attr
      @last = 
        x: undefined
        y: undefined
      
      maxSpeed = 250
      minSpeed = 5
      speed = 1
      
      @mousedown = (x,y,user) ->
        @user = user
        @ctx = @user.ctx
        @ctx.globalCompositeOperation = 'source-over'
        
        @last.x = x
        @last.y = y
        
        @ctx.beginPath()
        @drawArc x,y
        @ctx.closePath()
        @ctx.lineJoin = 'round'
        @ctx.beginPath()
      
      @drawArc = ( x , y , size = speed ) ->
        @ctx.arc x , y , ( @attr.s.lineWidth >> 1 ) * size , 0 , Math.PI * 2 , true
        _t.defineCanvasStyles @attr, @user
        @ctx.closePath()
        @ctx.fill()
      
      @drawLine = ( x , y , size = speed ) ->
        @ctx.lineTo x,y
        @ctx.stroke()
        
      ##    OPTIONAL   ##
      @drawGaps = ( x , y ) ->
        last = @last
        _x = x - last.x
        _y = y - last.y
        
        dist = Math.sqrt( Math.pow( _x, 2) + Math.pow( _y, 2 ) )
        
        _xInc = if isFinite _x / dist then _x / dist else 0
        _yInc = if isFinite _y / dist then _y / dist else 0
        speed = if dist > 5 then (1 - dist / (maxSpeed - minSpeed)) else 1
        
        for i in [1..(Math.ceil dist)]
          @drawArc last.x + i * _xInc, last.y + i * _yInc, speed
      
      @mousemove = (x,y) ->
        #@drawGaps x,y
        
        @drawLine x,y
        
        @last.x = x
        @last.y = y
        
      @mouseup = (x,y) ->
        @ctx.closePath()
        @ctx.beginPath()
        @drawArc x,y
      
      this

    'pen': (attr, me) ->
      if me then _t.Draw.move = 1
      
      @attr = attr
      
      @cX1 = undefined # control points for bezier
      @cY1 = undefined
      @cX2 = undefined
      @cY2 = undefined
      
      @iX = undefined # initial coordinates on path start
      @iY = undefined
      
      @closeX = undefined # control points for closing the path
      @closeY = undefined
      
      @draw = false
      
      @mousedown = (x,y,user) ->
        @user = user
        @sX = x # sX - start x
        @sY = y
        
        if not @draw 
          @iX = x
          @iY = y
        
        _t.defineCanvasStyles @attr, @user
        
      @mousemove = (x,y) ->
        # show user the handles
        
      @mouseup = (x,y) ->
        
        difX = x - @sX
        difY = y - @sY
        
        # if not the very first stroke then...
        if @draw
          @cX2 = @sX - difX
          @cY2 = @sY - difY
          
          @user.ctx.beginPath()
          @user.ctx.moveTo @lX, @lY
          @user.ctx.bezierCurveTo @cX1, @cY1, @cX2, @cY2, @sX, @sY
          
          @user.ctx.stroke()
          
          @cX1 = @sX + difX
          @cY1 = @sY + difY
          
        else
          @draw = true
          @cX1 = @sX + difX
          @cY1 = @sY + difY
          
          @closeX = @sX - difX
          @closeY = @sY - difY
        
        @lX = @sX
        @lY = @sY
      
      this
          
          
          
  
  toolbarFunctions: ->
    
    # TOOL MENU
    tools = $ '#tools'
    tools.on 'click' , '.sprite:not(.selected)' , ->
      tools.find('li .selected').removeClass 'selected'
      which = $(@).addClass('selected').attr('class').match(/tool-([a-z]+)/)[1] || 'pencil'
      
      _t.attr.type = which
      _t.type = new _t.Tools[which] _t.attr, true
    
    # STROKE WIDTH
    doc.on 'change' , '#lineWidth' , (e) =>
      @attr.s.lineWidth = ( +e.currentTarget.value - .5 )
    
    # COLOR PICKER FOR STROKE/FILL
    $.each $('#fill-stroke').children(), (i,v) =>
      v = $(v)
      which = if v.hasClass 'stroke' then 'strokeStyle' else 'fillStyle'
      v.ColorPicker
        color: '#000'
        onShow: (colpkr) ->
          $(colpkr).fadeIn 500
          v.addClass('selected').siblings().removeClass 'selected'
          return false
        onHide: (colpkr) =>
          $(colpkr).fadeOut 500
          return false
        onChange: (hsb, hex, rgb) =>
          @attr.s[which] = "##{hex}"
          v.css 'background', "##{hex}"

  
  
  

  
#    ----------------------------                   $VIDEO                 ----------------------------


  
  
  # createSignalingChannel: ->
  
  videoStart: ( isCaller ) ->
    pcConfig = 
      "iceServers":
        [ { "url": "stun:stun.l.google.com:19302" },
          { "url": "turn:my_username@<turn_server_ip_address>" , "credential": "my_password" }
        ]
    pc = RTCPeerConnection pcConfig
    
    pc.onicecanditate = ( e ) =>
      @videoSettings.signalingChannel.send JSON.stringify candidate: e.candidate
    
    pc.onaddstream = ( e ) =>
      @videoSettiongs.remoteVideo.src = URL.createObjectURL e.stream
    
    # navigator.getUserMedia({ "audio": true, "video": true }, function (stream) {
#         selfView.src = URL.createObjectURL(stream);
#         pc.addStream(stream);
# 
#         if (isCaller)
#             pc.createOffer(gotDescription);
#         else
#             pc.createAnswer(pc.remoteDescription, gotDescription);
# 
#         function gotDescription(desc) {
#             pc.setLocalDescription(desc);
#             signalingChannel.send(JSON.stringify({ "sdp": desc }));
#         }
#     });
# signalingChannel.onmessage = function (evt) {
#     if (!pc)
#         start(false);
# 
#     var signal = JSON.parse(evt.data);
#     if (signal.sdp)
#         pc.setRemoteDescription(new RTCSessionDescription(signal.sdp));
#     else
#         pc.addIceCandidate(new RTCIceCandidate(signal.candidate));
# };


  videoSettings:
    sdpConstraints:
      'mandatory':
        'OfferToReceiveAudio': true
        'OfferToReceiveVideo': true
    mainVideo: null
    removeVideo
    signalingChannel: null
    users:[]

  initVideo: ->
    @videoSettings.mainVideo = $ '#main-video'
    getUserMedia
      audio: true
      video: true
    , @streamVideo
    , @streamVideoError
  
  streamVideo: ( stream ) -> 
    #attachMediaStream
    _t.videoSettings.mainVideo[ 0 ].src = URL.createObjectURL stream
  
  

  
#    ----------------------------                   $RESIZE                 ----------------------------






  toREM: ( rem ) -> rem * REM


  onResize: ->
    # Chat Window
    $('#chatWindow').bind 'splitter', ->
      $this = $ this
      $this.find('.update').css
        height: $this.height() - _t.toREM 1.5
        width: $this.find('.inner').width() /2 - _t.toREM 1.5
    .trigger 'splitter'
    
    # User Window
    $('#userWindow').bind 'splitter', ->
      $this = $ this
      $.each $this.find( '.inner' ) , ( i , v ) ->
        v = $(v)
        v.find( '.update' ).css
          height: v.height() - 27
    .trigger 'splitter'