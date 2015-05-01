module.exports = {
  title: "pimatic-sispmctrl device config schemas"
  SispmctlSwitch: {
    title: "SispmctlSwitch config options"
    type: "object"
    extensions: ["xConfirm", "xLink", "xOnLabel", "xOffLabel"]
    properties:
      outletUnit:
        description: "The outlet unit number"
        type: "number"
      device: 
        # If you have more than on device then you can select the device the outlet belons to.
        description: "The device to use. Devices can be listed by \"sudo sispmctl -s\""
        type: "number"
        default: 0
      deviceSerial:
        # If you have more than on device then you gcan select the device by serial the outlet 
        # belons to.
        description: "Can be used instead of device to identify the device by serial number. 
          Devices can be listed by \"sudo sispmctl -s\""
        type: "string"
        required: false
  }

}
