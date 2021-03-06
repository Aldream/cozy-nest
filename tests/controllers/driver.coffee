###
# =================
# Test - driver
# =================
# Testing the drivers Controller.
###

fixturesDriver = require '../fixtures/driver'
fixturesSensor = require '../fixtures/sensor'
fs = require 'fs'
os = require 'os'
copyFile = require('../../server/helpers').copyFile
helpers = require '../helpers'
expect = require('chai').expect

store = {}

describe 'Drivers Controller', ->

    before helpers.clearDB
    before helpers.clearFiles
    before helpers.startServer
    before helpers.makeTestClient

    after  helpers.killServer

    describe 'When we create a Sensor Driver (POST /drivers) as a Coffee script', ->

        driver = fixturesDriver.basicSensorDriver

        it 'should allow requests', (done) ->
            @client.sendFile "drivers", driver.file, done

        it 'should reply with the created Driver', ->
            @body = JSON.parse @body
            
            expect(@err).to.not.exist
            expect(@response.statusCode).to.equal 201
            expect(@body.name).to.equal driver.name
            expect(@body.isSensor).is.true
            expect(@body.isActuator).is.false
            expect(@body.id).to.exist
            store.driverId = @body.id

    describe 'When we try creating a 2nd Driver (POST /drivers) with the same name', ->

        driver = fixturesDriver.basicSensorDriver

        it 'should allow requests', (done) ->
            @client.sendFile "drivers", driver.file, done

        it 'should reply with the previously-created Driver', ->
            @body = JSON.parse @body
            
            expect(@err).to.not.exist
            expect(@response.statusCode).to.equal 202
            expect(@body.id).to.equal store.driverId

    # @todo Test adding with other script formats
    # @todo Test adding incorrect driver (no file, bad syntax, missing methods, ...)
    
    describe 'When we get a Driver (GET /drivers/:id) which exists', ->

        it 'should allow requests', (done) ->
            @client.get "drivers/#{store.driverId}", done

        it 'should reply with the corresponding driver', ->
            expect(@err).to.not.exist
            expect(@body.name).to.equal fixturesDriver.basicSensorDriver.name
            expect(@body.id).to.equal store.driverId

            
    describe 'When we get a Driver (GET /drivers/:id) which doesn\'t exist', ->

        
        it 'should allow requests', (done) ->
            id = store.driverId + 404 # since "store.driverId" is the only correct ID in DB, "store.driverId + 404" is not.
            @client.get "drivers/#{id}", done

        it 'should return an error', ->
            expect(@response.statusCode).to.equal 404
            expect(@body).to.exist
            expect(@body.error).to.equal 'Driver not found'

    describe 'When we update a driver (PUT /drivers/:id)', ->

        it 'should allow requests', (done) ->
            @client.put "drivers/#{store.driverId}", fixturesDriver.validUpdateForTestdriver, done

        it 'should reply with an error (not allowed)', ->
            expect(@response.statusCode).to.equal 401
            expect(@body).to.exist
            expect(@body.error).to.equal 'Drivers can\'t be updated'

    describe 'When we delete a Driver (DELETE /drivers/:id) without devices', ->

        it 'should allow requests', (done) ->
            @client.del "drivers/#{store.driverId}", done

        it 'should return a "success"', ->
            expect(@err).to.not.exist
            expect(@response.statusCode).to.equal 200
            expect(@body.success).to.equal true

        it 'when we try getting the deleted driver (GET /drivers/:id)', (done) ->
            @client.get "drivers/#{store.driverId}", done
            
        it 'should return an error', ->
            expect(@response.statusCode).to.equal 404
            expect(@body).to.exist
            expect(@body.error).to.equal 'Driver not found'

    describe 'When we delete a Driver (DELETE /drivers/:id) with devices still depending on it', ->


        before helpers.createDriver fixturesDriver.basicSensorDriver.file
        before (done) ->
            # We add the driver:
            store.driverId = helpers.getInStore('driver').id
            done null

        before (done) ->
            # We add the depending device:
            sensor = fixturesSensor.supportedSensor1
            sensor.driverId = store.driverId
            helpers.createSensor(sensor) () ->
                store.sensorId = helpers.getInStore('sensor').id
                done null

        it 'should allow requests', (done) ->
            @client.del "drivers/#{store.driverId}", done

        it 'should return an error', ->
            expect(@response.statusCode).to.equal 500
            expect(@body).to.exist
            expect(@body.error).to.equal 'Devices still using this driver'

        it 'when we try deleting the sensor first (DELETE /sensors/:id)', (done) ->
            @client.del "sensors/#{store.sensorId}", done
            
        it '... then the driver (DELETE /drivers/:id)', (done) ->
            @client.del "drivers/#{store.driverId}", done

        it 'should return a "success"', ->
            expect(@err).to.not.exist
            expect(@response.statusCode).to.equal 200
            expect(@body.success).to.equal true

    # @todo Find why required JS drivers are "undefined"
    # describe 'When we create a Sensor Driver (POST /drivers) as a JS script', ->

    #     driver = fixturesDriver.basicSensorDriverJS

    #     before (done) ->
    #         @client.get "drivers/#{store.driverId}", done

    #     it 'should allow requests', (done) ->
    #         @client.sendFile "drivers", driver.file, done

    #     it 'should reply with the created Driver', ->
    #         @body = JSON.parse @body
    #         expect(@err).to.not.exist
    #         expect(@response.statusCode).to.equal 201
    #         expect(@body.name).to.equal driver.name
    #         expect(@body.isSensor).is.true
    #         expect(@body.isActuator).is.false
    #         expect(@body.id).to.exist
    #         store.driverId = @body.id

    describe 'When we create a Sensor Driver (POST /drivers) as a ZIP archive', ->

        driver = fixturesDriver.basicSensorDriverZip

        before (done) ->
            @client.get "drivers/#{store.driverId}", done

        it 'should allow requests', (done) ->
            @client.sendFile "drivers", driver.file, done

        it 'should reply with the created Driver', ->
            @body = JSON.parse @body
            
            expect(@err).to.not.exist
            expect(@response.statusCode).to.equal 201
            expect(@body.name).to.equal driver.name
            expect(@body.isSensor).is.true
            expect(@body.isActuator).is.false
            expect(@body.id).to.exist
            store.driverId = @body.id
