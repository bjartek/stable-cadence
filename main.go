package main

import (
	"fmt"

	"github.com/bjartek/overflow"
)

func main() {
	fmt.Print("\033[H\033[2J")
	o := overflow.Overflow(overflow.WithPrintResults(), overflow.WithFlowForNewUsers(10.0))

	if o.Error != nil {
		panic(o.Error)
	}

	o.Tx("setup", overflow.WithSigner("account"))
	o.Tx("setup", overflow.WithSigner("alice"))

	result := o.Tx("mintNFT",
		overflow.WithSignerServiceAccount(),
		overflow.WithArg("receiver", "account"),
	)

	id, err := result.GetIdFromEvent("Minted", "id")
	if err != nil {
		panic(err)
	}

	cres := o.Tx("mintCompositeNFT",
		overflow.WithSignerServiceAccount(),
		overflow.WithArg("receiver", "alice"),
		overflow.WithArg("basicID", id),
	)

	cid, err := cres.GetIdFromEvent("Minted", "id")
	if err != nil {
		panic(err)
	}
	o.Script("getNFT", overflow.WithArg("address", "alice"), overflow.WithArg("id", cid))

	o.Script("getEquipment",
		overflow.WithArg("address", "alice"),
		overflow.WithArg("id", cid),
		overflow.WithArg("equipmentType", "A.f8d6e0586b0a20c7.BasicNFT.NFT"),
		overflow.WithArg("equipmentId", id),
	)
}
