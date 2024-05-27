import Test

import "NonFungibleToken"
import "FlowToken"
import "FlowtyDrops"
import "OpenEditionNFT"

// Helper functions. All of the following were taken from
// https://github.com/onflow/Offers/blob/fd380659f0836e5ce401aa99a2975166b2da5cb0/lib/cadence/test/Offers.cdc
// - deploy
// - scriptExecutor
// - txExecutor

access(all) fun scriptExecutor(_ scriptName: String, _ arguments: [AnyStruct]): AnyStruct? {
    let scriptCode = loadCode(scriptName, "scripts")
    let scriptResult = Test.executeScript(scriptCode, arguments)

    if let failureError = scriptResult.error {
        panic(
            "Failed to execute the script because -:  ".concat(failureError.message)
        )
    }

    return scriptResult.returnValue
}

access(all) fun expectScriptFailure(_ scriptName: String, _ arguments: [AnyStruct]): String {
    let scriptCode = loadCode(scriptName, "scripts")
    let scriptResult = Test.executeScript(scriptCode, arguments)

    assert(scriptResult.error != nil, message: "script error was expected but there is no error message")
    return scriptResult.error!.message
}

access(all) fun txExecutor(_ txName: String, _ signers: [Test.TestAccount], _ arguments: [AnyStruct], _ expectedError: String?, _ expectedErrorType: ErrorType?): Test.TransactionResult {
    let txCode = loadCode(txName, "transactions")

    let authorizers: [Address] = []
    for signer in signers {
        authorizers.append(signer.address)
    }

    let tx = Test.Transaction(
        code: txCode,
        authorizers: authorizers,
        signers: signers,
        arguments: arguments,
    )

    let txResult = Test.executeTransaction(tx)
    if txResult.error != nil  {
        panic(txResult.error!.message)
    }

    return txResult
}

access(all) fun loadCode(_ fileName: String, _ baseDirectory: String): String {
    return Test.readFile("../".concat(baseDirectory).concat("/").concat(fileName))
}

access(all) enum ErrorType: UInt8 {
    access(all) case TX_PANIC
    access(all) case TX_ASSERT
    access(all) case TX_PRE
}

// the cadence testing framework allocates 4 addresses for system acounts,
// and 10 pre-created accounts for us to use for deployments:
access(all) let Account0x1 = Address(0x0000000000000001)
access(all) let Account0x2 = Address(0x0000000000000002)
access(all) let Account0x3 = Address(0x0000000000000003)
access(all) let Account0x4 = Address(0x0000000000000004)
access(all) let Account0x5 = Address(0x0000000000000005)
access(all) let Account0x6 = Address(0x0000000000000006)
access(all) let Account0x7 = Address(0x0000000000000007)
access(all) let Account0x8 = Address(0x0000000000000008)
access(all) let Account0x9 = Address(0x0000000000000009)
access(all) let Account0xa = Address(0x000000000000000a)
access(all) let Account0xb = Address(0x000000000000000b)
access(all) let Account0xc = Address(0x000000000000000c)
access(all) let Account0xd = Address(0x000000000000000d)
access(all) let Account0xe = Address(0x000000000000000e)

// Example Token constants
access(all) let exampleTokenStoragePath = /storage/exampleTokenVault
access(all) let exampleTokenReceiverPath = /public/exampleTokenReceiver
access(all) let exampleTokenProviderPath = /private/exampleTokenProvider
access(all) let exampleTokenBalancePath = /public/exampleTokenBalance

access(all) let serviceAccount = Test.getAccount(Account0x5)
access(all) let flowtyDropsAccount = Test.getAccount(Account0x6)
access(all) let openEditionAccount = Test.getAccount(Account0x7)
access(all) let exampleTokenAccount = Test.getAccount(Account0x8)

// Flow Token constants
access(all) let flowTokenStoragePath = /storage/flowTokenVault
access(all) let flowTokenReceiverPath = /public/flowTokenReceiver

access(all) fun deployAll() {
    deploy("ExampleToken", "../contracts/standard/ExampleToken.cdc", [])

    // 0x6
    deploy("FlowtyDrops", "../contracts/FlowtyDrops.cdc", [])
    deploy("FlowtySwitchers", "../contracts/FlowtySwitchers.cdc", [])
    deploy("FlowtyPricers", "../contracts/FlowtyPricers.cdc", [])
    deploy("FlowtyAddressVerifiers", "../contracts/FlowtyAddressVerifiers.cdc", [])
    deploy("DropFactory", "../contracts/DropFactory.cdc", [])

    // 0x8
    deploy("DropTypes", "../contracts/DropTypes.cdc", [])

    // 0x7
    deploy("OpenEditionNFT", "../contracts/nft/OpenEditionNFT.cdc", [])


    setupExampleToken(flowtyDropsAccount)
    setupExampleToken(openEditionAccount)
}

access(all) fun deploy(_ name: String, _ path: String, _ arguments: [AnyStruct]) {
    let err = Test.deployContract(name: name, path: path, arguments: arguments)
    Test.expect(err, Test.beNil()) 
}

access(all) fun heartbeat() {
    txExecutor("util/heartbeat.cdc", [serviceAccount], [], nil, nil)
}

access(all) fun getCurrentTime(): UFix64 {
    return scriptExecutor("util/get_current_time.cdc", [])! as! UFix64
}

access(all) fun mintFromDrop(
    minter: Test.TestAccount,
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
    commissionReceiver: Address
) {
    let args = [
        contractAddress,
        contractName,
        numToMint,
        totalCost,
        paymentIdentifier,
        paymentStoragePath,
        paymentReceiverPath,
        dropID,
        dropPhaseIndex,
        nftIdentifier,
        commissionReceiver
    ]
    txExecutor("drops/mint.cdc", [minter], args, nil, nil)
}

access(all) fun getDropIDs(
    contractAddress: Address,
    contractName: String
): [UInt64] {
    return scriptExecutor("get_drop_ids.cdc", [contractAddress, contractName])! as! [UInt64]
}

access(all) fun createEndlessOpenEditionDrop(
    acct: Test.TestAccount,
    name: String,
    description: String,
    ipfsCid: String,
    ipfsPath: String?,
    price: UFix64,
    paymentIdentifier: String,
    minterPrivatePath: PrivatePath,
    nftTypeIdentifier: String
): UInt64 {
    txExecutor("drops/add_endless_open_edition.cdc", [acct], [
        name, description, ipfsCid, ipfsPath, price, paymentIdentifier, minterPrivatePath, nftTypeIdentifier
    ], nil, nil)
    
    let e = Test.eventsOfType(Type<FlowtyDrops.DropAdded>()).removeLast() as! FlowtyDrops.DropAdded
    return e.id
}

access(all) fun createTimebasedOpenEditionDrop(
    acct: Test.TestAccount,
    name: String,
    description: String,
    ipfsCid: String,
    ipfsPath: String?,
    price: UFix64,
    paymentIdentifier: String,
    startUnix: UInt64?,
    endUnix: UInt64?,
    minterPrivatePath: PrivatePath,
    nftTypeIdentifier: String
): UInt64 {
    txExecutor("drops/add_time_based_open_edition.cdc", [acct], [
        name, description, ipfsCid, ipfsPath, price, paymentIdentifier, startUnix, endUnix, minterPrivatePath, nftTypeIdentifier
    ], nil, nil)

    let e = Test.eventsOfType(Type<FlowtyDrops.DropAdded>()).removeLast() as! FlowtyDrops.DropAdded
    return e.id
}

access(all) fun sendFlowTokens(fromAccount: Test.TestAccount, toAccount: Test.TestAccount, amount: UFix64) {
    txExecutor("util/send_flow_tokens.cdc", [fromAccount], [toAccount.address, amount], nil, nil)
}

access(all) fun setupExampleToken(_ acct: Test.TestAccount) {
    txExecutor("example-token/setup.cdc", [acct], [], nil, nil)
}

access(all) fun mintExampleTokens(_ acct: Test.TestAccount, _ amount: UFix64) {
    txExecutor("example-token/mint.cdc", [exampleTokenAccount], [acct.address, amount], nil, nil)
}

access(all) fun flowTokenIdentifier(): String {
    return Type<@FlowToken.Vault>().identifier
}

access(all) fun openEditionNftIdentifier(): String {
    return Type<@OpenEditionNFT.NFT>().identifier
}

access(all) fun hasDropPhaseStarted(contractAddress: Address, contractName: String, dropID: UInt64, phaseIndex: Int): Bool {
    return scriptExecutor("has_phase_started.cdc", [contractAddress, contractName, dropID, phaseIndex])! as! Bool
}

access(all) fun hasDropPhaseEnded(contractAddress: Address, contractName: String, dropID: UInt64, phaseIndex: Int): Bool {
    return scriptExecutor("has_phase_ended.cdc", [contractAddress, contractName, dropID, phaseIndex])! as! Bool
}

access(all) fun canMintAtPhase(contractAddress: Address, contractName: String, dropID: UInt64, phaseIndex: Int, minter: Address, numToMint: Int, totalMinted: Int, paymentIdentifier: String): Bool {
    return scriptExecutor("can_mint_at_phase.cdc", [
        contractAddress, contractName, dropID, phaseIndex, minter, numToMint, totalMinted, paymentIdentifier
    ])! as! Bool
}