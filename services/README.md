# JobQueue for node.js

This provides a simple job queue built on top of [Redis](http://redis.io/). It should be easy to implement this in other languages as needed.

## Web Server / Job Client

A simple web service can be used as a job client:

    express = require 'express'
    JobQueue = require('./job-queue')

    app = express()

    app.configure ->
      app.set "port", process.env.PORT or 4000

    jobs = JobQueue.createClient()

    app.get '/echo', (req, res) ->
      # queue the request
      job = jobs.run 'echo',
        request: req.params.q

      # respond to the web client when we get results back
      job = job.then (data) ->
        res.send data.request

      # handle any errors that might come up
      job = job.catch (err) ->
        res.send 'error! ' + JSON.stringify err

      # clean up once everything is handled
      job.done()

    app.listen app.get('port'), ->
      console.log "Listening on port #{app.get('port')}"

## Job Server

Creating a handler for a particular method is fairly easy:

    JobQueue = require('./job-queue')

    jobs = JobQueue.createServer()

    jobs.on 'echo', (data) -> data

    jobs.run()

## Job Messages

Jobs are queued by pushing them onto the left end of a list. The job server listens for changes in the job list and pops them from the right end of the list. Results from running the job are sent back to the client on the pub/sub channel specified in the job packet.

Each job is defined as a JSON string with the following information:

    {
      method: 'name-of-method',
      parameters: /* arbitrary JSON data passed to the method handler */,
      channel: 'name-of-pub/sub-channel-for-results',
      id: 'unique-id-of-job-request'
    }

The `id` of the request needs to be unique only for the requesting job client since each client has its own pub/sub channel for results.

The Redis logic on the job server side (the event loop):

    redisJobClient.brpoplpush 'job-queue', 'job-queue:in-process', 0, (err, job) ->
      # handle job ...
      redisPubClient.publish job.channel, 'results of handling job'
      redisJobClient.lrem 'job-queue:in-process', 0, job

This uses an atomic command in Redis to block until an item is available to right-pop from the jobs queue with an immediate left-push onto the 'job-queue:in-process' queue before returning the job. Once the job is handled, we send the results back to the client by `publish`ing the results. Then, we `lrem` (list/left-remove) the completed job from the 'job-queue:in-process' queue.

This allows us to run through the 'job-queue:in-process' queue if we start up after crashing. This queue should be unique for each processor, but not random. It can be based on the IP address or other reproducible information on the server running the job service.