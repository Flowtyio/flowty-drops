import Test

import "NonFungibleToken"
import "FlowToken"

// Helper functions. All of the following were taken from
// https://github.com/onflow/Offers/blob/fd380659f0836e5ce401aa99a2975166b2da5cb0/lib/cadence/test/Offers.cdc
// - deploy
// - scriptExecutor
// - txExecutor
// - getErrorMessagePointer

pub fun scriptExecutor(_ scriptName: String, _ arguments: [AnyStruct]): AnyStruct? {
    let scriptCode = loadCode(scriptName, "scripts")
    let scriptResult = Test.executeScript(scriptCode, arguments)

    if let failureError = scriptResult.error {
        panic(
            "Failed to execute the script because -:  ".concat(failureError.message)
        )
    }

    return scriptResult.returnValue
}

pub fun expectScriptFailure(_ scriptName: String, _ arguments: [AnyStruct]): String {
    let scriptCode = loadCode(scriptName, "scripts")
    let scriptResult = Test.executeScript(scriptCode, arguments)

    assert(scriptResult.error != nil, message: "script error was expected but there is no error message")
    return scriptResult.error!.message
}

pub fun txExecutor(_ txName: String, _ signers: [Test.Account], _ arguments: [AnyStruct], _ expectedError: String?, _ expectedErrorType: ErrorType?): Test.TransactionResult {
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
    if let err = txResult.error {
        if let expectedErrorMessage = expectedError {
            let ptr = getErrorMessagePointer(errorType: expectedErrorType!)
            let errMessage = err.message
            let hasEmittedCorrectMessage = contains(errMessage, expectedErrorMessage)
            let failureMessage = "Expecting - "
                .concat(expectedErrorMessage)
                .concat("\n")
                .concat("But received - ")
                .concat(err.message)
            assert(hasEmittedCorrectMessage, message: failureMessage)
        }
        panic(err.message)
    } else {
        if let expectedErrorMessage = expectedError {
            panic("Expecting error - ".concat(expectedErrorMessage).concat(". While no error triggered"))
        }
    }

    return txResult
}

pub fun loadCode(_ fileName: String, _ baseDirectory: String): String {
    return Test.readFile("../".concat(baseDirectory).concat("/").concat(fileName))
}

pub enum ErrorType: UInt8 {
    pub case TX_PANIC
    pub case TX_ASSERT
    pub case TX_PRE
}

pub fun getErrorMessagePointer(errorType: ErrorType): Int {
    switch errorType {
        case ErrorType.TX_PANIC: return 159
        case ErrorType.TX_ASSERT: return 170
        case ErrorType.TX_PRE: return 174
        default: panic("Invalid error type")
    }

    return 0
}

// Copied functions from flow-utils so we can assert on error conditions
// https://github.com/green-goo-dao/flow-utils/blob/main/cadence/contracts/StringUtils.cdc
pub fun contains(_ s: String, _ substr: String): Bool {
    if let index = index(s, substr, 0) {
        return true
    }
    return false
}

// https://github.com/green-goo-dao/flow-utils/blob/main/cadence/contracts/StringUtils.cdc
pub fun index(_ s: String, _ substr: String, _ startIndex: Int): Int? {
    for i in range(startIndex, s.length - substr.length + 1) {
        if s[i] == substr[0] && s.slice(from: i, upTo: i + substr.length) == substr {
            return i
        }
    }
    return nil
}

// https://github.com/green-goo-dao/flow-utils/blob/main/cadence/contracts/ArrayUtils.cdc
pub fun rangeFunc(_ start: Int, _ end: Int, _ f: ((Int): Void)) {
    var current = start
    while current < end {
        f(current)
        current = current + 1
    }
}

pub fun range(_ start: Int, _ end: Int): [Int] {
    let res: [Int] = []
    rangeFunc(start, end, fun (i: Int) {
        res.append(i)
    })
    return res
}


// the cadence testing framework allocates 4 addresses for system acounts,
// and 10 pre-created accounts for us to use for deployments:
pub let Account0x1 = Address(0x0000000000000001)
pub let Account0x2 = Address(0x0000000000000002)
pub let Account0x3 = Address(0x0000000000000003)
pub let Account0x4 = Address(0x0000000000000004)
pub let Account0x5 = Address(0x0000000000000005)
pub let Account0x6 = Address(0x0000000000000006)
pub let Account0x7 = Address(0x0000000000000007)
pub let Account0x8 = Address(0x0000000000000008)
pub let Account0x9 = Address(0x0000000000000009)
pub let Account0xa = Address(0x000000000000000a)
pub let Account0xb = Address(0x000000000000000b)
pub let Account0xc = Address(0x000000000000000c)
pub let Account0xd = Address(0x000000000000000d)
pub let Account0xe = Address(0x000000000000000e)

pub let serviceAccount = Test.getAccount(Account0x5)
pub let dropsAccount = Test.getAccount(Account0x5)

// Flow Token constants
pub let flowTokenStoragePath = /storage/flowTokenVault
pub let flowTokenReceiverPath = /public/flowTokenReceiver


pub fun deployAll() {
    deploy("FlowtyDrops", "../contracts/FlowtyDrops.cdc", [])
    deploy("FlowtySwitches", "../contracts/FlowtySwitches.cdc", [])
    deploy("FlowtyPricers", "../contracts/FlowtyPricers.cdc", [])
    deploy("FlowtyAddressVerifiers", "../contracts/FlowtyAddressVerifiers.cdc", [])
    deploy("DropFactory", "../contracts/DropFactory.cdc", [])

    deploy("OpenEditionNFT", "../contracts/nft/OpenEditionNFT.cdc", [])
}

pub fun deploy(_ name: String, _ path: String, _ arguments: [AnyStruct]) {
    let err = Test.deployContract(name: name, path: path, arguments: arguments)
    Test.expect(err, Test.beNil()) 
}

pub fun heartbeat() {
    txExecutor("util/heartbeat.cdc", [serviceAccount], [], nil, nil)
}

pub fun getCurrentTime(): UFix64 {
    return scriptExecutor("util/get_current_time.cdc", [])! as! UFix64
}