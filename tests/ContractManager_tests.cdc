import Test
import "./test_helpers.cdc"
import "ContractManager"

access(all) fun setup() {
    deployAll()
}

access(all) fun test_SetupContractManager() {
    let acct = Test.createAccount()
    mintFlowTokens(acct, 10.0)

    txExecutor("contract-manager/setup.cdc", [acct], [1.0])

    let savedEvent = Test.eventsOfType(Type<ContractManager.ManagerSaved>()).removeLast() as! ContractManager.ManagerSaved
    Test.assertEqual(acct.address, savedEvent.ownerAddress)
}