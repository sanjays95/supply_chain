pragma solidity ^0.4.2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";
contract Seller {
    
    function  sellerAddItem(string _name, uint _price) public{
        SupplyChain supplyChain = SupplyChain(DeployedAddresses.SupplyChain());
        supplyChain.addItem(_name, _price);
    }

    function sellerShipItem(uint _sku) public returns (bool){
        SupplyChain supplyChain = SupplyChain(DeployedAddresses.SupplyChain());
        supplyChain.call(abi.encodeWithSignature("shipItem(uint)"),_sku);
    }
}
contract Buyer{

    function buyerBuyItem(uint _sku,uint _price) public payable {
        SupplyChain supplyChain = SupplyChain(DeployedAddresses.SupplyChain());
        supplyChain.buyItem.value(_price)(_sku);
        //address(supplyChain).call.value(_price)(abi.encodeWithSignature("buyItem(uint256)"), _sku);
    }

    function buyerReceiveItem(uint _sku) public returns (bool){
        SupplyChain supplyChain = SupplyChain(DeployedAddresses.SupplyChain());
        return supplyChain.call(abi.encodeWithSignature("receiveItem(uint)"),_sku);
    }
    
    function() external payable{}
}
contract TestSupplyChain {

    uint public initialBalance=10000 wei;

    // Test for failing conditions in this contracts
    // test that every modifier is working
    function testcheckOwnership() public {
        SupplyChain supplyChain = SupplyChain(DeployedAddresses.SupplyChain());
        
        //address expected = 0;
        Assert.equal(supplyChain.owner(), msg.sender, "The Owner is diffrent from the deployer");
    } 
    
    function testAddItem() public{
        SupplyChain supplyChain = SupplyChain(DeployedAddresses.SupplyChain());
        
        Seller seller = new Seller();
        address emptyAddress = 0x0000000000000000000000000000000000000000;
        seller.sellerAddItem("book", 1);
        (string memory name,uint sku,uint price,uint state,address s1,address b1) = supplyChain.fetchItem(0);
        //fetchItem(0);
        Assert.equal(name,"book","the name of the last added item does not match the expected value");
        Assert.equal(price, 1 ,"the price of the last added item does not match the expected value");
        Assert.equal(state,0,"the state of the item should be 'For Sale', which should be declared first in the State Enum");
        Assert.equal(s1,address(seller),"the address adding the item should be listed as the seller");
        Assert.equal(b1,emptyAddress,"the buyer address should be set to 0 when an item is added");
    }
    function testBuyItem() public{
        SupplyChain supplyChain = SupplyChain(DeployedAddresses.SupplyChain());

        Buyer buyer = new Buyer();
        address(buyer).transfer(1000);
        //(string memory name,uint sku,uint price,uint state,address s1,address b1) = supplyChain.fetchItem(0);
        Assert.equal(address(this).balance,9000,"test contract has some balance");
        Assert.equal(address(buyer).balance,1000,"buyer contract has some balance");
        

        buyer.buyerBuyItem(0,100);
        (string memory name,uint sku,uint price,uint state,address s1,address b1) = supplyChain.fetchItem(0);
        
    
        //Assert.equal(name,"book","the name of the last added item does not match the expected value");
        //Assert.equal(state,1,"the state of the item should be 'Sold', which should be declared second in the State Enum");
        //Assert.equal(b1,address(buyer),"the buyer address should be set 'Buyer Contract' when he purchases an item");
    }

    // test for failure if user does not send enough funds
    // test for purchasing an item that is not for Sale
        

    // shipItem

    // test for calls that are made by not the seller
    // test for trying to ship an item that is not marked Sold

    // receiveItem

    // test calling the function from an address that is not the buyer
    // test calling the function on an item not marked Shipped
}

