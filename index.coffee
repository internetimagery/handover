localtunnel = require 'localtunnel'
commander = require 'commander'
serve = require 'serve-static'
connect = require 'connect'
http = require 'http'
each = require 'async/each'
path = require 'path'
fs = require 'fs-extra'
cheerio = require 'cheerio'
archiver = require 'archiver'

DL_NAME = "dl"
PUBLIC_DIR = path.join __dirname, "public"
DL_DIR = path.join PUBLIC_DIR, DL_NAME
INDEX = path.join PUBLIC_DIR, "index.html"

# Human readable sizing
human_size = (bytes)->
  breakpoint = 1024
  return "#{bytes}B" if Math.abs bytes < breakpoint
  units = ['kB','MB','GB','TB','PB','EB','ZB','YB']
  u = -1
  loop
    bytes /= breakpoint
    u += 1
    break if Math.abs(bytes) < breakpoint or u >= (units.length - 1)
  "#{bytes.toFixed 1} #{units[u]}"

# Start up server to hand out our files!
share = (port, directory, debug, callback)->
  connect()
  .use serve directory
  .listen port, ->
    if debug
      callback null, "http://localhost:#{port}"
    else
      localtunnel port, (err, tunnel)->
        return callback err if err
        callback null, tunnel.url

# Copy files in an efficient way
copy = (src, dest, callback)->
  fs.link src, dest, (err)->
    return callback err if err and err.code not in ["EXDEV","EPERM"]
    if err
      fs.copy src, dest, (err)->
        callback err
    else
      callback()

# Edit our index.html to include download links to our files
add_links = (files, callback)->
  fs.readFile INDEX, "utf8", (err, data)->
    return callback err if err
    try
      $ = cheerio.load data
      list = $ "#list"
      list.empty()
      for f in files
        stats = fs.statSync f
        name = path.basename f
        type = path.extname(f)[1..]
        date = new Date(stats.mtime).toDateString()
        size = human_size stats.size
        html = "<tr onClick='window.location = \"#{f}\";'>
                  <td>#{name}</td>
                  <td>#{type}</td>
                  <td>#{date}</td>
                  <td>#{size}</td>
                </tr>"
        list.append html
      fs.writeFile INDEX, $.html(), "utf8", callback
    catch err
      callback err

main = (port, paths, debug)->
  # Create a directory to hold our files
  # Move files into directory
  fs.emptyDir path.join(PUBLIC_DIR, DL_NAME), (err)->
    throw new Error err if err
    downloads = []
    each paths, (src, done)->
      fs.stat src, (err, stats)->
        return done() if err
        if stats.isFile()
          dest = path.join DL_DIR, path.basename src
          copy src, dest, (err)->
            downloads.push dest
            done err
        else if stats.isDirectory()
          dest = path.join DL_DIR, path.basename(src) + ".zip"
          archive = archiver "zip", {store: true}
          archive.pipe fs.createWriteStream dest
          archive.directory src
          archive.finalize()
          archive.on "error", (err)-> done err
          archive.on "close", ->
            downloads.push dest
            done()
    , (err)->
      throw new Error err if err
      add_links downloads, (err)->
        throw new Error err if err
        share port, PUBLIC_DIR, debug, (err, url)->
          throw new Error err if err
          console.log "Files ready to be handed over. Copy the link below to your friends."
          console.log url

module.exports = main
