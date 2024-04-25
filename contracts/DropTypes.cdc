import "FlowtyDrops"
import "MetadataViews"
import "ViewResolver"

pub contract DropTypes {
    pub struct Display {
        pub let name: String
        pub let description: String
        pub let url: String

        init(_ display: MetadataViews.Display) {
            self.name = display.name
            self.description = display.description
            self.url = display.thumbnail.uri()
        }
    }

    pub struct Media {
        pub let url: String
        pub let mediaType: String

        init(_ media: MetadataViews.Media) {
            self.url = media.file.uri()
            self.mediaType = media.mediaType
        }
    }

    pub struct DropSummary {
        pub let id: UInt64
        pub let display: Display
        pub let medias: [Media]
        pub let totalMinted: Int
        pub let minterCount: Int
        pub let commissionRate: UFix64
        pub let nftType: String

        pub let address: Address?
        pub let mintedByAddress: Int?

        pub let phases: [PhaseSummary]

        pub let blockTimestamp: UInt64
        pub let blockHeight: UInt64

        init(
            id: UInt64,
            display: MetadataViews.Display,
            medias: MetadataViews.Medias?,
            totalMinted: Int,
            minterCount: Int,
            mintedByAddress: Int?,
            commissionRate: UFix64,
            nftType: Type,
            address: Address?,
            phases: [PhaseSummary]
        ) {
            self.id = id
            self.display = Display(display)
            
            self.medias = []
            for m in medias?.items ?? [] {
                self.medias.append(Media(m))
            }


            self.totalMinted = totalMinted
            self.commissionRate = commissionRate
            self.minterCount = minterCount
            self.mintedByAddress = mintedByAddress
            self.nftType = nftType.identifier
            self.address = address
            self.phases = phases

            let b = getCurrentBlock()
            self.blockHeight = b.height
            self.blockTimestamp = UInt64(b.timestamp)
        }
    }

    pub struct Quote {
        pub let price: UFix64
        pub let quantity: Int
        pub let paymentIdentifier: String
        pub let minter: Address

        init(price: UFix64, quantity: Int, paymentIdentifier: String, minter: Address) {
            self.price = price
            self.quantity = quantity
            self.paymentIdentifier = paymentIdentifier
            self.minter = minter
        }
    }

    pub struct PhaseSummary {
        pub let id: UInt64
        pub let index: Int

        pub let switcherType: String
        pub let pricerType: String
        pub let addressVerifierType: String

        pub let hasStarted: Bool
        pub let hasEnded: Bool
        pub let start: UInt64?
        pub let end: UInt64?

        pub let paymentTypes: [String]
        
        pub let address: Address?
        pub let remainingForAddress: Int?

        pub let quote: Quote?

        init(
            index: Int,
            phase: &{FlowtyDrops.PhasePublic},
            address: Address?,
            totalMinted: Int?,
            minter: Address?,
            quantity: Int?,
            paymentIdentifier: String?
        ) {
            self.index = index
            self.id = phase.uuid

            let d = phase.getDetails()
            self.switcherType = d.switcher.getType().identifier
            self.pricerType = d.pricer.getType().identifier
            self.addressVerifierType = d.addressVerifier.getType().identifier

            self.hasStarted = d.switcher.hasStarted()
            self.hasEnded = d.switcher.hasEnded()
            self.start = d.switcher.getStart()
            self.end = d.switcher.getEnd()

            self.paymentTypes = []
            for pt in d.pricer.getPaymentTypes() {
                self.paymentTypes.append(pt.identifier)
            }

            if let addr = address {
                self.address = address
                self.remainingForAddress = d.addressVerifier.remainingForAddress(addr: addr, totalMinted: totalMinted ?? 0)
            } else {
                self.address = nil
                self.remainingForAddress = nil
            }

            if paymentIdentifier != nil && quantity != nil {
                let price = d.pricer.getPrice(num: quantity!, paymentTokenType: CompositeType(paymentIdentifier!)!, minter: minter)

                self.quote = Quote(price: price, quantity: quantity!, paymentIdentifier: paymentIdentifier!, minter: minter!)
            } else {
                self.quote = nil
            }
        }
    }

    pub fun getDropSummary(contractAddress: Address, contractName: String, dropID: UInt64, minter: Address?, quantity: Int?, paymentIdentifier: String?): DropSummary? {
        let resolver = getAccount(contractAddress).contracts.borrow<&ViewResolver>(name: contractName)
        if resolver == nil {
            return nil
        }

        let dropResolver = resolver!.resolveView(Type<FlowtyDrops.DropResolver>()) as! FlowtyDrops.DropResolver?
        if dropResolver == nil {
            return nil
        }

        let container = dropResolver!.borrowContainer()
        if container == nil {
            return nil
        }

        let drop = container!.borrowDropPublic(id: dropID)
        if drop == nil {
            return nil
        }

        let dropDetails = drop!.getDetails()

        let phaseSummaries: [PhaseSummary] = []
        for index, phase in drop!.borrowAllPhases() {
            let summary = PhaseSummary(
                index: index,
                phase: phase,
                address: minter,
                totalMinted: minter != nil ? dropDetails.minters[minter!] : nil,
                minter: minter,
                quantity: quantity,
                paymentIdentifier: paymentIdentifier
            )
            phaseSummaries.append(summary)
        }

        let dropSummary = DropSummary(
            id: drop!.uuid,
            display: dropDetails.display,
            medias: dropDetails.medias,
            totalMinted: dropDetails.totalMinted,
            minterCount: dropDetails.minters.keys.length,
            mintedByAddress: minter != nil ? dropDetails.minters[minter!] : nil,
            commissionRate: dropDetails.commissionRate,
            nftType: dropDetails.nftType,
            address: minter,
            phases: phaseSummaries
        )

        return dropSummary
    }

    pub fun getAllDropSummaries(contractAddress: Address, contractName: String, minter: Address?, quantity: Int?, paymentIdentifier: String?): [DropSummary] {
        let resolver = getAccount(contractAddress).contracts.borrow<&ViewResolver>(name: contractName)
        if resolver == nil {
            return []
        }

        let dropResolver = resolver!.resolveView(Type<FlowtyDrops.DropResolver>()) as! FlowtyDrops.DropResolver?
        if dropResolver == nil {
            return []
        }

        let container = dropResolver!.borrowContainer()
        if container == nil {
            return []
        }

        let summaries: [DropSummary] = []
        for id in container!.getIDs() {
            let drop = container!.borrowDropPublic(id: id)
            if drop == nil {
                continue
            }

            let dropDetails = drop!.getDetails()

            let phaseSummaries: [PhaseSummary] = []
            for index, phase in drop!.borrowAllPhases() {
                let summary = PhaseSummary(
                    index: index,
                    phase: phase,
                    address: minter,
                    totalMinted: minter != nil ? dropDetails.minters[minter!] : nil,
                    minter: minter,
                    quantity: quantity,
                    paymentIdentifier: paymentIdentifier
                )
                phaseSummaries.append(summary)
            }

            summaries.append(DropSummary(
                id: drop!.uuid,
                display: dropDetails.display,
                medias: dropDetails.medias,
                totalMinted: dropDetails.totalMinted,
                minterCount: dropDetails.minters.keys.length,
                mintedByAddress: minter != nil ? dropDetails.minters[minter!] : nil,
                commissionRate: dropDetails.commissionRate,
                nftType: dropDetails.nftType,
                address: minter,
                phases: phaseSummaries
            ))
        }

        return summaries
    }
}