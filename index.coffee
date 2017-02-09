localtunnel = require 'localtunnel'
commander = require 'commander'
serve = require 'serve-static'
connect = require 'connect'
path = require 'path'
fs = require 'fs-extra'

main = (port, files)->
  console.log "hi", files

module.exports = main
