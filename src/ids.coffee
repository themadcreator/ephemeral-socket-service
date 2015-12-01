crypto = require 'crypto'

module.exports = {
  pattern  : '[0-9a-zA-Z_-]{12}'
  generate : ->
    return crypto.randomBytes(9)
      .toString('base64')
      .replace(/\=/g, '')
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
}
