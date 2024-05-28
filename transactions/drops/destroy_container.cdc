import "FlowtyDrops"

transaction {
    prepare(acct: auth(LoadValue) &Account) {
        destroy acct.storage.load<@AnyResource>(from: FlowtyDrops.ContainerStoragePath)
    }
}