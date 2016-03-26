module.exports = (env) ->
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  _ = env.require 'lodash'
  child_process = require("child_process")

  exec = (command) ->
    return new Promise( (resolve, reject) ->
      child_process.exec(command, (err, stdout, stderr) ->
        if err then return reject(err)
        return resolve({stdout: stdout.toString(), stderr: stderr.toString()})
      )
    )
  settled = (promise) -> Promise.settle([promise])

  class Sispmctl extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      # lastAction is a promise for the last/current sispmctl call, wel always chain on
      # this so that sispmctl gets never called while its already running.
      @_lastAction = @checkBinary()
      @_lastAction.done()
      deviceConfigDef = require("./device-config-schema")
      @framework.deviceManager.registerDeviceClass("SispmctlSwitch", {
        configDef: deviceConfigDef.SispmctlSwitch, 
        createCallback: (config) => new SispmctlSwitch(config)
      })

    checkBinary: ->
      return exec("#{@config.binary} -v").catch( (error) ->
        if error.message.match "not found"
          env.logger.error "sispmctl binary not found. Check your config!"
      )

    exec: (command) ->
      @_lastAction = settled(@_lastAction).then( -> exec(command) )
      return @_lastAction


  plugin = new Sispmctl

  class SispmctlSwitch extends env.devices.PowerSwitch

    constructor: (@config) ->
      @name = @config.name
      @id = @config.id
      super()
      @_updateStatus() if @config.interval > 0

    _updateStatus: () ->
      setTimeout () =>
        @_getState()
        .catch (error) =>
          env.logger.error error.message ? error
        .finally () =>
          @_updateStatus()
      , @config.interval

    _getState: () ->
      # Build the sispmctl command to get the outlet status
      command = "#{plugin.config.binary} -q -n" # quiet and numerical
      if @config.deviceSerial?
        command += " -D #{@config.deviceSerial}" # select the device
      else
        command += " -d #{@config.device}" # select the device
      command += " -g #{@config.outletUnit}" # get status of the outlet
      # and execute it.
      env.logger.debug("executing #{command}") if plugin.config.debug
      return plugin.exec(command).then( ({stdout, stderr}) =>
        stdout = stdout.trim()
        env.logger.debug "stdout \"#{stdout}\", stderror: \"#{stderr}\"" if stderr.length isnt 0
        switch stdout
          when "1"
            @_setState(on)
            return Promise.resolve @_state
          when "0"
            @_setState(off)
            return Promise.resolve @_state
          else 
            env.logger.debug stderr
            throw new Error "SispmctlSwitch: unknown state=\"#{stdout}\"!"
      )

    getState: () ->
      if @_state?
        return Promise.resolve @_state
      else
        return @_getState()

    changeStateTo: (state) ->
      if @state is state then return
      # Build the sispmctl command
      command = "#{plugin.config.binary}"
      if @config.deviceSerial?
        command += " -D #{@config.deviceSerial}" # select the device
      else
        command += " -d #{@config.device}" # select the device
      command += " " + (if state then "-o" else "-f") # do on or off
      command += " " + @config.outletUnit # select the outlet
      # and execute it.
      env.logger.debug("executing #{command}") if plugin.config.debug
      return plugin.exec(command).then( ({stdout, stderr}) =>
        env.logger.debug "stdout \"#{stdout}\", stderror: \"#{stderr}\"" if stderr.length isnt 0
        @_setState(state)
      )

  return plugin