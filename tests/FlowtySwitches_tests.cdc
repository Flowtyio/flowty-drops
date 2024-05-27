import Test
import "test_helpers.cdc"
import "FlowtySwitchers"

access(all) fun setup() {
    deployAll()
}

access(all) fun test_FlowtySwitchers_AlwaysOn() {
    let s = FlowtySwitchers.AlwaysOn()
    Test.assert(s.hasStarted(), message: "AlwaysOn switcher should always be started")
    Test.assert(!s.hasEnded(), message: "AlwaysOn switcher never ends")

    Test.assertEqual(nil, s.getStart())
    Test.assertEqual(nil, s.getEnd())
}

access(all) fun test_FlowtySwitchers_ManualSwitch() {
    let s = FlowtySwitchers.ManualSwitch()

    Test.assertEqual(false, s.hasStarted())
    Test.assertEqual(false, s.hasEnded())
    Test.assertEqual(nil, s.getStart())
    Test.assertEqual(nil, s.getEnd())

    // now turn the switcher on
    s.setStarted(true)
    Test.assertEqual(true, s.hasStarted())
    Test.assertEqual(false, s.hasEnded())

    s.setEnded(true)
    Test.assertEqual(true, s.hasStarted())
    Test.assertEqual(true, s.hasEnded())
}

access(all) fun test_FlowtySwitchers_TimestampSwitch_StartIsNil() {
    let end = UInt64(getCurrentBlock().timestamp) + 10
    let s = FlowtySwitchers.TimestampSwitch(start: nil, end: end)

    Test.assertEqual(true, s.hasStarted())
    Test.assertEqual(nil, s.getStart())

    Test.assertEqual(false, s.hasEnded())
    Test.assertEqual(end, s.getEnd()!)
}

access(all) fun test_FlowtySwitchers_TimestampSwitch_StartAfterNow() {
    let start = UInt64(getCurrentBlock().timestamp) + 1
    let end = UInt64(getCurrentBlock().timestamp) + 10
    let s = FlowtySwitchers.TimestampSwitch(start: start, end: end)

    Test.assertEqual(false, s.hasStarted())
    Test.assertEqual(start, s.getStart()!)

    Test.assertEqual(false, s.hasEnded())
    Test.assertEqual(end, s.getEnd()!)
}

access(all) fun test_FlowtySwitchers_TimestampSwitch_StartBeforeNow() {
    let start = UInt64(getCurrentBlock().timestamp) - 1
    let end = UInt64(getCurrentBlock().timestamp) + 10
    let s = FlowtySwitchers.TimestampSwitch(start: start, end: end)

    Test.assertEqual(true, s.hasStarted())
    Test.assertEqual(start, s.getStart()!)

    Test.assertEqual(false, s.hasEnded())
    Test.assertEqual(end, s.getEnd()!)
}

access(all) fun test_FlowtySwitchers_TimestampSwitch_Ended() {
    let start = UInt64(getCurrentBlock().timestamp) - 10
    let end = UInt64(getCurrentBlock().timestamp) - 1
    let s = FlowtySwitchers.TimestampSwitch(start: start, end: end)

    Test.assertEqual(true, s.hasStarted())
    Test.assertEqual(true, s.hasEnded())
}

access(all) fun test_FlowtySwitchers_TimestampSwitch_InvalidStartEnd() {
    let start: UInt64 = 10
    let end: UInt64 = 9

    Test.expectFailure(fun() {
        FlowtySwitchers.TimestampSwitch(start: start, end: end)
    }, errorMessageSubstring: "start must be less than end")
}