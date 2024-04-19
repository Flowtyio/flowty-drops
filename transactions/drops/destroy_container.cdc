import "FlowtyDrops"

transaction {
    prepare(acct: AuthAccount) {
        destroy acct.load<@AnyResource>(from: FlowtyDrops.ContainerStoragePath)
    }
}