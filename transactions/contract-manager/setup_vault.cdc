import "ContractManager"
import "FungibleToken"

transaction(identifier: String) {
    prepare(acct: auth(BorrowValue) &Account) {
        let manager = acct.storage.borrow<auth(ContractManager.Manage) &ContractManager.Manager>(from: ContractManager.StoragePath)
            ?? panic("manager not found")

        let type = CompositeType(identifier) ?? panic("invalid composite type identifier")
        manager.configureVault(vaultType: type)
    }
}