import "FlowtyDrops"
import "FlowtyAddressVerifiers"

transaction(dropID: UInt64, phaseIndex: Int, maxPerMint: Int) {
    prepare(acct: AuthAccount) {
        let container = acct.borrow<&FlowtyDrops.Container>(from: FlowtyDrops.ContainerStoragePath)
            ?? panic("container not found")
        let drop = container.borrowDrop(id: dropID) ?? panic("drop not found")
        let phase = drop.borrowPhase(index: phaseIndex)
        let v = phase.borrowAddressVerifierAuth() as! auth &FlowtyAddressVerifiers.AllowAll
        v.setMaxPerMint(maxPerMint)
    }
}