
import "NonFungibleToken"
import "BasicNFT"
import "UniversalCollection"
import "MetadataViews"

transaction {

    prepare(signer: AuthAccount) {
        let collectionData = BasicNFT.getCollectionData()
        // Return early if the account already has a collection
        if signer.borrow<&{NonFungibleToken.Collection}>(from: collectionData.storagePath) != nil {
            return
        }

        // Create a new empty collection
        let collection <- BasicNFT.createEmptyCollection()

        // save it to the account
        signer.save(<-collection, to: collectionData.storagePath)

        // create a public capability for the collection
        signer.link<&{NonFungibleToken.Collection}>( collectionData.publicPath, target: collectionData.storagePath)

        let minter =signer.borrow<&BasicNFT.Minter>(from: /storage/basicNFTMinter)
    }
}
