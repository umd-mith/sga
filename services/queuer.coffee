
express = require 'express'
JobQueue = require('./job-queue')

app = express()

app.configure ->
  app.set "port", process.env.PORT or 4000

jobs = JobQueue.createClient
  jobQueue: 'jobs'

app.get '/search', (req, res) ->
  # queue the request
  job = jobs.run 'echo',
    request: 'echo something'

  job = job.then (data) ->
    res.send 'results: ' + JSON.stringify data

  job.catch (err) ->
    res.send 'error! ' + JSON.stringify err

app.listen app.get('port'), ->
  console.log "Listening on port #{app.get('port')}"