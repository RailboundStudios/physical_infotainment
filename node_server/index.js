const noble = require('noble');

noble.startScanning();

while (true) {
  console.log('Scanning...');
}