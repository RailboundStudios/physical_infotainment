from bluepy.btle import Peripheral, UUID, Service, Characteristic, Descriptor

class MyPeripheral(Peripheral):
    def __init__(self):
        Peripheral.__init__(self)

        # Create a service
        service_uuid = UUID("12345678-1234-5678-1234-56789abcdef0")
        service = self.addService(Service(service_uuid))

        # Create a characteristic
        char_uuid = UUID("12345678-1234-5678-1234-56789abcdef1")
        char = service.addCharacteristic(char_uuid,
                                         props=Characteristic.PROP_READ | Characteristic.PROP_WRITE,
                                         perms=Characteristic.PERM_READ | Characteristic.PERM_WRITE)

        # Start the peripheral
        self.advertise("MyBLEPeripheral")

if __name__ == "__main__":
    peripheral = MyPeripheral()
    peripheral.run()
