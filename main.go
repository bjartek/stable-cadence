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

	o.Tx("setup", overflow.WithSigner("alice"))
	o.Tx("setup", overflow.WithSigner("bob"))
	message("We have started the emulator, deployed our BasicNFT and created two tests users alice and bob")
	pause()

	message("We create a minter for alice")
	// We create a minter and give it to alice
	aliceMinter := "basicNFTMinterAlice"
	o.Tx("giveMinter",
		overflow.WithSignerServiceAccount(),
		overflow.WithArg("receiver", "alice"),
		overflow.WithArg("name", aliceMinter),
	)

	message("Alice claim the minter")
	// Alice claims the minter from her inbox
	o.Tx("claimMinter",
		overflow.WithSigner("alice"),
		overflow.WithArg("name", aliceMinter),
		overflow.WithArg("provider", "account"),
	)

	message("Alice mint an NFT to bob")
	// We mint the NFT as this admin
	o.Tx("mintNFTAsAdmin",
		overflow.WithSigner("alice"),
		overflow.WithArg("receiver", "bob"),
	)

	pause()

	message("We create a minter for bob")
	// bob is a minter
	bobMinter := "basicNFTMinterBob"
	o.Tx("giveMinter",
		overflow.WithSignerServiceAccount(),
		overflow.WithArg("receiver", "bob"),
		overflow.WithArg("name", bobMinter),
	)

	// bob claims the minter from his inbox
	message("Bob claim the minter")
	o.Tx("claimMinter",
		overflow.WithSigner("bob"),
		overflow.WithArg("name", bobMinter),
		overflow.WithArg("provider", "account"),
	)

	message("Bob mints an NFT to himself")
	// We mint the NFT as this admin
	o.Tx("mintNFTAsAdmin",
		overflow.WithSigner("bob"),
		overflow.WithArg("receiver", "bob"),
	)

	pause()

	message("We revoke the minter given to alice")
	// the admin revokes the permission
	o.Tx("revokeMinter",
		overflow.WithSignerServiceAccount(),
		overflow.WithArg("name", aliceMinter))

	message("We mint an NFT as bob again")

	// bob should still be able to mint
	// we get an error minting again
	o.Tx("mintNFTAsAdmin",
		overflow.WithSigner("bob"),
		overflow.WithArg("receiver", "bob"),
	)

	message("Now when we go to the next step we expect it to fail to mint as alice")
	pause()

	// we get an error minting
	o.Tx("mintNFTAsAdmin",
		overflow.WithSigner("alice"),
		overflow.WithArg("receiver", "bob"),
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
