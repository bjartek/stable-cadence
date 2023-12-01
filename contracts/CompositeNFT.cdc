import "NonFungibleToken"
import "MetadataViews"
import "ViewResolver"
import "BasicNFT"
import "UniversalCollection"
import "UniversalCollectionMetadata"
import "Equipment"

/// This example NFT uses two abstractions to be very terse
/// - it implements the UniversalCollectionMetadata interfaces that gives it the required top level functions to get and resolve the standard views
//  - the method to create an empty collection uses the UniversalCollection resource to abstract away all standard handling of how to store the NFT
access(all) contract CompositeNFT : UniversalCollectionMetadata{

    access(all) let minterPath : StoragePath
    access(all) event Minted(id: UInt64, uuid: UInt64, to: Address?, type: String)

    access(all) let identifier: String

    /// The only thing that an NFT really needs to have is this resource definition
    access(all) resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver, Equipment.Collection {
        /// Arbitrary trait mapping metadata
        access(self) let metadata: {String: AnyStruct}

        access(self) let subBasic :@{UInt64: BasicNFT.NFT}

        init(
            metadata: {String: AnyStruct},
            child: @BasicNFT.NFT
        ) {
            self.metadata = metadata
            self.subBasic <- {}

            let oldToken <- self.subBasic[child.getID()] <- child
            destroy oldToken
        }

        /// Gets the ID of the NFT, which here is the UUID
        access(all) view fun getID(): UInt64 { return self.uuid }

        access(all) 
        fun getEquipment(type:Type, id:UInt64) : &{NonFungibleToken.NFT}? {

            if type != BasicNFT.NFT.getType() {
                return nil
            }
            return (&self.subBasic[id] as &{NonFungibleToken.NFT}?)
        }

        /// Uses the basic NFT views
        access(all) view fun getViews(): [Type] {
            return [
            Type<MetadataViews.Display>(),
            Type<MetadataViews.Traits>(),
            Type<MetadataViews.NFTCollectionDisplay>(),
            Type<MetadataViews.NFTCollectionData>(),
            Type<Equipment.Content>()
            ]
        }

        access(all) fun resolveView(_ view: Type): AnyStruct? {
            switch view {
            case Type<MetadataViews.Display>():
                return MetadataViews.Display(
                    name: (self.metadata["name"] as! String?)!,
                    description: (self.metadata["description"] as! String?)!,
                    thumbnail: MetadataViews.HTTPFile(
                        url: (self.metadata["thumbnail"] as! String?)!
                    )
                )
            case Type<MetadataViews.Traits>():
                return MetadataViews.dictToTraits(dict: self.metadata, excludedNames: nil)
            case Type<MetadataViews.NFTCollectionData>():
                return CompositeNFT.getCollectionData()
            case Type<MetadataViews.NFTCollectionDisplay>():
                return CompositeNFT.getCollectionDisplay()
            case Type<Equipment.Content>():
                let id=self.subBasic.keys[0]
                let typ=Type<@BasicNFT.NFT>().identifier
                let item = Equipment.Item(type:typ, id:id, data:{})
                return Equipment.Content([item])
            }
            return nil
        }

        destroy() {
            destroy <- self.subBasic
        }
    }


    access(all) view fun getCollectionDisplay() : MetadataViews.NFTCollectionDisplay {

        let media = MetadataViews.Media(
            file: MetadataViews.HTTPFile(
                url: "https://assets.website-files.com/5f6294c0c7a8cdd643b1c820/5f6294c0c7a8cda55cb1c936_Flow_Wordmark.svg"
            ),
            mediaType: "image/svg+xml"
        )
        return MetadataViews.NFTCollectionDisplay(
            name: "The Example Collection",
            description: "This collection is used as an example to help you develop your next Flow NFT.",
            externalURL: MetadataViews.ExternalURL("https://example-nft.onflow.org"),
            squareImage: media,
            bannerImage: media,
            socials: {
                "twitter": MetadataViews.ExternalURL("https://twitter.com/flow_blockchain")
            }
        )
    }

    access(all) resource Minter {
        access(all) fun mintNFT(metadata: {String: AnyStruct}, receiver : &{NonFungibleToken.Receiver}, child : @BasicNFT.NFT){
            let nft <- create NFT(metadata: metadata, child: <- child)
            emit Minted(id: nft.getID(), uuid:nft.uuid, to: receiver.owner?.address, type: Type<@CompositeNFT.NFT>().identifier)
            receiver.deposit(token: <- nft)
        }
    }

    access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
        return <- UniversalCollection.createEmptyCollection(identifier: self.identifier, type: Type<@CompositeNFT.NFT>())
    }

    init() {
        let minter <- create Minter()
        self.identifier="compositeNFT"

        self.minterPath=/storage/compositeNFTMinter
        self.account.storage.save(<-minter, to: self.minterPath)
    }
}

