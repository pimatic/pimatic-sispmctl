module.exports = {
  title: "pimatic-sispmctl device config schemas"
  SispmctlSwitch: {
    title: "SispmctlSwitch config options"
    type: "object"
    extensions: ["xConfirm", "xLink", "xOnLabel", "xOffLabel"]
    properties:
      outletUnit:
        description: "The outlet unit number"
        type: "number"
      device: 
        # If you have more than on device then you can select the device the outlet belongs to.
        description: "The device to use. Devices can be listed by \"sudo sispmctl -s\""
        type: "number"
        default: 0
      deviceSerial:
        # If you have more than on device then you can select the device by serial the outlet
        # belongs to.
        description: "Can be used instead of device to identify the device by serial number. 
          Devices can be listed by \"sudo sispmctl -s\""
        type: "string"
        required: false
      interval:
        description: "Polling interval in ms for reading the switch state. If 0, no polling is performed"
        type: "number"
        default: 0
  }
}
