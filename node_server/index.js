const bleno = require("bleno");

function runCommand(command) {
    // todo run command
    console.log("Running command: " + command);
}

bleno.on("stateChange", (state) => {
   if (state === "poweredOn") {
      bleno.startAdvertising("Pi Infotainment", ["1803"]);
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