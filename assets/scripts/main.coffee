###
require [
  'socket.io'
], (io)->
  socket = io.connect '/room'
  socket.on 'connect', -> console.info 'io-connect'
  socket.on 'disconnect', -> console.info 'io-disconnect'
  # custom events, current_song changed

  socket.on 'current_song', (msg)->
    console.info 'change current_song to', msg
    #current_song.set msg

  room_name = 'room1'
  socket.emit 'join', room_name
###

define 'collections/channel', ['backbone', 'models/song'], (Backbone, Song)->
  ###
  params:
    type: s、p、e、b、n、u、r
    s: skip
    p: playing <when play list is empty>
    e: end <when one song ends>
    b: ban <when song is marked as trash>
    n: request a new playlist
    u: unrate, r: rate
    sid: current_sid
    channel: current_channle
    r: a random key. which.length() == 10
    kbps: 192, 128, 64
    from: mainsite
  ###

  class ChannelListCollection extends Backbone.Collection
    model: Song
    url: ->
      '/fm/mine/playlist'
      #?type=n&sid=&pt=0.0&channel=0&from=mainsite&kbps=192&r=82e6b6a312'
    parse: (response)->
      if response.r == 0
        return response.song


define 'turkeyfm', [
  'underscore'
  'backbone'
  'collections/channel',
  'models/current_song',
  'models/current_user'
  'templates/iframeplayer'
], (_, Backbone, Channel, current_song, current_user, iframeplayer)->
  # current_channel
  channel = new Channel()

  class TurkeyFM #extends Backbone.Events
    constructor: ->
      _.extend this, Backbone.Events
      @listenTo channel, 'sync', @synced

    synced: ->
      # Remove and return the first song from collection
      current_song.set channel.shift().toJSON()

    # http://www.ijusha.com/referer-anti-hotlinking/
    initPlayer: ->
      window.AudioPlayer = iframeplayer host: location.host
      $('body').append '''<iframe
        src="javascript: parent.AudioPlayer;"
        frameBorder="0"
        width="0"
        height="0"></iframe>'''

    rock: ->
      @initPlayer()
      channel.fetch()


require [
  'jquery'
  'backbone'
  'utils/ajax'
  'models/current_user'
], ($, Backbone, ajax, current_user)->
  ## if not login, then show the login form
  ajax.json '/account', (r)->
    if r.r == 0
      current_user.set r.user_info
    else
      require ['views/mod/login'], (mod_login)->
        $('body').append(mod_login.el)
        mod_login.show()

require ['turkeyfm'], (FM)->
  lets = new FM()
  # Let's rock, play the music!!!
  lets.rock()


