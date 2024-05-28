import "FlowtyDrops"
import "FlowtySwitchers"

transaction(dropID: UInt64, phaseIndex: Int, start: UInt64?, end: UInt64?) {
    prepare(acct: auth(BorrowValue) &Account) {
        let container = acct.storage.borrow<auth(FlowtyDrops.Owner) &FlowtyDrops.Container>(from: FlowtyDrops.ContainerStoragePath)
            ?? panic("container not found")
        let drop = container.borrowDrop(id: dropID) ?? panic("drop not found")
        let phase = drop.borrowPhase(index: phaseIndex)

        let tmp = phase.borrowSwitchAuth()
        let s = tmp as! auth(Mutate) &FlowtySwitchers.TimestampSwitch

        s.setStart(start: start)
        s.setEnd(end: end)
    }
}