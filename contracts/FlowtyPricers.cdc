import "FlowtyDrops"
import "FlowToken"

/*
This contract contains implementations of the FlowtyDrops.Pricer interface.
You can use these, or any custom implementation for the phases of your drop.
*/
pub contract FlowtyPricers {

    /*
    The FlatPrice Pricer implementation has a set price and token type. Every mint is the same cost regardless of
    the number minter, or what address is minting
    */
    pub struct FlatPrice: FlowtyDrops.Pricer {
        pub let price: UFix64
        pub let paymentTokenType: Type

        pub fun getPrice(num: Int, minter: Address): UFix64 {
            return self.price * UFix64(num)
        }

        pub fun getPaymentType(): Type {
            return self.paymentTokenType
        }

        init(price: UFix64, paymentTokenType: Type) {
            self.price = price
            self.paymentTokenType = paymentTokenType
        }
    }

    /*
    The Free Pricer can be used for a free mint, it has no price and always marks its payment type as @FlowToken.Vault
    */
    pub struct Free: FlowtyDrops.Pricer {
        pub fun getPrice(num: Int, minter: Address): UFix64 {
            return 0.0
        }

        pub fun getPaymentType(): Type {
            return Type<@FlowToken.Vault>()
        }
    }
}