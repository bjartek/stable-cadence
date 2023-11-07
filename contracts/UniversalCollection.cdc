/* 
*
* This is an example collection that can store any one type of NFT
* See BasicNFT for an stupid implementation
*/

import "NonFungibleToken"
import "MetadataViews"
import "ViewResolver"

access(all) contract UniversalCollection {

    access(all) resource Collection: NonFungibleToken.Collection {

        /// every Universal collection supports a single type
        access(all) let supportedType : Type

        access(contract) var ownedNFTs: @{UInt64: {NonFungibleToken.NFT}}

        access(self) var storagePath: StoragePath
        access(self) var publicPath: PublicPath

        /// Return the default storage path for the collection
        access(all) view fun getDefaultStoragePath(): StoragePath? {
            return self.storagePath
        }

        /// Return the default public path for the collection
        access(all) view fun getDefaultPublicPath(): PublicPath? {
            return self.publicPath
        }

        init (identifier: String, type:Type) {
            self.ownedNFTs <- {}
            self.supportedType = type
            self.storagePath = StoragePath(identifier: identifier)!
            self.publicPath = PublicPath(identifier: identifier)!
        }

        /// getSupportedNFTTypes returns a list of NFT types that this receiver accepts
        access(all) view fun getSupportedNFTTypes(): {Type: Bool} {
            let supportedTypes: {Type: Bool} = {}
            supportedTypes[self.supportedType] = true
            return supportedTypes
        }

        /// Returns whether or not the given type is accepted by the collection
        /// A collection that can accept any type should just return true by default
        access(all) view fun isSupportedNFTType(type: Type): Bool {
            if type == self.supportedType {
                return true
            } else {
                return false
            }
        }

        /// Indicates that the collection is using UUID to key the NFT dictionary
        access(all) view fun usesUUID(): Bool {
            return true
        }

        /// withdraw removes an NFT from the collection and moves it to the caller
        access(NonFungibleToken.Withdrawable) fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT} {
            let token <- self.ownedNFTs.remove(key: withdrawID)
            ?? panic("Could not withdraw an NFT with the provided ID from the collection")

            return <-token
        }

        /// withdrawWithUUID removes an NFT from the collection, using its UUID, and moves it to the caller
        access(NonFungibleToken.Withdrawable) fun withdrawWithUUID(_ uuid: UInt64): @{NonFungibleToken.NFT} {
            return <-self.withdraw(withdrawID: uuid)
        }

        /// withdrawWithType removes an NFT from the collection, using its Type and ID and moves it to the caller
        /// This would be used by a collection that can store multiple NFT types
        access(NonFungibleToken.Withdrawable) fun withdrawWithType(type: Type, withdrawID: UInt64): @{NonFungibleToken.NFT} {
            return <-self.withdraw(withdrawID: withdrawID)
        }

        /// withdrawWithTypeAndUUID removes an NFT from the collection using its type and uuid and moves it to the caller
        /// This would be used by a collection that can store multiple NFT types
        access(NonFungibleToken.Withdrawable) fun withdrawWithTypeAndUUID(type: Type, uuid: UInt64): @{NonFungibleToken.NFT} {
            return <-self.withdraw(withdrawID: uuid)
        }

        /// deposit takes a NFT and adds it to the collections dictionary
        /// and adds the ID to the id array
        access(all) fun deposit(token: @{NonFungibleToken.NFT}) {
            if self.supportedType != token.getType() {
                panic("Not supported")
            }

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[token.getID()] <- token

            destroy oldToken
        }

        /// Function for a direct transfer instead of having to do a deposit and withdrawal
        ///
        access(NonFungibleToken.Withdrawable) fun transfer(id: UInt64, receiver: Capability<&{NonFungibleToken.Receiver}>): Bool {
            let token <- self.withdraw(withdrawID: id)

            let displayView = token.resolveView(Type<MetadataViews.Display>())! as! MetadataViews.Display

            // If we can't borrow a receiver reference, don't panic, just return the NFT
            // and return true for an error
            if let receiverRef = receiver.borrow() {

                receiverRef.deposit(token: <-token)

                return false
            } else {
                self.deposit(token: <-token)
                return true
            }
        }

        /// getIDs returns an array of the IDs that are in the collection
        access(all) view fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        /// getLength retusnt the number of items in the collection
        access(all) view fun getLength(): Int {
            return self.ownedNFTs.length
        }

        access(all) view fun getIDsWithTypes(): {Type: [UInt64]} {
            let typeIDs: {Type: [UInt64]} = {}
            typeIDs[self.supportedType] = self.getIDs()
            return typeIDs
        }

        /// borrowNFT gets a reference to an NFT in the collection
        /// so that the caller can read its metadata and call its methods
        access(all) view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT} {
            let nftRef = (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)
            ?? panic("Could not borrow a reference to an NFT with the specified ID")

            return nftRef
        }

        access(all) view fun borrowNFTSafe(id: UInt64): &{NonFungibleToken.NFT}? {
            return (&self.ownedNFTs[id] as &{NonFungibleToken.NFT}?)
        }

        /// Borrow the view resolver for the specified NFT ID
        access(all) view fun borrowViewResolver(id: UInt64): &{ViewResolver.Resolver}? {
            return (&self.ownedNFTs[id] as &{ViewResolver.Resolver}?)!
        }

        /// public function that anyone can call to create a new empty collection
        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            panic("cannot call create emptyCollection of universal collection")
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    /// public function that anyone can call to create a new empty collection
    /// Since multiple collection types can be defined in a contract,
    /// The caller needs to specify which one they want to create
    access(all) fun createEmptyCollection(identifier: String, type: Type): @{NonFungibleToken.Collection} {
        return <- create Collection(identifier: identifier, type:type)
    }

}

