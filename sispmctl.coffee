module.exports = (env) ->
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  _ = env.require 'lodash'

  exec = Promise.promisify(require("child_process").exec)
  settled = (promise) -> Promise.settle([promise])

  class Sispmctl extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      # lastAction is a promise for the last/current sispmctrl call, wel always chain on
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
      return @_lastAction = settled(@_lastAction).then( => exec(command) )


  plugin = new Sispmctl

  class SispmctlSwitch extends env.devices.PowerSwitch

    constructor: (@config) ->
      @name = config.name
      @id = config.id
      super()

    getState: () ->
      if @_state? then return Promise.resolve @_state
      # Built the sispmctrl command to get the outlet status
      command = "#{plugin.config.binary} -q -n" # quiet and numerical
      command += " -d #{@config.device}" # select the device
      command += " -g #{@config.outletUnit}" # get status of the outlet
      # and execue it.
      return plugin.exec(command,  (streams) =>
        stdout = streams[0]
        stderr = streams[1]
        stdout = stdout.trim()
        switch stdout
          when "1"
            @_state = on
            return Promise.resolve @_state
          when "0"
            @_state = off
            return Promise.resolve @_state
          else 
            env.logger.debug stderr
            throw new Error "SispmctlSwitch: unknown state=\"#{stdout}\"!"
      )
        

    changeStateTo: (state) ->
      if @state is state then return
      # Built the sispmctrl command
      command = "#{plugin.config.binary}"
      command += " -d #{@config.device}" # select the device
      command += " " + (if state then "-o" else "-f") # do on or off
      command += " " + @config.outletUnit # select the outlet
      # and execue it.
      return plugin.exec(command).then( (streams) =>
        stdout = streams[0]
        stderr = streams[1]
        env.logger.debug stderr if stderr.length isnt 0
        @_setState(state)
      )

  return plugin