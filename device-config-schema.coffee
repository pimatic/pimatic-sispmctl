module.exports =
  SispmctlSwitch:
    outletUnit:
      description: "The outlet unit number"
      type: "number"
    device: 
      # If you have more than on device then you gan select the device the outlet belons to.
      description: "The device to use. Devices can be listed by \"sudo sispmctl -s\""
      type: "number"
      default: 0