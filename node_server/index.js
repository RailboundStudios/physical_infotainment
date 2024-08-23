const bleno = require("bleno");

bleno.on("stateChange", (state) => {
   if (state === "poweredOn") {
      bleno.startAdvertising("Pi Infotainment", ["12ab"]);
   } else {
        bleno.stopAdvertising();
   }
});