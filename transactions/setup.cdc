
import "NonFungibleToken"
import "BasicNFT"
import "CompositeNFT"
import "UniversalCollection"
import "MetadataViews"

transaction {

    prepare(signer: auth(BorrowValue, IssueStorageCapabilityController, PublishCapability, SaveValue) &Account) {
        let collectionData = BasicNFT.getCollectionData()
        // Return early if the account already has a collection
        if signer.storage.borrow<&{NonFungibleToken.Collection}>(from: collectionData.storagePath) != nil {
            return
        }

        // Create a new empty collection
        let collection <- BasicNFT.createEmptyCollection()

        // save it to the account
        signer.storage.save(<-collection, to: collectionData.storagePath)

        // create a public capability for the collection
        let collectionCap= signer.capabilities.storage.issue<&{NonFungibleToken.Collection}>( collectionData.storagePath)
        signer.capabilities.publish(collectionCap, at: collectionData.publicPath)

        let ccollectionData = CompositeNFT.getCollectionData()
        // Return early if the account already has a collection
        if signer.storage.borrow<&{NonFungibleToken.Collection}>(from: ccollectionData.storagePath) != nil {
            return
        }

        // Create a new empty collection
        let ccollection <- CompositeNFT.createEmptyCollection()

        // save it to the account
        signer.storage.save(<-ccollection, to: ccollectionData.storagePath)

        // create a public capability for the collection
        let ccollectionCap= signer.capabilities.storage.issue<&{NonFungibleToken.Collection}>( collectionData.storagePath)
        signer.capabilities.publish(ccollectionCap, at: ccollectionData.publicPath)


    }
}
