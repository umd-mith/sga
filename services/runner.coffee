JobQueue = require('./job-queue')
Q = require 'q'
redis = require 'redis'
util = require 'util'

jobs = JobQueue.createServer 
  jobQueue: 'jobs'

jobs.on 'echo', (data) -> data

jobs.run()