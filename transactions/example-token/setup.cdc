import "FungibleToken"
import "ExampleToken"

transaction {
    prepare(acct: AuthAccount) {
        if acct.borrow<&ExampleToken.Vault>(from: /storage/exampleTokenVault) == nil {
            acct.save(<-ExampleToken.createEmptyVault(), to: /storage/exampleTokenVault)
        }

        acct.unlink(/public/exampleTokenReceiver)
        acct.unlink(/public/exampleTokenBalance)
        acct.unlink(/private/exampleTokenBalance)
        
        acct.link<&{FungibleToken.Receiver}>(
            /public/exampleTokenReceiver,
            target: /storage/exampleTokenVault
        )

        acct.link<&{FungibleToken.Balance}>(
            /public/exampleTokenBalance,
            target: /storage/exampleTokenVault
        )

        acct.link<&{FungibleToken.Provider, FungibleToken.Balance, FungibleToken.Receiver}>(/private/exampleTokenBalance, target: /storage/exampleTokenVault)
    }
}
 