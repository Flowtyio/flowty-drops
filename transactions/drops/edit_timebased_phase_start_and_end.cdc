import "FlowtyDrops"
import "FlowtySwitchers"

transaction(dropID: UInt64, phaseIndex: Int, start: UInt64?, end: UInt64?) {
    prepare(acct: AuthAccount) {
        let container = acct.borrow<&FlowtyDrops.Container>(from: FlowtyDrops.ContainerStoragePath)
            ?? panic("container not found")
        let drop = container.borrowDrop(id: dropID) ?? panic("drop not found")
        let phase = drop.borrowPhase(index: phaseIndex)
        let s = phase.borrowSwitchAuth() as! auth &FlowtySwitchers.TimestampSwitch

        s.setStart(start: start)
        s.setEnd(end: end)
    }
}