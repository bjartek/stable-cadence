
import "ViewResolver"
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


    /// Helper to get Content in a typesafe way
    ///
    /// @param viewResolver: A reference to the resolver resource
    /// @return An optional Display struct
    ///
    access(all) fun getEquipmentContent(_ viewResolver: &{ViewResolver.Resolver}) : Content? {
        if let view = viewResolver.resolveView(Type<Content>()) {
            if let v = view as? Content {
                return v
            }
        }
        return nil
    }

    /// This is a struct to show information for a single item that is equipped
    access(all)
    struct Item {

        access(all)
        let type:String

        access(all)
        let id:UInt64

        access(all)
        let data : {String:String}

        init(type:String, id:UInt64, data: {String:String}) {
            self.type=type
            self.id=id
            self.data=data
        }
    }
}
