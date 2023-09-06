import FungibleToken from "./utility/FungibleToken.cdc"
import NonFungibleToken from "./utility/NonFungibleToken.cdc"


access(all) contract NFTStorefrontV2 {

    access(all) event StorefrontInitialized(storefrontResourceID: UInt64)
    access(all) event StorefrontDestroyed(storefrontResourceID: UInt64)
    access(all) event ListingAvailable(
        storefrontAddress: Address,
        listingResourceID: UInt64,
        nftType: Type,
        nftUUID: UInt64, 
        nftID: UInt64,
        salePaymentVaultType: Type,
        salePrice: UFix64,
        customID: String?,
        commissionAmount: UFix64,
        commissionReceivers: [Address]?,
        expiry: UInt64
    )

    access(all) event ListingCompleted(
        listingResourceID: UInt64, 
        storefrontResourceID: UInt64, 
        purchased: Bool,
        nftType: Type,
        nftUUID: UInt64,
        nftID: UInt64,
        salePaymentVaultType: Type,
        salePrice: UFix64,
        customID: String?,
        commissionAmount: UFix64,
        commissionReceiver: Address?,
        expiry: UInt64
    )

    access(all) event UnpaidReceiver(receiver: Address, entitledSaleCut: UFix64)
    access(all) let StorefrontStoragePath: StoragePath
    access(all) let StorefrontPublicPath: PublicPath

    access(all) struct SaleCut {
        access(all) let receiver: Capability<&{FungibleToken.Receiver}>
        access(all) let amount: UFix64
        init(receiver: Capability<&{FungibleToken.Receiver}>, amount: UFix64) {
            self.receiver = receiver
            self.amount = amount
        }
    }

    access(all) resource Listing {

        pub var storefrontID: UInt64
        pub var purchased: Bool
        pub let nftType: Type
        pub let nftUUID: UInt64
        pub let nftID: UInt64
        pub let salePaymentVaultType: Type
        pub let salePrice: UFix64
        pub let saleCuts: [SaleCut]
        pub var customID: String?
        pub let commissionAmount: UFix64
        pub let expiry: UInt64

        access(contract) let nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
        access(contract) let marketplacesCapability: [Capability<&{FungibleToken.Receiver}>]?

        access(all) fun borrowNFT(): &NonFungibleToken.NFT? {
            let ref = self.nftProviderCapability.borrow()!.borrowNFT(id: self.nftID)
            if ref.isInstance(self.nftType) && ref.id == self.nftID {
                return ref as &NonFungibleToken.NFT?  
            } 
            return nil
        }

        access(all) fun getAllowedCommissionReceivers(): [Capability<&{FungibleToken.Receiver}>]? {
            return self.marketplacesCapability
        }

        access(all) fun purchase(
            payment: @FungibleToken.Vault, 
            commissionRecipient: Capability<&{FungibleToken.Receiver}>?,
        ): @NonFungibleToken.NFT {

            pre {
                self.purchased == false: "listing has already been purchased"
                payment.isInstance(self.salePaymentVaultType): "payment vault is not requested fungible token"
                payment.balance == self.salePrice: "payment vault does not contain requested price"
                self.expiry > UInt64(getCurrentBlock().timestamp): "Listing is expired"
                self.owner != nil : "Resource doesn't have the assigned owner"
            }

            self.purchased = true

            if self.commissionAmount > 0.0 {
                let commissionReceiver = commissionRecipient ?? panic("Commission recipient can't be nil")
                if self.marketplacesCapability != nil {
                    var isCommissionRecipientHasValidType = false
                    var isCommissionRecipientAuthorised = false
                    for cap in self.marketplacesCapability! {
                        // Check 1: Should have the same type
                        if cap.getType() == commissionReceiver.getType() {
                            isCommissionRecipientHasValidType = true
                            // Check 2: Should have the valid market address that holds approved capability.
                            if cap.address == commissionReceiver.address && cap.check() {
                                isCommissionRecipientAuthorised = true
                                break
                            }
                        }
                    }
                    assert(isCommissionRecipientHasValidType, message: "Given recipient does not has valid type")
                    assert(isCommissionRecipientAuthorised,   message: "Given recipient has not authorised to receive the commission")
                }
                let commissionPayment <- payment.withdraw(amount: self.commissionAmount)
                let recipient = commissionReceiver.borrow() ?? panic("Unable to borrow the recipent capability")
                recipient.deposit(from: <- commissionPayment)
            }

            let nft <-self.nftProviderCapability.borrow()!.withdraw(withdrawID: self.nftID)

            assert(nft.isInstance(self.nftType), message: "withdrawn NFT is not of specified type")
            assert(nft.id == self.nftID, message: "withdrawn NFT does not have specified ID")

            let storeFrontPublicRef = self.owner!.getCapability<&NFTStorefrontV2.Storefront{NFTStorefrontV2.StorefrontPublic}>(NFTStorefrontV2.StorefrontPublicPath)
            .borrow() ?? panic("Unable to borrow the storeFrontManager resource")
            let duplicateListings = storeFrontPublicRef.getDuplicateListingIDs(nftType: self.nftType, nftID: self.nftID, listingID: self.uuid)

            for listingID in duplicateListings {
                storeFrontPublicRef.cleanup(listingResourceID: listingID)
            }

            var residualReceiver: &{FungibleToken.Receiver}? = nil

            for cut in self.saleCuts {
                if let receiver = cut.receiver.borrow() {
                    let paymentCut <- payment.withdraw(amount: cut.amount)
                    receiver.deposit(from: <-paymentCut)
                    if (residualReceiver == nil) {
                        residualReceiver = receiver
                    }
                } else {
                    emit UnpaidReceiver(receiver: cut.receiver.address, entitledSaleCut: cut.amount)
                }
            }

            assert(residualReceiver != nil, message: "No valid payment receivers")

            residualReceiver!.deposit(from: <-payment)

            emit ListingCompleted(
                listingResourceID: self.uuid,
                storefrontResourceID: self.storefrontID,
                purchased: self.purchased,
                nftType: self.nftType,
                nftUUID: self.nftUUID,
                nftID: self.nftID,
                salePaymentVaultType: self.salePaymentVaultType,
                salePrice: self.salePrice,
                customID: self.customID,
                commissionAmount: self.commissionAmount,
                commissionReceiver: self.commissionAmount != 0.0 ? commissionRecipient!.address : nil,
                expiry: self.expiry
            )

            return <-nft
        }

        destroy () {

            if !self.purchased {
                emit ListingCompleted(
                    listingResourceID: self.uuid,
                    storefrontResourceID: self.storefrontID,
                    purchased: self.purchased,
                    nftType: self.nftType,
                    nftUUID: self.nftUUID,
                    nftID: self.nftID,
                    salePaymentVaultType: self.salePaymentVaultType,
                    salePrice: self.salePrice,
                    customID: self.customID,
                    commissionAmount: self.commissionAmount,
                    commissionReceiver: nil,
                    expiry: self.expiry
                )
            }
        }

        init (
            nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>,
            nftType: Type,
            nftUUID: UInt64,
            nftID: UInt64,
            salePaymentVaultType: Type,
            saleCuts: [SaleCut],
            marketplacesCapability: [Capability<&{FungibleToken.Receiver}>]?,
            storefrontID: UInt64,
            customID: String?,
            commissionAmount: UFix64,
            expiry: UInt64
        ) {

            pre {
                // Validate the expiry
                expiry > UInt64(getCurrentBlock().timestamp): "Expiry should be in the future"
                // Validate the length of the sale cut
                saleCuts.length > 0: "Listing must have at least one payment cut recipient"
            }

            self.nftType = nftType,
            self.nftUUID = nftUUID,
            self.nftID = nftID,
            self.salePaymentVaultType = salePaymentVaultType,
            self.saleCuts = saleCuts,
            self.storefrontID = storefrontID,
            self.customID = customID,
            self.commissionAmount = commissionAmount,
            self.expiry =  expiry

            var salePrice = commissionAmount
            for cut in self.saleCuts {
                cut.receiver.borrow()
                ?? panic("Cannot borrow receiver")
                salePrice = salePrice + cut.amount
            }
            assert(salePrice > 0.0, message: "Listing must have non-zero price")
            self.salePrice = salePrice

            self.nftProviderCapability = nftProviderCapability
            self.marketplacesCapability = marketplacesCapability

            let provider = self.nftProviderCapability.borrow()
            assert(provider != nil, message: "cannot borrow nftProviderCapability")

            let nft = provider!.borrowNFT(id: self.nftID)
            assert(nft.isInstance(self.nftType), message: "token is not of specified type")
            assert(nft.id == self.nftID, message: "token does not have specified ID")
        }
    }

    //entitlements: StorefrontManager

    pub resource Storefront  {
        access(contract) var listings: @{UInt64: Listing}
        access(contract) var listedNFTs: {String: {UInt64 : [UInt64]}}

        access(StorefrontManager) fun createListing(
            nftProviderCapability: Capability<&{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>,
            nftType: Type,
            nftID: UInt64,
            salePaymentVaultType: Type,
            saleCuts: [SaleCut],
            marketplacesCapability: [Capability<&{FungibleToken.Receiver}>]?,
            customID: String?,
            commissionAmount: UFix64,
            expiry: UInt64
        ): UInt64 {

            let collectionRef = nftProviderCapability.borrow()
            ?? panic("Could not borrow reference to collection")
            let nftRef = collectionRef.borrowNFT(id: nftID)

            let uuid = nftRef.uuid
            let listing <- create Listing(
                nftProviderCapability: nftProviderCapability,
                nftType: nftType,
                nftUUID: uuid,
                nftID: nftID,
                salePaymentVaultType: salePaymentVaultType,
                saleCuts: saleCuts,
                marketplacesCapability: marketplacesCapability,
                storefrontID: self.uuid,
                customID: customID,
                commissionAmount: commissionAmount,
                expiry: expiry
            )

            let listingResourceID = listing.uuid
            let listingPrice = listing.salePrice
            let oldListing <- self.listings[listingResourceID] <- listing

            destroy oldListing

            self.addDuplicateListing(nftIdentifier: nftType.identifier, nftID: nftID, listingResourceID: listingResourceID)

            var allowedCommissionReceivers : [Address]? = nil
            if let allowedReceivers = marketplacesCapability {
                allowedCommissionReceivers = []
                for receiver in allowedReceivers {
                    allowedCommissionReceivers!.append(receiver.address)
                }
            }

            emit ListingAvailable(
                storefrontAddress: self.owner?.address!,
                listingResourceID: listingResourceID,
                nftType: nftType,
                nftUUID: uuid,
                nftID: nftID,
                salePaymentVaultType: salePaymentVaultType,
                salePrice: listingPrice,
                customID: customID,
                commissionAmount: commissionAmount,
                commissionReceivers: allowedCommissionReceivers,
                expiry: expiry
            )

            return listingResourceID
        }

        access(StorefrontManager) fun removeListing(listingResourceID: UInt64) {
            let listing <- self.listings.remove(key: listingResourceID)
            ?? panic("missing Listing")
            self.removeDuplicateListing(nftIdentifier: listing.nftType.identifier, nftID: listing.nftID, listingResourceID: listingResourceID)
            // This will emit a ListingCompleted event.
            destroy listing
        }

        access(contract) fun addDuplicateListing(nftIdentifier: String, nftID: UInt64, listingResourceID: UInt64) {
            if !self.listedNFTs.containsKey(nftIdentifier) {
                self.listedNFTs.insert(key: nftIdentifier, {nftID: [listingResourceID]})
            } else {
                if !self.listedNFTs[nftIdentifier]!.containsKey(nftID) {
                    self.listedNFTs[nftIdentifier]!.insert(key: nftID, [listingResourceID])
                } else {
                    self.listedNFTs[nftIdentifier]![nftID]!.append(listingResourceID)
                } 
            }
        }

        access(contract) fun removeDuplicateListing(nftIdentifier: String, nftID: UInt64, listingResourceID: UInt64) {
            let listingIndex = self.listedNFTs[nftIdentifier]![nftID]!.firstIndex(of: listingResourceID) ?? panic("Should contain the index")
            self.listedNFTs[nftIdentifier]![nftID]!.remove(at: listingIndex)
        }

        access(contract) fun cleanup(listingResourceID: UInt64) {
            pre {
                self.listings[listingResourceID] != nil: "could not find listing with given id"
            }
            let listing <- self.listings.remove(key: listingResourceID)!
            self.removeDuplicateListing(nftIdentifier: listing.nftType.identifier, nftID: listing.nftID, listingResourceID: listingResourceID)

            destroy listing
        }


        access(all) view fun getListingIDs(): [UInt64] {
            return self.listings.keys
        }

        access(all) fun getExistingListingIDs(nftType: Type, nftID: UInt64): [UInt64] {
            if self.listedNFTs[nftType.identifier] == nil || self.listedNFTs[nftType.identifier]![nftID] == nil {
                return []
            }
            var listingIDs = self.listedNFTs[nftType.identifier]![nftID]!
            return listingIDs
        }


        access(all) fun cleanupPurchasedListings(listingResourceID: UInt64) {
            pre {
                self.listings[listingResourceID] != nil: "could not find listing with given id"
                self.borrowListing(listingResourceID: listingResourceID)!.purchased == true: "listing not purchased yet"
            }
            let listing <- self.listings.remove(key: listingResourceID)!
            self.removeDuplicateListing(nftIdentifier: listing.nftType.identifier, nftID: listing.nftID, listingResourceID: listingResourceID)

            destroy listing
        }


        access(all) fun getDuplicateListingIDs(nftType: Type, nftID: UInt64, listingID: UInt64): [UInt64] {
            var listingIDs = self.getExistingListingIDs(nftType: nftType, nftID: nftID)

            // Verify that given listing Id also a part of the `listingIds`
            let doesListingExist = listingIDs.contains(listingID)
            // Find out the index of the existing listing.
            if doesListingExist {
                var index: Int = 0
                for id in listingIDs {
                    if id == listingID {
                        break
                    }
                    index = index + 1
                }
                listingIDs.remove(at:index)
                return listingIDs
            } 
            return []
        }


        access(all) fun cleanupExpiredListings(fromIndex: UInt64, toIndex: UInt64) {
            pre {
                fromIndex <= toIndex : "Incorrect start index"
                Int(toIndex - fromIndex) < self.getListingIDs().length : "Provided range is out of bound"
            }
            var index = fromIndex
            let listingsIDs = self.getListingIDs()
            while index <= toIndex {
                // There is a possibility that some index may not have the listing.
                // becuase of that instead of failing the transaction, Execution moved to next index or listing.

                if let listing = self.borrowListing(listingResourceID: listingsIDs[index]) {
                    if listing.expiry <= UInt64(getCurrentBlock().timestamp) {
                        self.cleanup(listingResourceID: listingsIDs[index])
                    }
                }
                index = index + UInt64(1) 
            }
        } 


        access(all) view fun borrowListing(listingResourceID: UInt64): &Listing{ListingPublic}? {
            return &self.listings[listingResourceID]
        }


        destroy () {
            emit StorefrontDestroyed(storefrontResourceID: self.uuid)
        }

        init () {
            self.listings <- {}
            self.listedNFTs = {}
            emit StorefrontInitialized(storefrontResourceID: self.uuid)
        }
    }

    access(all) fun createStorefront(): @Storefront {
        return <-create Storefront()
    }

    init () {
        self.StorefrontStoragePath = /storage/NFTStorefrontV2
        self.StorefrontPublicPath = /public/NFTStorefrontV2
    }
}

