pragma solidity ^0.4.2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";

//proxy contract that acts as a seller
contract Seller {
    
    SupplyChain supplyChain = SupplyChain(DeployedAddresses.SupplyChain());
    
    function sellerAddItem(string _name, uint _price) public{
        supplyChain.addItem(_name, _price);
    }

    function sellerShipItem(uint _sku) public returns (bool){
        return address(supplyChain).call(abi.encodeWithSignature("shipItem(uint256)"),_sku);
    }

    //to receive ether
    function() external payable {
    }
}

//proxy contract that acts as the buyer
contract Buyer{

    SupplyChain supplyChain = SupplyChain(DeployedAddresses.SupplyChain());

    function buyerBuyItem(uint _sku,uint _price) public payable returns(bool) {
        return address(supplyChain).call.value(_price)(abi.encodeWithSignature("buyItem(uint256)"), _sku);
    }

    function buyerReceiveItem(uint _sku) public returns (bool){
        return address(supplyChain).call(abi.encodeWithSignature("receiveItem(uint256)"),_sku);
    }
    
    //to receive ether
    function() external payable{}
}

//Contract to test the functionalities of Supply Chain Contract
contract TestSupplyChain {
    //Set balance for this contract.
    uint public initialBalance = 5 ether;

    SupplyChain supplyChain = SupplyChain(DeployedAddresses.SupplyChain());
    
    Seller seller = new Seller();
    Buyer buyer = new Buyer();

    //
    Buyer buyer2 = new Buyer();

    address emptyAddress = 0x0000000000000000000000000000000000000000;
    
    //test the ownership of the contract
    function testcheckOwnership() public {
        //address expected = 0;
        Assert.equal(supplyChain.owner(), msg.sender, "The Owner is diffrent from the deployer");
    } 
    
    //to add an item buy seller
    function testAddItem() public{
        
        seller.sellerAddItem("book", 2);
        (string memory name,,uint price,uint state,address s1,address b1) = supplyChain.fetchItem(0);
        
        Assert.equal(name,"book","the name of the last added item does not match the expected value");
        Assert.equal(price,2,"the price of the last added item does not match the expected value");
        Assert.equal(state,0,"the state of the item should be 'For Sale', which should be declared first in the State Enum");
        Assert.equal(s1,address(seller),"the address adding the item should be listed as the seller");
        Assert.equal(b1,emptyAddress,"the buyer address should be set to 0 when an item is added");
    }

    // test for trying to ship an item that is not marked Sold
    function testSellerCantShip() public{
        bool result = seller.sellerShipItem(0);

        Assert.isFalse(result,"Seller was able to ship an item that has not yet been bought by any buyer");
        (,,,uint state,,) = supplyChain.fetchItem(0);
        Assert.equal(state,0,"the state of the item should be 'For Sale'");
    }

    // test for failure if user does not send enough funds
    function testBuyItemForLessCost() public{
        //transfer balance to the buyer addres so he can buy an item
        address(buyer).transfer(1000);

        //buying for price 1 less than the selling price
        bool result = buyer.buyerBuyItem(0,1);
        
        Assert.isFalse(result,"calling Buy item threw an exception-Bought for a less selling price");
        
        (string memory name,,uint price,uint state,address s1,address b1) = supplyChain.fetchItem(0);

        Assert.equal(name,"book","the name of the last added item does not match the expected value");
        Assert.equal(price,2,"the price of the last added item does not match the expected value");
        Assert.equal(state,0,"the state of the item should be 'For Sale'");
        Assert.equal(s1,address(seller),"the address adding the item should be listed as the seller");
        Assert.equal(b1,emptyAddress,"the buyer address should be set to empty");
        Assert.equal(1000,address(buyer).balance,"balance not matched");
    }

    //buy an item
    function testBuyItem() public{
        bool result = buyer.buyerBuyItem(0,3);
        
        Assert.isTrue(result,"calling Buy item threw an exception");
        (string memory name,,uint price,uint state,address s1,address b1) = supplyChain.fetchItem(0);

        Assert.equal(name,"book","the name of the last added item does not match the expected value");
        Assert.equal(price,2,"the price of the last added item does not match the expected value");
        Assert.equal(state,1,"the state of the item should be 'Sold'");
        Assert.equal(s1,address(seller),"the address adding the item should be listed as the seller");
        Assert.equal(b1,address(buyer),"the buyer address should be set 'Buyer Contract' when he purchases an item");
        //to check if he received the excess amount 
        Assert.equal(998,address(buyer).balance,"balance not matched");
    }

    // test for purchasing an item that is not for Sale
    function testBuySoldItem() public{
        //buyer2 tries to buy an item already bought by buyer
        address(buyer2).transfer(1000);

        bool result = buyer2.buyerBuyItem(0,3);

        Assert.isFalse(result,"Bought an item that has been bought by another buyer");
        (,,uint price,uint state,address s1,address b1) = supplyChain.fetchItem(0);
        
        Assert.equal(price, 2 ,"the price of the last added item does not match the expected value");
        Assert.equal(state,1,"the state of the item should be 'Sold'");
        Assert.equal(s1,address(seller),"the address adding the item should be listed as the seller");
        Assert.equal(b1,address(buyer),"the buyer address should be set 'Buyer Contract' when he purchases an item");
        Assert.equal(1000,address(buyer2).balance,"balance not matched");

    }

    // test calling the function on an item not marked Shipped
    function testBuyerCantRecieve() public{
        bool result = buyer.buyerReceiveItem(0);

        Assert.isFalse(result,"buyer recieves an item that has not been shipped");
        (,,,uint state,,) = supplyChain.fetchItem(0);
        Assert.equal(state,1,"the state of the item should be 'Sold'");
    }

    // test for calls that are made by not the seller
    function testFakeSeller() public{
        //Another seller (seller2) trying to ship an Item that is placed by seller
        Seller seller2 = new Seller();
        
        bool result = seller2.sellerShipItem(0);

        Assert.isFalse(result,"Seller2 was able to ship an item of seller");
        (,,,uint state,address s1,) = supplyChain.fetchItem(0);

        Assert.equal(state,1,"the state of the item should be 'Sold'");
        Assert.equal(s1,address(s1),"Seller address is not matching");
    }

    // shipItem
    function testSellerShips() public{
        bool result = seller.sellerShipItem(0);

        Assert.isTrue(result,"Seller was not able to ship an item");
        (,,,uint state,,) = supplyChain.fetchItem(0);
        Assert.equal(state,2,"the state of the item should be 'Shipped'");
    }

    // test calling the function from an address that is not the buyer
    function testFakeBuyer() public{
        //buyer2 trying to recieve an item that has been bought by buyer
        bool result = buyer2.buyerReceiveItem(0);

        Assert.isFalse(result,"buyer2 was able to receive an item bought by buyer");
        
        (,,,uint state,,) = supplyChain.fetchItem(0);
        Assert.equal(state,2,"the state of the item should still be 'Shipped'");
    }

    // receiveItem
    function testBuyerRecieve() public{
        bool result = buyer.buyerReceiveItem(0);

        Assert.isTrue(result,"buy recieves an item that has not been shipped");
        (,,,uint state,,) = supplyChain.fetchItem(0);
        Assert.equal(state,3,"the state of the item should be 'Received'");
    }

}

