
import "NonFungibleToken"

access(all) contract Equipment {

    access(all)
    event Equip(type:String, id:UInt64, equipmentType:String, equipmentId:UInt64, data: {String:String})

    access(all)
    event Unquip(type:String, id:UInt64, equipmentType:String, equipmentId:UInt64, data: {String:String})

    access(all) 
    resource interface Collection {
        access(all) fun getEquipment(type:Type, id:UInt64) : &{NonFungibleToken.NFT}? {
            return nil
        }
    }

    /// Struct meant to be used as a metadata view to signal what Equipment an NFT has
    access(all)
    struct Content {

        access(all)
        let equipment: [Item]

        init(_ items: [Item]) {
            self.equipment=items
        }
    }


    /// This is a struct to show information for a single item that is equipped
    access(all)
    struct Item {

        access(all)
        let type:Type

        access(all)
        let id:UInt64

        access(all)
        let data : {String:String}

        init(type:Type, id:UInt64, data: {String:String}) {
            self.type=type
            self.id=id
            self.data=data
        }
    }
}
