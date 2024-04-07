import "FungibleToken"

transaction(to: Address, amount: UFix64) {
    prepare(acct: AuthAccount) {
        let receiver = getAccount(to).getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
            .borrow() ?? panic("receiver not found")
        
        let provider = acct.borrow<&{FungibleToken.Provider}>(from: /storage/flowTokenVault)!
        let tokens <- provider.withdraw(amount: amount)
        receiver.deposit(from: <-tokens)
    }
}