import "ContractFactory"
import "ContractFactoryTemplate"
import "OpenEditionTemplate"
import "MetadataViews"
import "OpenEditionInitializer"
import "ContractManager"
import "FungibleToken"
import "FlowToken"

transaction(name: String, params: {String: AnyStruct}, managerInitialTokenBalance: UFix64) {
    prepare(acct: auth(Storage, Capabilities) &Account) {
        if acct.storage.borrow<&AnyResource>(from: ContractManager.StoragePath) == nil {
            let v = acct.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)!
            let tokens <- v.withdraw(amount: managerInitialTokenBalance) as! @FlowToken.Vault

            acct.storage.save(<- ContractManager.createManager(tokens: <-tokens), to: ContractManager.StoragePath)

            acct.capabilities.publish(
                acct.capabilities.storage.issue<&ContractManager.Manager>(ContractManager.StoragePath),
                at: ContractManager.PublicPath
            )
        }

        let manager = acct.storage.borrow<auth(ContractManager.Manage) &ContractManager.Manager>(from: ContractManager.StoragePath)
            ?? panic("manager was not borrowed successfully")
        ContractFactory.createContract(templateType: Type<OpenEditionTemplate>(), acct: manager.borrowContractAccount(), name: name, params: params, initializeIdentifier: Type<OpenEditionInitializer>().identifier)
    }
}