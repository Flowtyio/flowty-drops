import "FlowToken"
import "FungibleToken"
import "FungibleTokenSwitchboard"

access(all) contract ContractManager {
    access(all) let StoragePath: StoragePath
    access(all) let PublicPath: PublicPath

    access(all) entitlement Manage

    access(all) resource Manager {
        access(self) let acct: Capability<auth(Storage, Contracts, Keys, Inbox, Capabilities) &Account>
        access(self) let switchboardCap: Capability<auth(FungibleTokenSwitchboard.Owner) &FungibleTokenSwitchboard.Switchboard>

        access(Manage) fun borrowContractAccount(): auth(Contracts) &Account {
            return self.acct.borrow()!
        }

        access(Manage) fun addFungibleTokenReceiver(_ cap: Capability<&{FungibleToken.Receiver}>) {
            pre {
                cap.check(): "capability is not valid"
            }

            let switchboard = self.switchboardCap.borrow() ?? panic("fungible token switchboard is not valid")
            switchboard.addNewVault(capability: cap)
        }

        access(Manage) fun getSwitchboard(): auth(FungibleTokenSwitchboard.Owner) &FungibleTokenSwitchboard.Switchboard {
            return self.switchboardCap.borrow()!
        }

        access(all) fun addFlowTokensToAccount(_ tokens: @FlowToken.Vault) {
            self.acct.borrow()!.storage.borrow<&{FungibleToken.Receiver}>(from: /storage/flowTokenVault)!.deposit(from: <-tokens)
        }

        access(all) fun getAccount(): &Account {
            return getAccount(self.acct.address)
        }

        init(tokens: @FlowToken.Vault) {
            pre {
                tokens.balance >= 0.001: "minimum balance of 0.001 required for initialization"
            }

            let acct = Account(payer: ContractManager.account)
            self.acct = acct.capabilities.account.issue<auth(Storage, Contracts, Keys, Inbox, Capabilities) &Account>()
            assert(self.acct.check(), message: "failed to setup account capability")

            acct.storage.borrow<&{FungibleToken.Receiver}>(from: /storage/flowTokenVault)!.deposit(from: <-tokens)

            let switchboard <- FungibleTokenSwitchboard.createSwitchboard()
            acct.storage.save(<-switchboard, to: FungibleTokenSwitchboard.StoragePath)

            let receiver = acct.capabilities.storage.issue<&{FungibleToken.Receiver}>(FungibleTokenSwitchboard.StoragePath)
            assert(receiver.check(), message: "invalid switchboard receiver capability")
            acct.capabilities.publish(receiver, at: FungibleTokenSwitchboard.ReceiverPublicPath)

            acct.capabilities.publish(
                acct.capabilities.storage.issue<&FungibleTokenSwitchboard.Switchboard>(FungibleTokenSwitchboard.StoragePath),
                at: FungibleTokenSwitchboard.PublicPath
            )

            self.switchboardCap = acct.capabilities.storage.issue<auth(FungibleTokenSwitchboard.Owner) &FungibleTokenSwitchboard.Switchboard>(FungibleTokenSwitchboard.StoragePath)
        }
    }

    access(all) fun createManager(tokens: @FlowToken.Vault): @Manager {
        return <- create Manager(tokens: <- tokens)
    }

    init() {
        let identifier = "ContractManager_".concat(self.account.address.toString())
        self.StoragePath = StoragePath(identifier: identifier)!
        self.PublicPath = PublicPath(identifier: identifier)!
    }
}