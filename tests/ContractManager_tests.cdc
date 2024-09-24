import Test
import "./test_helpers.cdc"
import "ContractManager"
import "HybridCustody"
import "FungibleToken"

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

access(all) fun test_SetupContractManager_CanWithdrawTokens() {
    let acct = Test.createAccount()
    mintFlowTokens(acct, 10.0)

    let amount = 5.0
    txExecutor("contract-manager/setup.cdc", [acct], [amount])
    let savedEvent = Test.eventsOfType(Type<ContractManager.ManagerSaved>()).removeLast() as! ContractManager.ManagerSaved
    let contractAddress = savedEvent.contractAddress

    // make sure there is a HybridCustody.AccountUpdated event
    let updatedEvent = Test.eventsOfType(Type<HybridCustody.AccountUpdated>()).removeLast() as! HybridCustody.AccountUpdated
    Test.assertEqual(acct.address, updatedEvent.parent!)
    Test.assertEqual(contractAddress, updatedEvent.child)
    Test.assertEqual(true, updatedEvent.active)

    // withdraw and destroy 1 token to prove we are able to access an account's tokens
    let controllerId = scriptExecutor("util/get_withdraw_controller_id.cdc", [contractAddress, /storage/flowTokenVault])! as! UInt64
    txExecutor("flow-token/withdraw_tokens.cdc", [acct], [amount, controllerId])

    let withdrawEvent = Test.eventsOfType(Type<FungibleToken.Withdrawn>()).removeLast() as! FungibleToken.Withdrawn
    Test.assertEqual(amount, withdrawEvent.amount)
    Test.assertEqual(contractAddress, withdrawEvent.from!)

    let depositEvent = Test.eventsOfType(Type<FungibleToken.Deposited>()).removeLast() as! FungibleToken.Deposited
    Test.assertEqual(amount, depositEvent.amount)
    Test.assertEqual(acct.address, depositEvent.to!)
}