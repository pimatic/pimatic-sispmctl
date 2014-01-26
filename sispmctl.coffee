module.exports = (env) ->
  convict = env.require "convict"
  Q = env.require 'q'
  assert = env.require 'cassert'

  exec = Q.denodeify(require("child_process").exec)

  class Sispmctl extends env.plugins.Plugin

    init: (app, @framework, config) =>
      conf = convict require("./sispmctl-config-schema")
      conf.load config
      conf.validate()
      @config = conf.get ""
      @checkBinary()

    checkBinary: ->
      exec("#{@config.binary} -v").catch( (error) ->
        if error.message.match "not found"
          env.logger.error "sispmctl binary not found. Check your config!"
      ).done()


    createDevice: (config) =>
      if config.class is "SispmctlSwitch" 
        @framework.registerDevice(new SispmctlSwitch config)
        return true
      return false

  plugin = new Sispmctl

  class SispmctlSwitch extends env.devices.PowerSwitch

    constructor: (config) ->
      conf = convict require("./actuator-config-schema")
      conf.load config
      conf.validate()
      @config = conf.get ""

      @name = config.name
      @id = config.id
      super()

    getState: () ->
      if @_state? then return Q @_state
      # Built the sispmctrl command to get the outlet status
      command = "#{plugin.config.binary} -q -n" # quiet and numerical
      command += " -d #{@config.device}" # select the device
      command += " -g #{@config.outletUnit}" # get status of the outlet
      # and execue it.
      return exec(command).then( (streams) =>
        stdout = streams[0]
        stderr = streams[1]
        stdout = stdout.trim()
        switch stdout
          when "1"
            @_state = on
            return Q @_state
          when "0"
            @_state = off
            return Q @_state
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
      return exec(command).then( (streams) =>
        stdout = streams[0]
        stderr = streams[1]
        env.logger.debug stderr if stderr.length isnt 0
        @_setState(state)
      )

  return plugin