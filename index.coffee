localtunnel = require 'localtunnel'
commander = require 'commander'
serve = require 'serve-static'
openpgp = require 'openpgp'
connect = require 'connect'
http = require 'http'
each = require 'async/each'
path = require 'path'
fs = require 'fs-extra'

# openpgp.initWorker {path: "openpgp.worker.min.js"}
#
#
# openpgp.generateKey {
#   userIds: [{name: "me", email:"them@that.com"}]
#   numBits: 4096
# }
# .then (key)->
#   console.log key.privateKeyArmored
#   console.log key.publicKeyArmored

# Start up server to hand out our files!
handover = (port, directory, debug, callback)->
  connect()
  .use serve directory
  .listen port, ->
    if debug
      callback null, "http://localhost:#{port}"
    else
      localtunnel port, (err, tunnel)->
        return callback err if err
        callback null, tunnel.url

# Copy files in the most efficient way
copy = (src, dest, callback)->
  fs.link src, dest, (err)->
    return callback err if err and err.code not in ["EXDEV","EPERM"]
    if err
      fs.copy src, dest, (err)->
        callback err
    else
      callback()

main = (port, files, debug)->
  if files.length
    public_path = path.join __dirname, "public"
    files_path = path.join public_path, "dl"
    # Create a directory to hold our files
    # Move files into directory
    fs.emptyDir files_path, (err)->
      throw new Error err if err
      each files, (src, done)->
        dest = path.join files_path, path.basename src
        copy src, dest, (err)->
          done err
      , (err)->
        throw new Error err if err
        handover port, public_path, debug, (err, url)->
          throw new Error err if err
          console.log "Files ready to be handed over. Copy the link below to your friends."
          console.log url

module.exports = ->
