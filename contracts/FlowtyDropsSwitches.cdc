import "FlowtyDrops"

/*
This contract contains implementations for the FlowtyDrops.Switch struct interface.
You can use these implementations, or your own, for switches when configuring a drop
*/
pub contract FlowtyDropsSwitches {
    /*
    The AlwaysOn Switch is always on and never ends.
    */
    pub struct AlwaysOn: FlowtyDrops.Switch {
        pub fun hasStarted(): Bool {
            return true
        }

        pub fun hasEnded(): Bool {
            return false
        }

        pub fun getStart(): UInt64? {
            return nil
        }

        pub fun getEnd(): UInt64? {
            return nil
        }
    }

    /*
    The manual switch is used to explicitly toggle a drop.
    This version of switch allows a creator to turn on or off a drop at will
    */
    pub struct ManualSwitch: FlowtyDrops.Switch {
        access(self) var started: Bool
        access(self) var ended: Bool

        pub fun hasStarted(): Bool {
            return self.started
        }

        pub fun hasEnded(): Bool {
            return self.ended
        }

        pub fun getStart(): UInt64? {
            return nil
        }

        pub fun getEnd(): UInt64? {
            return nil
        }

        pub fun setStarted(_ b: Bool) {
            self.started = b
        }

        pub fun setEnded(_ b: Bool) {
            self.ended = b
        }

        init() {
            self.started = false
            self.ended = false
        }
    }

    /*
    TimestampSwitch uses block timestamps to determine if a phase or drop is live or not.
    A timestamp switch has a start and an end time.
    */
    pub struct TimestampSwitch: FlowtyDrops.Switch {
        pub let start: UInt64?
        pub let end: UInt64?


        pub fun hasStarted(): Bool {
            return self.start == nil || UInt64(getCurrentBlock().timestamp) >= self.start!
        }

        pub fun hasEnded(): Bool {
            if self.end == nil {
                return false
            }

            return UInt64(getCurrentBlock().timestamp) > self.end!
        }

        pub fun getStart(): UInt64? {
            return self.start
        }

        pub fun getEnd(): UInt64? {
            return self.end
        }

        init(start: UInt64?, end: UInt64?) {
            self.start = start
            self.end = end
        }
    }

    /*
    BlockHeightSwitch uses the current block height as a marker for when a phase or drop is live.
    */
    pub struct BlockHeightSwitch: FlowtyDrops.Switch {
        pub let start: UInt64?
        pub let end: UInt64?


        pub fun hasStarted(): Bool {
            return self.start == nil || getCurrentBlock().height >= self.start!
        }

        pub fun hasEnded(): Bool {
            if self.end == nil {
                return false
            }

            return getCurrentBlock().height > self.end!
        }

        pub fun getStart(): UInt64? {
            return self.start
        }

        pub fun getEnd(): UInt64? {
            return self.end
        }

        init(start: UInt64?, end: UInt64?) {
            self.start = start
            self.end = end
        }

    }
}