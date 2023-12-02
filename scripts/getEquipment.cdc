import "CompositeNFT"
import "NonFungibleToken"
import "MetadataViews"
import "Equipment"

/// This script gets all the view-based metadata associated with the specified NFT
/// and returns it as a single struct

access(all) struct NFT {
    access(all) let name: String
    access(all) let description: String
    access(all) let thumbnail: String
    access(all) let owner: Address
    access(all) let type: String
    access(all) let equipment: Equipment.Content?

    init(
        name: String,
        description: String,
        thumbnail: String,
        owner: Address,
        nftType: String,
        equipment:Equipment.Content?
    ) {
        self.name = name
        self.description = description
        self.thumbnail = thumbnail
        self.owner = owner
        self.type = nftType
        self.equipment=equipment
    }
}

access(all) fun main(address: Address, id: UInt64, equipmentType: String, equipmentId: UInt64): MetadataViews.Display {
    let account = getAccount(address)

    let collectionData = CompositeNFT.resolveView(Type<MetadataViews.NFTCollectionData>()) as! MetadataViews.NFTCollectionData? ?? panic("ViewResolver does not resolve NFTCollectionData view")

    let collection = account.capabilities.borrow<&{NonFungibleToken.Collection}>(collectionData.publicPath) ?? panic("Could not borrow a reference to the collection")

    let nft = collection.borrowNFT(id) as! &{Equipment.Collection}

    let typ = CompositeType(equipmentType)!
    let item =nft.getEquipment(type: typ, id: equipmentId)!
    return  MetadataViews.getDisplay(item)!
}
