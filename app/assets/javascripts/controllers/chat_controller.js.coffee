Twitchpluschat.ChatController = Ember.ArrayController.extend
  MaxVisibleMessages: 50

  _parentController: null

  needs: ['video']
  video: Ember.computed.alias('controllers.video')
  messagesSorting: ['createdAt']
  sortedMessages: Ember.computed.sort('pastMessages', 'messagesSorting')
  currentMessages: []

  pastMessages: ((message) ->
    absoluteCurrentTime = @get('video.absoluteCurrentTime')

    if absoluteCurrentTime?
      @filter (message) ->
        message.get('createdAt') <= absoluteCurrentTime
    else
      []
  ).property('@this.@each.createdAt', 'video.absoluteCurrentTime')

  visibleMessages: (->
    @get('sortedMessages').slice(-@get('MaxVisibleMessages') - 1)
  ).property('sortedMessages')

  parentController: ((key, value) ->
    if arguments.length > 1
      @set('_parentController', value)

      @get('parentController').on 'currentTimeDidChange', =>
        @findMessagesAtCurrentTime() if @get('video.absoluteCurrentTime')?

    @get('_parentController')
  ).property()

  findMessagesAtCurrentTime: ->
    @store.findMessages(
      videoId: @get('video.id'),
      atTime: @get('video.absoluteCurrentTime'),
      minTime: @get('video.recordedAt')
    ).then (currentBatch) =>
      allMessages = @set('content', @store.all('message'))
      currentMessages = @get('currentMessages')
      visibleMessages = @get('visibleMessages')

      @beginPropertyChanges()

      allMessages.forEach (message) ->
        id = message.get('id')

        if currentBatch.mapBy('id').indexOf(id) == -1 &&
           visibleMessages.mapBy('id').indexOf(id) == -1
          message.unloadRecord()

      currentMessages.forEach (message) ->
        if visibleMessages.indexOf(message) == -1
          currentMessages.removeObject(message)

      visibleMessages.forEach (message, index) ->
        if currentMessages.indexOf(message) == -1
          currentMessages.insertAt(index, message)

      @endPropertyChanges()
