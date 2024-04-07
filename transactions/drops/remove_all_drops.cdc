import "FlowtyDrops"

transaction {
    prepare(acct: AuthAccount) {
        if let container = acct.borrow<&FlowtyDrops.Container>(from: FlowtyDrops.ContainerStoragePath) {
            for id in container.getIDs() {
                destroy container.removeDrop(id: id)
            }
        }
    }
}