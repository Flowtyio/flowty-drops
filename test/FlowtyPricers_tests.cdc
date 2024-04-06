import Test
import "test_helpers.cdc"
import "FlowtyPricers"

import "FlowToken"

pub let placeholder = Test.createAccount()

pub fun setup() {
    deployAll()
}

pub fun test_importAll() {
    scriptExecutor("import_all.cdc", [])
}

pub fun test_FlowtyPricers_FlatPrice() {
    let price = 1.1
    let pricer = FlowtyPricers.FlatPrice(price: price, paymentTokenType: Type<@FlowToken.Vault>())

    Test.assertEqual(pricer.getPaymentType(), Type<@FlowToken.Vault>())

    let num = 2
    let cost = pricer.getPrice(num: num, minter: placeholder.address)
    Test.assertEqual(cost, price * UFix64(num))
}

pub fun test_FlowtyPricers_Free() {
    let pricer = FlowtyPricers.Free()
    Test.assertEqual(0.0, pricer.getPrice(num: 5, minter: placeholder.address))
}