import Test
import "test_helpers.cdc"
import "FlowtySwitches"

pub fun setup() {
    deployAll()
}

pub fun test_FlowtySwitches_AlwaysOn() {
    let s = FlowtySwitches.AlwaysOn()
    Test.assert(s.hasStarted(), message: "AlwaysOn switch should always be started")
    Test.assert(!s.hasEnded(), message: "AlwaysOn switch never ends")

    Test.assertEqual(nil, s.getStart())
    Test.assertEqual(nil, s.getEnd())
}

pub fun test_FlowtySwitches_ManualSwitch() {
    let s = FlowtySwitches.ManualSwitch()

    Test.assertEqual(false, s.hasStarted())
    Test.assertEqual(false, s.hasEnded())
    Test.assertEqual(nil, s.getStart())
    Test.assertEqual(nil, s.getEnd())

    // now turn the switch on
    s.setStarted(true)
    Test.assertEqual(true, s.hasStarted())
    Test.assertEqual(false, s.hasEnded())

    s.setEnded(true)
    Test.assertEqual(true, s.hasStarted())
    Test.assertEqual(true, s.hasEnded())
}

pub fun test_FlowtySwitches_TimestampSwitch_StartIsNil() {
    let end = UInt64(getCurrentBlock().timestamp) + 10
    let s = FlowtySwitches.TimestampSwitch(start: nil, end: end)

    Test.assertEqual(true, s.hasStarted())
    Test.assertEqual(nil, s.getStart())

    Test.assertEqual(false, s.hasEnded())
    Test.assertEqual(end, s.getEnd()!)
}

pub fun test_FlowtySwitches_TimestampSwitch_StartAfterNow() {
    let start = UInt64(getCurrentBlock().timestamp) + 1
    let end = UInt64(getCurrentBlock().timestamp) + 10
    let s = FlowtySwitches.TimestampSwitch(start: start, end: end)

    Test.assertEqual(false, s.hasStarted())
    Test.assertEqual(start, s.getStart()!)

    Test.assertEqual(false, s.hasEnded())
    Test.assertEqual(end, s.getEnd()!)
}

pub fun test_FlowtySwitches_TimestampSwitch_StartBeforeNow() {
    let start = UInt64(getCurrentBlock().timestamp) - 1
    let end = UInt64(getCurrentBlock().timestamp) + 10
    let s = FlowtySwitches.TimestampSwitch(start: start, end: end)

    Test.assertEqual(true, s.hasStarted())
    Test.assertEqual(start, s.getStart()!)

    Test.assertEqual(false, s.hasEnded())
    Test.assertEqual(end, s.getEnd()!)
}

pub fun test_FlowtySwitches_TimestampSwitch_Ended() {
    let start = UInt64(getCurrentBlock().timestamp) - 10
    let end = UInt64(getCurrentBlock().timestamp) - 1
    let s = FlowtySwitches.TimestampSwitch(start: start, end: end)

    Test.assertEqual(true, s.hasStarted())
    Test.assertEqual(true, s.hasEnded())
}

pub fun test_FlowtySwitches_TimestampSwitch_InvalidStartEnd() {
    let start: UInt64 = 10
    let end: UInt64 = 9

    Test.expectFailure(fun() {
        FlowtySwitches.TimestampSwitch(start: start, end: end)
    }, errorMessageSubstring: "start must be less than end")
}