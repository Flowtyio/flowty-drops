import "FlowtyDrops"
import "FlowtyPricers"

transaction(dropID: UInt64, start: UInt64?, end: UInt64?) {
    prepare(acct: AuthAccount) {
        let container = acct.borrow<&FlowtyDrops.Container>(from: FlowtyDrops.ContainerStoragePath)
            ?? panic("container not found")
        let drop = container.borrowDrop(id: dropID) ?? panic("drop not found")
        let firstPhase = drop.borrowPhase(index: 0)

        let details = FlowtyDrops.PhaseDetails(switcher: firstPhase.details.switcher, display: firstPhase.details.display, pricer: FlowtyPricers.Free(), addressVerifier: firstPhase.details.addressVerifier)

        let phases = drop.borrowAllPhases()
        destroy drop.removePhase(index: phases.length - 1)
    }
}