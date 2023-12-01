package main

import (
	"fmt"

	"github.com/bjartek/overflow"
	"github.com/fatih/color"
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

	o.Tx("mintCompositeNFT",
		overflow.WithSignerServiceAccount(),
		overflow.WithArg("receiver", "alice"),
		overflow.WithArg("basicID", id),
	)
}

func pause() {
	fmt.Println()
	color.Yellow("press any key to continue")
	fmt.Scanln()
	fmt.Print("\033[H\033[2J")
}

func message(msg string) {
	fmt.Println()
	color.Green(msg)
}
