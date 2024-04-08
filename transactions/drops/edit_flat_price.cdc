import "FlowtyDrops"
import "FlowtyPricers"

transaction(dropID: UInt64, phaseIndex: Int, price: UFix64) {
    prepare(acct: AuthAccount) {
        let container = acct.borrow<&FlowtyDrops.Container>(from: FlowtyDrops.ContainerStoragePath)
            ?? panic("container not found")
        let drop = container.borrowDrop(id: dropID) ?? panic("drop not found")
        let phase = drop.borrowPhase(index: phaseIndex)
        let pricer = phase.borrowPricerAuth() as! auth &FlowtyPricers.FlatPrice
        pricer.setPrice(price: price)
    }
}