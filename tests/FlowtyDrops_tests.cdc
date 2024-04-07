import Test
import "test_helpers.cdc"
import "FlowToken"
import "FlowtyDrops"

pub let defaultEndlessOpenEditionName = "Default Endless Open Edition"

pub fun setup() {
    deployAll()
}

pub fun afterEach() {
    txExecutor("drops/remove_all_drops.cdc", [openEditionAccount], [], nil, nil)
}

pub fun testImports() {
    Test.assert(scriptExecutor("import_all.cdc", [])! as! Bool, message: "failed to import all")
}

pub fun test_OpenEditionNFT_getPrice() {
    let minter = Test.createAccount()

    let dropID = createDefaultEndlessOpenEditionDrop()
    let price = getPriceAtPhase(
        contractAddress: openEditionAccount.address, contractName: "OpenEditionNFT", dropID: dropID, phaseIndex: 0, minter: minter.address, numToMint: 1, paymentIdentifier: Type<@FlowToken.Vault>().identifier
    )
    Test.assertEqual(1.0, price)

    let priceMultiple = getPriceAtPhase(
        contractAddress: openEditionAccount.address, contractName: "OpenEditionNFT", dropID: dropID, phaseIndex: 0, minter: minter.address, numToMint: 10, paymentIdentifier: Type<@FlowToken.Vault>().identifier
    )
    Test.assertEqual(10.0, priceMultiple)
}

pub fun test_OpenEditionNFT_getDetails() {
    let dropID = createDefaultEndlessOpenEditionDrop()
    let details = getDropDetails(contractAddress: openEditionAccount.address, contractName: "OpenEditionNFT", dropID: dropID)
    Test.assertEqual(details.display.name, defaultEndlessOpenEditionName)
}

// ------------------------------------------------------------------------
//                      Helper functions section

pub fun createDefaultEndlessOpenEditionDrop(): UInt64 {
    return  createEndlessOpenEditionDrop(
        acct: openEditionAccount,
        name: "Default Endless Open Edition",
        description: "This is a placeholder description",
        ipfsCid: "1234",
        ipfsPath: nil,
        price: 1.0,
        paymentIdentifier: Type<@FlowToken.Vault>().identifier,
        minterPrivatePath: FlowtyDrops.MinterPrivatePath
    )
}

pub fun getPriceAtPhase(contractAddress: Address, contractName: String, dropID: UInt64, phaseIndex: Int, minter: Address, numToMint: Int, paymentIdentifier: String): UFix64 {
    return scriptExecutor("get_price_at_phase.cdc", [contractAddress, contractName, dropID, phaseIndex, minter, numToMint, paymentIdentifier])! as! UFix64
}

pub fun getDropDetails(contractAddress: Address, contractName: String, dropID: UInt64): FlowtyDrops.DropDetails {
    return scriptExecutor("get_drop_details.cdc", [contractAddress, contractName, dropID])! as! FlowtyDrops.DropDetails
}