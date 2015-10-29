// Only require coffeescript if it is not already registered
/* istanbul ignore if  */
if (!require.extensions[".coffee"]) require("coffee-script/register");

module.exports = require("./jwt.coffee");
