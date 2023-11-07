import MetadataViews from "MetadataViews"
import NonFungibleToken from "NonFungibleToken"
import UniversalCollection from "UniversalCollection"

access(all) contract interface UniversalCollectionMetadata {

    access(all)  identifier: String

    access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection}

    access(all) view fun getCollectionDisplay() : MetadataViews.NFTCollectionDisplay

    /// Return the NFT types that the contract defines
    access(all) view fun getNFTTypes(): [Type] {
        return [
        self.getType()
        ]
    }

    access(all) view fun getCollectionData() : MetadataViews.NFTCollectionData {
        return MetadataViews.NFTCollectionData(
            storagePath: StoragePath(identifier: self.identifier)!,
            publicPath: PublicPath(identifier: self.identifier)!,
            providerPath: PrivatePath(identifier: self.identifier)!,
            publicCollection: Type<&UniversalCollection.Collection>(),
            publicLinkedType: Type<&UniversalCollection.Collection>(),
            providerLinkedType: Type<auth(NonFungibleToken.Withdrawable) &UniversalCollection.Collection>(),
            createEmptyCollectionFunction: (fun(): @{NonFungibleToken.Collection} {
                return <-self.createEmptyCollection()
            })
        )
    }

    /// Function that returns all the Metadata Views implemented by a Non Fungible Token
    ///
    /// @return An array of Types defining the implemented views. This value will be used by
    ///         developers to know which parameter to pass to the resolveView() method.
    ///
    access(all) view fun getViews(): [Type] {
        return [
        Type<MetadataViews.NFTCollectionData>(),
        Type<MetadataViews.NFTCollectionDisplay>()
        ]
    }


    /// Function that resolves a metadata view for this contract.
    ///
    /// @param view: The Type of the desired view.
    /// @return A structure representing the requested view.
    ///
    access(all) fun resolveView(_ view: Type): AnyStruct? {
        switch view {
        case Type<MetadataViews.NFTCollectionData>():
            return self.getCollectionData()
        case Type<MetadataViews.NFTCollectionDisplay>():
            return self.getCollectionDisplay()
        }
        return nil
    }

}
