###

  job record is represented as serialized JSON
    {
      method: '...',
      parameters: '...',
      channel: '...', // the pub/sub channel through which the results should be sent 
      id: '...', // unique id from the perspective of the return queue 
    }

###

uuid  = require 'node-uuid'
Q     = require 'q'
redis = require 'redis'

class JobQueueClient
  constructor: (config) -> #@client, @jobQueue, @uuidGen = uuid.v1) ->
    @jobQueue = config.jobQueue or 'jobs'
    @jobClient = redis.createClient()
    @subClient = redis.createClient()
    @uuidGen = config.uuidGen or uuid.v1
    @reQueue = @uuidGen()
    @pendingJobs = {}
    @subClient.subscribe @reQueue
    @subClient.on 'message', (channel, message) =>
      if channel == @reQueue
        data = JSON.parse message
        if @pendingJobs[data.id]?
          if data.success
            @pendingJobs[data.id].resolve data.data
          else
            @pendingJobs[data.id].reject data.error
          delete @pendingJobs[data.id]

  end: ->
    @subClient.unsubscribe()
    @subClient.end()
    @jobClient.end()
    for job in @pendingJobs
      @pendingJobs.reject new Error 'Client closed while job was pending'

  run: (method, parameters) ->
    id = @uuidGen()
    @pendingJobs[id] = Q.defer()

    msg = JSON.stringify
      channel: @reQueue
      method: method
      parameters: parameters
      id: id
    console.log "queuing #{msg}"
    @jobClient.lpush [@jobQueue, msg], ->

    @pendingJobs[id].promise

class JobQueueServer
  constructor: (config) -> #(@client, @jobQueue) ->
    @jobQueue = config.jobQueue or 'jobs'
    @inProcessQueue = '#{@jobQueue}:in-process'
    @jobClient = redis.createClient()
    @pubClient = redis.createClient()
    @handlers = {}
    @counter = 0

  on: (method, handler) ->
    @handlers[method] = handler
    @

  run: ->
    handleJob = (job) =>
      console.log "   job #{@counter}: #{job}"
      data = JSON.parse job
      if @handlers[data.method]?
        promise = Q @handlers[data.method](data.parameters)
        promise = promise.then (result) =>
          @pubClient.publish data.channel, JSON.stringify({ success: true, data: result, id: data.id })
        promise = promise.catch (err) =>
          @pubClient.publish data.channel, JSON.stringify({ success: false, error: err, id: data.id })
        promise = promise.finally () =>
          @jobClient.lrem @inProcessQueue, 0, job
        promise.done()
      else
        @pubClient.publish data.channel, JSON.stringify({ success: false, error: "Unknown method", id: data.id })


    eventLoop = =>
      #setTimeout eventLoop, 100
      @jobClient.brpoplpush @jobQueue, @inProcessQueue, 0, (err, job) =>
        @counter += 1
        handleJob job
        setTimeout eventLoop, 0
    eventLoop()


module.exports =
  createClient: (args...) -> new JobQueueClient args...
  createServer: (args...) -> new JobQueueServer args...