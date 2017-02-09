commander = require 'commander'
fs = require 'fs'
path = require 'path'
meta = require "./package.json"
handover = require './index'
main = ->
  # Lets go!
  commander
  .version meta.version
  .description "Pick a file or files, gain a link to share them."
  .option "-p, --port <port>", "Port to use"
  .arguments "<file...>"
  .action (files, env)->
    env.port ?= 8080
    paths = (path.resolve f for f in files)
    handover env.port, (p for p in paths when fs.existsSync p)
  .parse process.argv

module.exports = main
