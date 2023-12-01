
import "NonFungibleToken"

access(all) contract ComplexNFT {

    access(all) resource interface NFT {

        access(all) fun getSubNFTBy(type:Type, id:UInt64) : &{NonFungibleToken.NFT}? {
            return nil
        }

    }

    access(all)
    struct Content {

        access(all)
        let subNFTS: { Type: [UInt64] }

        init(_ subNFTS: {Type: [UInt64]}) {
            self.subNFTS=subNFTS
        }


    }
}
