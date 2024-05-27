import Test
import "test_helpers.cdc"
import "FlowToken"
import "FlowtyDrops"
import "OpenEditionNFT"
import "ExampleToken"
import "DropTypes"

access(all) let defaultEndlessOpenEditionName = "Default Endless Open Edition"

access(all) fun setup() {
    deployAll()
}

access(all) fun afterEach() {
    txExecutor("drops/remove_all_drops.cdc", [openEditionAccount], [], nil, nil)
}

access(all) fun testImports() {
    Test.assert(scriptExecutor("import_all.cdc", [])! as! Bool, message: "failed to import all")
}

access(all) fun test_OpenEditionNFT_getPrice() {
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

access(all) fun test_OpenEditionNFT_getDetails() {
    let dropID = createDefaultEndlessOpenEditionDrop()
    let details = getDropDetails(contractAddress: openEditionAccount.address, contractName: "OpenEditionNFT", dropID: dropID)
    Test.assertEqual(details.display.name, defaultEndlessOpenEditionName)
}

access(all) fun test_OpenEditionNFT_mint() {
    let dropID = createDefaultEndlessOpenEditionDrop()
    let details = getDropDetails(contractAddress: openEditionAccount.address, contractName: "OpenEditionNFT", dropID: dropID)

    let minter = Test.createAccount()
    setupExampleToken(minter)
    mintExampleTokens(minter, 100.0)

    let costPerItem = 1.0
    let numToMint = 2
    let total = costPerItem * UFix64(numToMint)

    let ids = mintDrop(
        minter: minter,
        contractAddress: openEditionAccount.address,
        contractName: "OpenEditionNFT",
        numToMint: numToMint,
        totalCost: total,
        paymentIdentifier: exampleTokenIdentifier(),
        paymentStoragePath: exampleTokenStoragePath,
        paymentReceiverPath: exampleTokenReceiverPath,
        dropID: dropID,
        dropPhaseIndex: 0,
        nftIdentifier: Type<@OpenEditionNFT.NFT>().identifier,
        commissionAddress: flowtyDropsAccount.address
    )

    Test.assertEqual(numToMint, ids.length)

    // did the commission get sent correctly?
    let commissionDepositAmount = total * details.commissionRate
    let minterDepositAmount = total - commissionDepositAmount

    let tokenDeposits = Test.eventsOfType(Type<ExampleToken.TokensDeposited>())
    let minterFee = tokenDeposits.removeLast() as! ExampleToken.TokensDeposited
    let commissionEvent = tokenDeposits.removeLast() as! ExampleToken.TokensDeposited
    
    Test.assertEqual(commissionDepositAmount, commissionEvent.amount)
    Test.assertEqual(flowtyDropsAccount.address, commissionEvent.to!)
    
    Test.assertEqual(minterDepositAmount, minterFee.amount)
    Test.assertEqual(openEditionAccount.address, minterFee.to!)
}

access(all) fun test_OpenEditionNFT_EditPhaseDetails() {
    let dropID = createDefaultTimeBasedOpenEditionDrop()
    Test.assertEqual(true, hasDropPhaseStarted(contractAddress: openEditionAccount.address, contractName: "OpenEditionNFT", dropID: dropID, phaseIndex: 0))
    Test.assertEqual(false, hasDropPhaseEnded(contractAddress: openEditionAccount.address, contractName: "OpenEditionNFT", dropID: dropID, phaseIndex: 0))
    
    // now let's set a new start and end time
    let currentTime = getCurrentTime()
    let newStart = UInt64(currentTime + 5.0)

    txExecutor("drops/edit_timebased_phase_start_and_end.cdc", [openEditionAccount], [dropID, 0, newStart, newStart + UInt64(5)], nil, nil)
    Test.assertEqual(false, hasDropPhaseStarted(contractAddress: openEditionAccount.address, contractName: "OpenEditionNFT", dropID: dropID, phaseIndex: 0))
    Test.assertEqual(false, hasDropPhaseEnded(contractAddress: openEditionAccount.address, contractName: "OpenEditionNFT", dropID: dropID, phaseIndex: 0))

    // now move time such that the drop should have started
    Test.moveTime(by: 6.0)
    Test.assertEqual(true, hasDropPhaseStarted(contractAddress: openEditionAccount.address, contractName: "OpenEditionNFT", dropID: dropID, phaseIndex: 0))
    Test.assertEqual(false, hasDropPhaseEnded(contractAddress: openEditionAccount.address, contractName: "OpenEditionNFT", dropID: dropID, phaseIndex: 0))

    // now move time to expire the phase
    Test.moveTime(by: 10.0)
    Test.assertEqual(true, hasDropPhaseEnded(contractAddress: openEditionAccount.address, contractName: "OpenEditionNFT", dropID: dropID, phaseIndex: 0))
}

access(all) fun test_OpenEditionNFT_EditPrice() {
    let dropID = createDefaultTimeBasedOpenEditionDrop()
    Test.assertEqual(1.0, getPriceAtPhase(contractAddress: openEditionAccount.address, contractName: "OpenEditionNFT", dropID: dropID, phaseIndex: 0, minter: openEditionAccount.address, numToMint: 1, paymentIdentifier: exampleTokenIdentifier()))

    txExecutor("drops/edit_flat_price.cdc", [openEditionAccount], [dropID, 0, 2.0], nil, nil)
    Test.assertEqual(2.0, getPriceAtPhase(contractAddress: openEditionAccount.address, contractName: "OpenEditionNFT", dropID: dropID, phaseIndex: 0, minter: openEditionAccount.address, numToMint: 1, paymentIdentifier: exampleTokenIdentifier()))
}

access(all) fun test_OpenEditionNFT_EditMaxPerMint() {
    let dropID = createDefaultTimeBasedOpenEditionDrop()
    Test.assertEqual(true, canMintAtPhase(contractAddress: openEditionAccount.address, contractName: "OpenEditionNFT", dropID: dropID, phaseIndex: 0, minter: openEditionAccount.address, numToMint: 10, totalMinted: 0, paymentIdentifier: exampleTokenIdentifier()))
    txExecutor("drops/edit_address_verifier_max_per_mint.cdc", [openEditionAccount], [dropID, 0, 5], nil, nil)

    Test.assertEqual(false, canMintAtPhase(contractAddress: openEditionAccount.address, contractName: "OpenEditionNFT", dropID: dropID, phaseIndex: 0, minter: openEditionAccount.address, numToMint: 10, totalMinted: 0, paymentIdentifier: exampleTokenIdentifier()))
    Test.assertEqual(true, canMintAtPhase(contractAddress: openEditionAccount.address, contractName: "OpenEditionNFT", dropID: dropID, phaseIndex: 0, minter: openEditionAccount.address, numToMint: 5, totalMinted: 0, paymentIdentifier: exampleTokenIdentifier()))
}

access(all) fun test_OpenEditionNFT_GetActivePhases() {
    let dropID = createDefaultTimeBasedOpenEditionDrop()
    let activePhaseIDs = scriptExecutor("get_active_phases.cdc", [openEditionAccount.address, "OpenEditionNFT", dropID])! as! [UInt64]
    Test.assert(activePhaseIDs.length == 1, message: "unexpected active phase length")
}

access(all) fun test_OpenEditionNFT_addPhase() {
    let dropID = createDefaultTimeBasedOpenEditionDrop()

    txExecutor("drops/add_free_phase.cdc", [openEditionAccount], [dropID, nil, nil], nil, nil)
    let phaseEvent = Test.eventsOfType(Type<FlowtyDrops.PhaseAdded>()).removeLast() as! FlowtyDrops.PhaseAdded

    var activePhaseIDs = scriptExecutor("get_active_phases.cdc", [openEditionAccount.address, "OpenEditionNFT", dropID])! as! [UInt64]
    Test.assert(activePhaseIDs.contains(phaseEvent.id), message: "unexpected active phase length")

    txExecutor("drops/remove_last_phase.cdc", [openEditionAccount], [dropID, nil, nil], nil, nil)
    activePhaseIDs = scriptExecutor("get_active_phases.cdc", [openEditionAccount.address, "OpenEditionNFT", dropID])! as! [UInt64]
    Test.assert(!activePhaseIDs.contains(phaseEvent.id), message: "unexpected active phase length")
}

access(all) fun test_OpenEditionNFT_getDropSummary() {
    let dropID = createDefaultTimeBasedOpenEditionDrop()

    let minter = Test.createAccount()
    setupExampleToken(minter)
    mintExampleTokens(minter, 100.0)

    let summary = scriptExecutor("get_drop_summary.cdc", [openEditionAccount.address, "OpenEditionNFT", dropID, minter.address, 1, exampleTokenIdentifier()])! as! DropTypes.DropSummary
    Test.assertEqual(minter.address, summary.address!)

    let numToMint = 5
    let totalCost = 5.0

    mintDrop(
        minter: minter,
        contractAddress: openEditionAccount.address,
        contractName: "OpenEditionNFT",
        numToMint: numToMint,
        totalCost: totalCost,
        paymentIdentifier: exampleTokenIdentifier(),
        paymentStoragePath: exampleTokenStoragePath,
        paymentReceiverPath: exampleTokenReceiverPath,
        dropID: dropID,
        dropPhaseIndex: 0,
        nftIdentifier: Type<@OpenEditionNFT.NFT>().identifier,
        commissionAddress: flowtyDropsAccount.address
    )

    let summaryAfter = scriptExecutor("get_drop_summary.cdc", [openEditionAccount.address, "OpenEditionNFT", dropID, minter.address, 1, exampleTokenIdentifier()])! as! DropTypes.DropSummary
    Test.assertEqual(summaryAfter.totalMinted, numToMint)
    Test.assertEqual(summaryAfter.mintedByAddress!, numToMint)
    Test.assertEqual(1, summaryAfter.phases.length)

    let summaries = scriptExecutor("get_drop_summaries.cdc", [openEditionAccount.address, "OpenEditionNFT", minter.address, 1, exampleTokenIdentifier()])! as! [DropTypes.DropSummary]
    Test.assertEqual(1, summaries.length)
    Test.assertEqual(summaries[0].totalMinted, numToMint)
    Test.assertEqual(summaries[0].mintedByAddress!, numToMint)
    Test.assertEqual(1, summaries[0].phases.length)
}

access(all) fun test_OpenEditionNFT_getDropSummary_noMinter() {
    let dropID = createDefaultTimeBasedOpenEditionDrop()

    let summaries = scriptExecutor("get_drop_summaries.cdc", [openEditionAccount.address, "OpenEditionNFT", nil, 1, exampleTokenIdentifier()])! as! [DropTypes.DropSummary]
    Test.assertEqual(1, summaries.length)
    Test.assertEqual(summaries[0].totalMinted, 0)
    Test.assertEqual(summaries[0].mintedByAddress, nil)
    Test.assertEqual(1, summaries[0].phases.length)
}
// ------------------------------------------------------------------------
//                      Helper functions section

access(all) fun createDefaultEndlessOpenEditionDrop(): UInt64 {
    return createEndlessOpenEditionDrop(
        acct: openEditionAccount,
        name: "Default Endless Open Edition",
        description: "This is a placeholder description",
        ipfsCid: "1234",
        ipfsPath: nil,
        price: 1.0,
        paymentIdentifier: exampleTokenIdentifier(),
        minterPrivatePath: FlowtyDrops.MinterPrivatePath,
        nftTypeIdentifier: openEditionNftIdentifier()
    )
}

access(all) fun createDefaultTimeBasedOpenEditionDrop(): UInt64 {
    let currentTime = getCurrentTime()

    return createTimebasedOpenEditionDrop(
        acct: openEditionAccount,
        name: "Default Time-based Open Edition",
        description: "This is a placeholder description",
        ipfsCid: "1234",
        ipfsPath: nil,
        price: 1.0,
        paymentIdentifier: exampleTokenIdentifier(),
        startUnix: UInt64(getCurrentTime()),
        endUnix: UInt64(currentTime + 5.0),
        minterPrivatePath: FlowtyDrops.MinterPrivatePath,
        nftTypeIdentifier: openEditionNftIdentifier()
    )
}

access(all) fun getPriceAtPhase(contractAddress: Address, contractName: String, dropID: UInt64, phaseIndex: Int, minter: Address, numToMint: Int, paymentIdentifier: String): UFix64 {
    return scriptExecutor("get_price_at_phase.cdc", [contractAddress, contractName, dropID, phaseIndex, minter, numToMint, paymentIdentifier])! as! UFix64
}

access(all) fun getDropDetails(contractAddress: Address, contractName: String, dropID: UInt64): FlowtyDrops.DropDetails {
    return scriptExecutor("get_drop_details.cdc", [contractAddress, contractName, dropID])! as! FlowtyDrops.DropDetails
}

access(all) fun mintDrop(
    minter: Test.Account,
    contractAddress: Address,
    contractName: String,
    numToMint: Int,
    totalCost: UFix64,
    paymentIdentifier: String,
    paymentStoragePath: StoragePath,
    paymentReceiverPath: PublicPath,
    dropID: UInt64,
    dropPhaseIndex: Int,
    nftIdentifier: String,
    commissionAddress: Address
): [UInt64] {
    txExecutor("drops/mint.cdc", [minter], [
        contractAddress, contractName, numToMint, totalCost, paymentIdentifier, paymentStoragePath, paymentReceiverPath, dropID, dropPhaseIndex, nftIdentifier, commissionAddress
    ], nil, nil)

    let ids: [UInt64] = []
    let events = Test.eventsOfType(Type<FlowtyDrops.Minted>())
    var count = 0
    while count < numToMint {
        count = count + 1
        let event = events.removeFirst() as! FlowtyDrops.Minted
        ids.append(event.nftID)
    }

    return ids
}