pimatic sispmctl plugin
=======================
Backend for the [SIS-PM Control for Linux aka sispmct](http://sispmctl.sourceforge.net/) 
application that can control GEMBIRD (m)SiS-PM device, witch are USB controlled multiple socket.

Configuration
-------------
You can load the plugin by editing your `config.json` to include:

    { 
       "plugin": "sispmctl"
    }

in the `plugins` section. For all configuration options see 
[sispmctl-config-schema](sispmctl-config-schema.html)

Actuators can be defined by adding them to the `devices` section in the config file.
Set the `class` attribute to `SispmctlSwitch`. For example:

    { 
      "id": "light",
      "class": "SispmctlSwitch", 
      "name": "Lamp",
      "outletUnit": 1 
    }

For device configuration options see the [device-config-schema](device-config-schema.html) file.