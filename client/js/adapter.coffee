# RTCPeerConnection
# getUserMedia
# attachMediaStream
# reattachMediaStream
# webrtcDetectedBrowser

if navigator.mozGetUserMedia
#   console.log "This appears to be Firefox"
  this.webrtcDetectedBrowser = "firefox"
  
  # The RTCPeerConnection object.
  this.RTCPeerConnection = mozRTCPeerConnection
  
  # The RTCSessionDescription object.
  this.RTCSessionDescription = mozRTCSessionDescription
  
  # The RTCIceCandidate object.
  this.RTCIceCandidate = mozRTCIceCandidate
  
  # Get UserMedia (only difference is the prefix).
  # Code from Adam Barth.
  this.getUserMedia = navigator.mozGetUserMedia.bind(navigator)
  
  # Attach a media stream to an element.
  this.attachMediaStream = (element, stream) ->
    console.log "Attaching media stream"
    element.mozSrcObject = stream
    element.play()

  this.reattachMediaStream = (to, from) ->
    console.log "Reattaching media stream"
    to.mozSrcObject = from.mozSrcObject
    to.play()

  
  # Fake get{Video,Audio}Tracks
  MediaStream::getVideoTracks = ->
    []

  MediaStream::getAudioTracks = ->
    []
else if navigator.webkitGetUserMedia
#   console.log "This appears to be Chrome"
  this.webrtcDetectedBrowser = "chrome"
  
  # The RTCPeerConnection object.
  this.RTCPeerConnection = webkitRTCPeerConnection
  
  # Get UserMedia (only difference is the prefix).
  # Code from Adam Barth.
  this.getUserMedia = navigator.webkitGetUserMedia.bind(navigator)
  
  # Attach a media stream to an element.
  this.attachMediaStream = (element, stream) ->
    element.src = webkitURL.createObjectURL(stream)

  this.reattachMediaStream = (to, from) ->
    to.src = from.src

  
  # The representation of tracks in a stream is changed in M26.
  # Unify them for earlier Chrome versions in the coexisting period.
  unless webkitMediaStream::getVideoTracks
    webkitMediaStream::getVideoTracks = ->
      @videoTracks

    webkitMediaStream::getAudioTracks = ->
      @audioTracks
  
  # New syntax of getXXXStreams method in M26.
  unless webkitRTCPeerConnection::getLocalStreams
    webkitRTCPeerConnection::getLocalStreams = ->
      @localStreams

    webkitRTCPeerConnection::getRemoteStreams = ->
      @remoteStreams
else
  console.log "Browser does not appear to be WebRTC-capable"