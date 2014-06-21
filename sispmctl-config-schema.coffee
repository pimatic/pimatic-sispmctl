# #sispmctl configuration options
module.exports = {
  title: "sispmctl config"
  type: "object"
  properties:
    binary:
      description: "The path to the sispmctl command"
      type: "string"
      default: "sispmctl"
}
