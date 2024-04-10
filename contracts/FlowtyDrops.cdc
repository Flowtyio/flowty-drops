import "NonFungibleToken"
import "FungibleToken"
import "MetadataViews"

pub contract FlowtyDrops {
    pub let ContainerStoragePath: StoragePath
    pub let ContainerPublicPath: PublicPath

    pub let MinterStoragePath: StoragePath
    pub let MinterPrivatePath: PrivatePath

    pub event DropAdded(address: Address, id: UInt64, name: String, description: String, imageUrl: String, start: UInt64?, end: UInt64?)
    pub event Minted(address: Address, dropID: UInt64, phaseID: UInt64, nftID: UInt64, nftType: String)
    pub event PhaseAdded(dropID: UInt64, dropAddress: Address, id: UInt64, index: Int, switcherType: String, pricerType: String, addressVerifierType: String)
    pub event PhaseRemoved(dropID: UInt64, dropAddress: Address, id: UInt64)

    // Interface to expose all the components necessary to participate in a drop
    // and to ask questions about a drop.
    pub resource interface DropPublic {
        pub fun borrowPhasePublic(index: Int): &{PhasePublic}
        pub fun borrowActivePhases(): [&{PhasePublic}]
        pub fun borrowAllPhases(): [&{PhasePublic}]
        pub fun mint(
            payment: @FungibleToken.Vault,
            amount: Int,
            phaseIndex: Int,
            expectedType: Type,
            receiverCap: Capability<&{NonFungibleToken.CollectionPublic}>,
            commissionReceiver: Capability<&{FungibleToken.Receiver}>,
            data: {String: AnyStruct}
        ): @FungibleToken.Vault
        pub fun getDetails(): DropDetails
    }

    pub resource Drop: DropPublic {
        // phases represent the stages of a drop. For example, a drop might have an allowlist and a public mint phase.
        access(self) let phases: @[Phase]
        // the details of a drop. This includes things like display information and total number of mints
        access(self) let details: DropDetails
        access(self) let minterCap: Capability<&{Minter}>

        pub fun mint(
            payment: @FungibleToken.Vault,
            amount: Int,
            phaseIndex: Int,
            expectedType: Type,
            receiverCap: Capability<&{NonFungibleToken.CollectionPublic}>,
            commissionReceiver: Capability<&{FungibleToken.Receiver}>,
            data: {String: AnyStruct}
        ): @FungibleToken.Vault {
            pre {
                expectedType.isSubtype(of: Type<@NonFungibleToken.NFT>()): "expected type must be an NFT"
                self.phases.length > phaseIndex: "phase index is too high"
                receiverCap.check(): "receiver capability is not valid"
            }

            // validate the payment vault amount and type
            let phase = &self.phases[phaseIndex] as! &Phase
            assert(
                phase.details.addressVerifier.canMint(addr: receiverCap.address, num: amount, totalMinted: self.details.minters[receiverCap.address] ?? 0, data: {}),
                message: "receiver address has exceeded their mint capacity"
            )

            let paymentAmount = phase.details.pricer.getPrice(num: amount, paymentTokenType: payment.getType(), minter: receiverCap.address)
            let withdrawn <- payment.withdraw(amount: paymentAmount) // make sure that we have a fresh vault resource

            // take commission
            let commission <- withdrawn.withdraw(amount: self.details.commissionRate * withdrawn.balance)
            commissionReceiver.borrow()!.deposit(from: <-commission)

            assert(phase.details.pricer.getPrice(num: amount, paymentTokenType: withdrawn.getType(), minter: receiverCap.address) * (1.0 - self.details.commissionRate) == withdrawn.balance, message: "incorrect payment amount")
            assert(phase.details.pricer.getPaymentTypes().contains(withdrawn.getType()), message: "unsupported payment type")

            // mint the nfts
            let minter = self.minterCap.borrow() ?? panic("minter capability could not be borrowed")
            let mintedNFTs <- minter.mint(payment: <-withdrawn, amount: amount, phase: phase, data: data)

            // distribute to receiver
            let receiver = receiverCap.borrow() ?? panic("could not borrow receiver capability")
            self.details.addMinted(num: mintedNFTs.length, addr: receiverCap.address)

            while mintedNFTs.length > 0 {
                let nft <- mintedNFTs.removeFirst()

                let nftType = nft.getType()
                emit Minted(address: receiverCap.address, dropID: self.uuid, phaseID: phase.uuid, nftID: nft.id, nftType: nftType.identifier)

                // validate that every nft is the right type
                assert(nftType == expectedType, message: "unexpected nft type was minted")
    
                receiver.deposit(token: <-nft)
            }

            // cleanup
            destroy mintedNFTs

            // return excess payment
            return <- payment
        }

        pub fun borrowPhase(index: Int): &Phase {
            return &self.phases[index] as! &Phase
        }


        pub fun borrowPhasePublic(index: Int): &{PhasePublic} {
            return &self.phases[index] as! &{PhasePublic}
        }

        pub fun borrowActivePhases(): [&{PhasePublic}] {
            let arr: [&{PhasePublic}] = []
            var count = 0
            while count < self.phases.length {
                let ref = self.borrowPhasePublic(index: count)
                let switcher = ref.getDetails().switcher
                if switcher.hasStarted() && !switcher.hasEnded() {
                    arr.append(ref)
                }

                count = count + 1
            }

            return arr
        }

        pub fun borrowAllPhases(): [&{PhasePublic}] {
            let arr: [&{PhasePublic}] = []
            var count = 0
            while count < self.phases.length {
                let ref = self.borrowPhasePublic(index: count)
                arr.append(ref)
                count = count + 1
            }

            return arr
        }

        pub fun addPhase(_ phase: @Phase) {
            emit PhaseAdded(
                dropID: self.uuid,
                dropAddress: self.owner!.address,
                id: phase.uuid,
                index: self.phases.length,
                switcherType: phase.details.switcher.getType().identifier,
                pricerType: phase.details.pricer.getType().identifier,
                addressVerifierType: phase.details.addressVerifier.getType().identifier
            )
            self.phases.append(<-phase)
        }

        pub fun removePhase(index: Int): @Phase {
            pre {
                self.phases.length > index: "index is greater than length of phases"
            }

            let phase <- self.phases.remove(at: index)
            emit PhaseRemoved(dropID: self.uuid, dropAddress: self.owner!.address, id: phase.uuid)

            return <- phase
        }

        pub fun getDetails(): DropDetails {
            return self.details
        }

        init(details: DropDetails, minterCap: Capability<&{Minter}>, phases: @[Phase]) {
            pre {
                minterCap.check(): "minter capability is not valid"
            }

            self.phases <- phases
            self.details = details
            self.minterCap = minterCap
        }

        destroy () {
            destroy self.phases
        }
    }

    pub struct DropDetails {
        pub let display: MetadataViews.Display
        pub let medias: MetadataViews.Medias?
        pub var totalMinted: Int
        pub var minters: {Address: Int}
        pub let commissionRate: UFix64

        access(contract) fun addMinted(num: Int, addr: Address) {
            self.totalMinted = self.totalMinted + num
            if self.minters[addr] == nil {
                self.minters[addr] = 0
            }

            self.minters[addr] = self.minters[addr]! + num
        }

        init(display: MetadataViews.Display, medias: MetadataViews.Medias?, commissionRate: UFix64) {
            self.display = display
            self.medias = medias
            self.totalMinted = 0
            self.commissionRate = commissionRate
            self.minters = {}
        }
    }

    // A switcher represents a phase being on or off, and holds information
    // about whether a phase has started or not.
    pub struct interface Switcher {
        // Signal that a phase has started. If the phase has not ended, it means that this switcher's phase
        // is active
        pub fun hasStarted(): Bool
        // Signal that a phase has ended. If a switcher has ended, minting will not work. That could mean
        // the drop is over, or it could mean another phase has begun.
        pub fun hasEnded(): Bool

        pub fun getStart(): UInt64?
        pub fun getEnd(): UInt64?
    }

    // A phase represents a stage of a drop. Some drops will only have one
    // phase, while others could have many. For example, a drop with an allow list
    // and a public mint would likely have two phases.
    pub resource Phase: PhasePublic {
        pub let details: PhaseDetails

        // returns whether this phase of a drop has started.
        pub fun isActive(): Bool {
            return self.details.switcher.hasStarted() && !self.details.switcher.hasEnded()
        }

        pub fun getDetails(): PhaseDetails {
            return self.details
        }

        pub fun borrowSwitchAuth(): auth &{Switcher} {
            return &self.details.switcher as! auth &{Switcher}
        }

        pub fun borrowPricerAuth(): auth &{Pricer} {
            return &self.details.pricer as! auth &{Pricer}
        }

        pub fun borrowAddressVerifierAuth(): auth &{AddressVerifier} {
            return &self.details.addressVerifier as! auth &{AddressVerifier}
        }

        init(details: PhaseDetails) {
            self.details = details
        }
    }

    pub resource interface PhasePublic {
        pub fun getDetails(): PhaseDetails
        pub fun isActive(): Bool
        // What does a phase need to be able to answer/manage?
        // - What are the details of the phase being interactive with?
        // - How many items are left in the current phase?
        // - Can Address x mint on a phase?
        // - What is the cost to mint for the phase I am interested in (for address x)?
    }

    pub struct PhaseDetails {
        // handles whether a phase is on or not
        pub let switcher: {Switcher}

        // display information about a phase
        pub let display: MetadataViews.Display?

        // handles the pricing of a phase
        pub let pricer: {Pricer}

        // verifies whether an address is able to mint
        pub let addressVerifier: {AddressVerifier}

        // placecholder data dictionary to allow new fields to be accessed
        pub let data: {String: AnyStruct}

        init(switcher: {Switcher}, display: MetadataViews.Display?, pricer: {Pricer}, addressVerifier: {AddressVerifier}) {
            self.switcher = switcher
            self.display = display
            self.pricer = pricer
            self.addressVerifier = addressVerifier

            self.data = {}
        }
    }

    pub struct interface AddressVerifier {
        pub fun canMint(addr: Address, num: Int, totalMinted: Int, data: {String: AnyStruct}): Bool {
            return true
        }

        pub fun remainingForAddress(addr: Address, totalMinted: Int): Int? {
            return nil
        }
    }

    pub struct interface Pricer {
        pub fun getPrice(num: Int, paymentTokenType: Type, minter: Address): UFix64
        pub fun getPaymentTypes(): [Type]
    }

    pub resource interface Minter {
        pub fun mint(payment: @FungibleToken.Vault, amount: Int, phase: &Phase, data: {String: AnyStruct}): @[NonFungibleToken.NFT] {
            post {
                phase.details.switcher.hasStarted() && !phase.details.switcher.hasEnded(): "phase is not active"
                result.length == amount: "incorrect number of items returned"
            }
        }
    }
    
    pub struct DropResolver {
        access(self) let cap: Capability<&{ContainerPublic}>

        pub fun borrowContainer(): &{ContainerPublic}? {
            return self.cap.borrow()
        }

        init(cap: Capability<&{ContainerPublic}>) {
            pre {
                cap.check(): "container capability is not valid"
            }

            self.cap = cap
        }
    }

    pub resource interface ContainerPublic {
        pub fun borrowDropPublic(id: UInt64): &{DropPublic}?
        pub fun getIDs(): [UInt64]
    }

    // Contains drops. 
    pub resource Container: ContainerPublic {
        pub let drops: @{UInt64: Drop}

        pub fun addDrop(_ drop: @Drop) {
            let details = drop.getDetails()

            let phases = drop.borrowAllPhases()
            assert(phases.length > 0, message: "drops must have at least one phase to be added to a container")

            let firstPhaseDetails = phases[0].getDetails()

            emit DropAdded(
                address: self.owner!.address,
                id: drop.uuid,
                name: details.display.name,
                description: details.display.description,
                imageUrl: details.display.thumbnail.uri(),
                start: firstPhaseDetails.switcher.getStart(),
                end: firstPhaseDetails.switcher.getEnd()
            )
            destroy self.drops.insert(key: drop.uuid, <-drop)
        }

        pub fun removeDrop(id: UInt64): @Drop {
            pre {
                self.drops.containsKey(id): "drop was not found"
            }

            return <- self.drops.remove(key: id)!
        }

        pub fun borrowDrop(id: UInt64): &Drop? {
            return &self.drops[id] as &Drop?
        }

        pub fun borrowDropPublic(id: UInt64): &{DropPublic}? {
            return &self.drops[id] as &{DropPublic}?
        }

        pub fun getIDs(): [UInt64] {
            return self.drops.keys
        }

        init() {
            self.drops <- {}
        }

        destroy () {
            destroy self.drops
        }
    }

    pub fun createPhase(details: PhaseDetails): @Phase {
        return <- create Phase(details: details)
    }

    pub fun createDrop(details: DropDetails, minterCap: Capability<&{Minter}>, phases: @[Phase]): @Drop {
        return <- create Drop(details: details, minterCap: minterCap, phases: <- phases)
    }

    pub fun createContainer(): @Container {
        return <- create Container()
    }

    init() {
        let identifier = "FlowtyDrops_".concat(self.account.address.toString())
        let containerIdentifier = identifier.concat("_Container")
        let minterIdentifier = identifier.concat("_Minter")

        self.ContainerStoragePath = StoragePath(identifier: containerIdentifier)!
        self.ContainerPublicPath = PublicPath(identifier: containerIdentifier)!

        self.MinterPrivatePath = PrivatePath(identifier: minterIdentifier)!
        self.MinterStoragePath = StoragePath(identifier: minterIdentifier)!
    }
}