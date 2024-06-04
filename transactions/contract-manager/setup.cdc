import "ContractManager"
import "FlowToken"
import "FungibleToken"

transaction(flowTokenAmount: UFix64) {
    prepare(acct: auth(Storage, Capabilities) &Account) {
        let v = acct.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)!
        let tokens <- v.withdraw(amount: flowTokenAmount) as! @FlowToken.Vault

        acct.storage.save(<- ContractManager.createManager(tokens: <-tokens), to: ContractManager.StoragePath)
    }
}