localtunnel = require 'localtunnel'
commander = require 'commander'
serve = require 'serve-static'
connect = require 'connect'
http = require 'http'
path = require 'path'
fs = require 'fs-extra'
cheerio = require 'cheerio'
archiver = require 'archiver'
Password = require 'xkcd-password'
Promise = require 'promise'
words = require './words'

DL_NAME = "dl"
PUBLIC_DIR = path.join __dirname, "public"
DL_DIR = path.join PUBLIC_DIR, DL_NAME
INDEX = path.join PUBLIC_DIR, "index.html"

emptyDir = Promise.denodeify fs.emptyDir
each = Promise.denodeify require "async/each"
readFile = Promise.denodeify fs.readFile
writeFile = Promise.denodeify fs.writeFile
link = Promise.denodeify fs.link
copy = Promise.denodeify fs.copy
stats = Promise.denodeify fs.stat

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
share = (port, directory, debug)->
  pw = new Password()
  pw.initWithWordList words
  pw.generate {numWords: 2}
  .then (xkcd)->
    new Promise (ok, fail)->
      connect()
      .use serve directory
      .listen port, {subdomain: xkcd.join "-"}, ->
        return ok "http://localhost:#{port}" if debug
        localtunnel port, (err, tunnel)->
          if err then fail() else ok tunnel.url
  .catch (err)->
    throw new Error err

# Copy files in an efficient way
dupe = (src, dest)->
  link src, dest
  .catch (err)->
    throw new Error err if err.code not in ["EXDEV","EPERM"]
    copy src, dest

# Edit our index.html to include download links to our files
add_links = (files)->
  $ = null
  readFile INDEX, "utf8"
  .then (data)->
    $ = cheerio.load data
    list = $ "#list"
    list.empty()
    for f in files
      stats = fs.statSync f
      name = path.basename f
      type = path.extname(f)[1..]
      date = new Date(stats.mtime).toDateString()
      size = human_size stats.size
      html = "<tr onClick='window.location = \"#{DL_NAME}/#{name}\";'>
                <td>#{name}</td>
                <td>#{type}</td>
                <td>#{date}</td>
                <td>#{size}</td>
              </tr>"
      list.append html
  .then ->
    writeFile INDEX, $.html(), "utf8"



main = (port, paths, debug)->
  # Create a directory to hold our files
  # Move files into directory
  downloads = []
  emptyDir DL_DIR
  .then ->
    each paths, (src, done)->
      stats src
      .then (st)->
        if st.isFile()
          dest = path.join DL_DIR, path.basename src
          dupe src, dest
          .then ->
            downloads.push dest
            done()
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
      .catch -> done()
  .then ->
    add_links downloads
  .then ->
    share port, PUBLIC_DIR, debug
  .then (url)->
    console.log "Files ready to be handed over. Copy the link below to your friends."
    console.log url
  .catch (err)->
    throw new Error err

module.exports = main
