Heap = require 'heap'

###
Stores sockets by their ID for fast lookup. Also uses a priority queue sorted
by time-to-live.

This class will automatically close and remove sockets when they timeout.
###
class EphemeralStorage
  @DEFAULT_TTL_SEC : 600 # 10 minutes

  constructor : (@ttl = EphemeralStorage.DEFAULT_TTL_SEC) ->
    @_map = {}
    @_heap = new Heap((a, b) -> a.ttl - b.ttl)

  reap : =>
    time = new Date().valueOf()

    # Delete entries that have expired
    while true
      top = @_heap.peek()
      break unless top? and top.ttl < time
      @_heap.pop()
      @extract(top.key)?.timeout()

    # Enqueue another call to @reap right after the next entry expires
    if (next = @_heap.peek())?
      if @_lastTimeoutToken? then clearTimeout(@_lastTimeoutToken)
      @_lastTimeoutToken = setTimeout(@reap, next.ttl - time + 5)
    return

  push : (key, entry, ttl) ->
    ttl ?= new Date().valueOf() + (@ttl * 1000)
    @_map[key] = entry
    @_heap.push {key, ttl}

    process.nextTick(@reap)

  extract : (key) ->
    entry = @_map[key]
    if entry? then delete @_map[key]
    # NOTE: We don't bother to remove the entry from the heap at this time since
    # 1) heaps don't do random access, 2) it will eventually be cleaned up by
    # the @reap method, and 3) we clean up the socket when we close it so we
    # won't leak request/response objects
    return entry

module.exports = EphemeralStorage
