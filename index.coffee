localtunnel = require 'localtunnel'
commander = require 'commander'
serve = require 'serve-static'
connect = require 'connect'
async = require 'async'
path = require 'path'
fs = require 'fs-extra'

serve = (port, directory)->
  connect()
  .use serve directory
  .listen port, ->
    console.log "Files ready to be handed off. Copy the link below to your friends."
    # localtunnel port, (err, tunnel)->
    #   throw new Error err if err
    #   console.log tunnel.url


main = (port, files)->
  public_path = path.join __dirname, "public"
  src_path = path.join __dirname, "src"
  files = files.concat (path.join src_path, f for f in fs.readdirSync src_path)
  # Create a directory to hold our files
  # Move files into directory
  fs.emptyDir public_path, (err)->
    throw new Error err if err
    async.each files, (file, done)->
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
      serve port, public_path

module.exports = main
