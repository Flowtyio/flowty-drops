import Test
import "./test_helpers.cdc"

access(all) fun setup() {
    deployAll()
}

access(all) fun test_SetupContractManager() {
    let acct = Test.createAccount()

    txExecutor("contract-manager/setup.cdc", [acct], [])
}