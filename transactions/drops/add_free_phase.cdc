import "FlowtyDrops"
import "FlowtyPricers"

transaction(dropID: UInt64, start: UInt64?, end: UInt64?) {
    prepare(acct: AuthAccount) {
        let container = acct.borrow<&FlowtyDrops.Container>(from: FlowtyDrops.ContainerStoragePath)
            ?? panic("container not found")
        let drop = container.borrowDrop(id: dropID) ?? panic("drop not found")
        let firstPhase = drop.borrowPhase(index: 0)

        let details = FlowtyDrops.PhaseDetails(switch: firstPhase.details.switch, display: firstPhase.details.display, pricer: FlowtyPricers.Free(), addressVerifier: firstPhase.details.addressVerifier)
        let phase <- FlowtyDrops.createPhase(details: details)

        drop.addPhase(<- phase)
    }
}