import "FlowtyDrops"

access(all) fun main(addr: Address): UInt64? {
    let acct = getAuthAccount<auth(Capabilities) &Account>(addr)
    let controllers = acct.capabilities.storage.getControllers(forPath: FlowtyDrops.MinterStoragePath)

    for c in controllers {
        if c.borrowType == Type<&{FlowtyDrops.Minter}>() {
            return c.capabilityID
        }
    }

    return nil
}