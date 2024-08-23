const bleno = require("bleno");

function runCommand(String command) {
    // todo run command
}

bleno.on("stateChange", (state) => {
   if (state === "poweredOn") {
      bleno.startAdvertising("Pi Infotainment", ["12ab"]);
   } else {
        bleno.stopAdvertising();
   }

   // Receive command
    bleno.on("accept", (clientAddress) => {
         console.log("Accepted connection from: " + clientAddress);
         bleno.on("data", (data) => {
              console.log("Received data: " + data);
              runCommand(data);
         });
    });
});