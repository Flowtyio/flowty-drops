import "FungibleToken"
import "MetadataViews"

import "FlowtyDrops"
import "FlowtySwitches"
import "FlowtyAddressVerifiers"
import "FlowtyPricers"

/*
The DropFactory is a contract that helps create common types of drops
*/
pub contract DropFactory {
    pub fun createEndlessOpenEditionDrop(
        price: UFix64,
        paymentTokenType: Type,
        dropDisplay: MetadataViews.Display,
        minterCap: Capability<&{FlowtyDrops.Minter}>
    ): @FlowtyDrops.Drop {
        pre {
            paymentTokenType.isSubtype(of: Type<@FungibleToken.Vault>()): "paymentTokenType must be a FungibleToken"
        }

        // This drop is always on and never ends.
        let switch = FlowtySwitches.AlwaysOn()

        // All addresses are allowed to participate
        let addressVerifier = FlowtyAddressVerifiers.AllowAll()

        // The cost of each mint is the same, and only permits one token type as payment
        let pricer = FlowtyPricers.FlatPrice(price: price, paymentTokenType: paymentTokenType)
        
        let phaseDetails = FlowtyDrops.PhaseDetails(switch: switch, display: nil, pricer: pricer, addressVerifier: addressVerifier)
        let phase <- FlowtyDrops.createPhase(details: phaseDetails)

        let dropDetails = FlowtyDrops.DropDetails(display: dropDisplay, medias: nil, commissionRate: 0.05)
        let drop <- FlowtyDrops.createDrop(details: dropDetails, minterCap: minterCap, phases: <- [<-phase])

        return <- drop
    }
}