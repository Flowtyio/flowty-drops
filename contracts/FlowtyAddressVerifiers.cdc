import "FlowtyDrops"

/*
This contract contains implementations of the FlowtyDrops.AddressVerifier struct interface
*/
pub contract FlowtyAddressVerifiers {
    /*
    The AllowAll AddressVerifier allows any address to mint without any verification
    */
    pub struct AllowAll: FlowtyDrops.AddressVerifier {}

    /*
    The AllowList Verifier only lets a configured set of addresses participate in a drop phase. The number
    of mints per address is specified to allow more granular control of what each address is permitted to do.
    */
    pub struct AllowList: FlowtyDrops.AddressVerifier {
        access(self) let allowedAddresses: {Address: Int}

        pub fun canMint(addr: Address, num: Int, totalMinted: Int, data: {String: AnyStruct}): Bool {
            if let allowedMints = self.allowedAddresses[addr] {
                return allowedMints >= num + totalMinted
            }

            return false
        }

        pub fun remainingForAddress(addr: Address, totalMinted: Int): Int? {
            if let allowedMints = self.allowedAddresses[addr] {
                return allowedMints - totalMinted
            }
            return nil
        }

        pub fun setAddress(addr: Address, value: Int) {
            self.allowedAddresses[addr] = value
        }

        pub fun removeAddress(addr: Address) {
            self.allowedAddresses.remove(key: addr)
        }

        init(allowedAddresses: {Address: Int}) {
            self.allowedAddresses = allowedAddresses
        }
    }
}