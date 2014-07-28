'use strict'

describe 'Service: socketService', ->

  # load the service's module
  beforeEach module 'wwwApp'

  # instantiate service
  socketService = {}
  beforeEach inject (_socketService_) ->
    socketService = _socketService_

  it 'should do something', ->
    expect(!!socketService).toBe true
