localtunnel = require 'localtunnel'
commander = require 'commander'
serve = require 'serve-static'
connect = require 'connect'
http = require 'http'
each = require 'async/each'
path = require 'path'
fs = require 'fs-extra'

# Start up server to hand out our files!
handover = (port, directory, debug)->
  connect()
  .use serve directory
  .listen port, ->
    console.log "Files ready to be handed over. Copy the link below to your friends."
    if debug
      console.log "http://localhost:#{port}"
    else
      localtunnel port, (err, tunnel)->
        throw new Error err if err
        console.log tunnel.url
  .on "close", ->
    console.log "File sharing stopped."

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
        handover port, public_path, debug

module.exports = main
