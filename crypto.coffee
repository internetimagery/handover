# TODO: Add some secure options by encrypting the file, and decrypting it in the browser on the other side.

openpgp = require 'openpgp'

openpgp.initWorker {path: "openpgp.worker.min.js"}


openpgp.generateKey {
  userIds: [{name: "me", email:"them@that.com"}]
  numBits: 4096
}
.then (key)->
  console.log key.privateKeyArmored
  console.log key.publicKeyArmored
