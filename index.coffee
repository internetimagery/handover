localtunnel = require 'localtunnel'
commander = require 'commander'
serve = require 'serve-static'
connect = require 'connect'
http = require 'http'
each = require 'async/each'
path = require 'path'
fs = require 'fs-extra'

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

main = (port, files, debug)->
  if files.length
    public_path = path.join __dirname, "public"
    src_path = path.join __dirname, "src"
    files = files.concat (path.join src_path, f for f in fs.readdirSync src_path)
    # Create a directory to hold our files
    # Move files into directory
    fs.emptyDir public_path, (err)->
      throw new Error err if err
      each files, (file, done)->
        dest = path.join public_path, path.basename file
        fs.link file, dest, (err)->
          return done err if err and err.code != "EXDEV"
          if err
            fs.copy file, dest, (err)->
              done err
          else
            done()
      , (err)->
        throw new Error err if err
        handover port, public_path, debug

module.exports = main
