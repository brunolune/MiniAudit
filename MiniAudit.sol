// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0; // ^0.5.12; -> compiler's pragma need to be fixed
                       // to avoid incompatibilities with further compiler versions.
                       
//import is needed to use SafeMath:
import "https://github.com/OpenZeppelin/openzeppelin-contracts/contracts/utils/math/SafeMath.sol";

// This contract is supposed to be a Crowdsale but its purpose seems to be receiving ethers from investors
// and sending the ether to a escrow contract, not distributing tokens, it is confusing...
// This contract is supposed to define an owner and an escrow account, a function to receive ether and send
// this ether to the escrow account and a function to withdraw the ether balance. However it cannot work 
// cause ethers are sent to the escrow account and cannot be withdrawn from the Crowdsale contract ...
// The most meaningful to do with this contract is a bank-like contract where we can deposit ethers
// and  withdraw them ... 

contract Crowdsale {
    using SafeMath for uint256;
    
    // definition of contract's owner is useless in this contract
    address public owner; // the owner of the contract
    // it is not clear if escrow is a contract or a regular account
    // to receive payment on an address, it must be declared as payable ...
    // address public escrow; // wallet to collect raised ETH
    address payable public escrow; // wallet to collect raised ETH

    // Unnecessary to initialize variables to their default value, it costs gas for nothing:
    // uint256 public savedBalance = 0; // Total amount raised in ETH
    uint256 public savedBalance; // Total amount raised in ETH
    mapping (address => uint256) public balances; // Balances in incoming Ether
 
    // initialization should be done with a constructor at deployment 
    // it is not allowed for a function to have the same name as the contract
    // Anyone can change the owner in the proposed contract... So I change it to define owner
    // to be the account deploying the contract:
    // Initialization
    //   function Crowdsale(address _escrow) public{
    constructor (address payable _escrow) {
        // tx.origin is not recommanded to use anymore since it can be used
        // for exploits since it refers to the first caller whereas msg.sender to the last 
        // owner = tx.origin;
        owner=msg.sender;
        // add address of the specific contract
        escrow = _escrow; 
   }
   
    // Preferably use receive() function to receive ether cause function() or fallback()
    // should be used in case no corresponding functions were found in the contract and
    // can lead to unexpected behavior.
    // function to receive ETH
    // function() public { // This is the 'default function' or 'fallback function':
    receive() payable external {
        balances[msg.sender] = balances[msg.sender].add(msg.value);
        savedBalance = savedBalance.add(msg.value);
        // escrow.send(msg.value) should be used with bool to verify success of transaction
        // send() can fail sending but does not cause revert and can fail due to insufficient 
        // gas (if tx > 2300 gas), for that reason 
        // (bool sent,)=call{value:msg.sender}("") is to be used for more secure transfer
        // However it makes no sense to send the ethers to another address if we want to be
        // able to withdraw them, so I comment this part:
        //escrow.send(msg.value);
    }
  
    // refund investisor
    function withdrawPayments() public{
        // we need to verify that balances[msg.sender] is enough:
        require(balances[msg.sender]>0,"nothing to withdraw");
        // this assignment is not necessary (not efficient and address must be payable)
        // address payee = msg.sender;
        // uint256 payment = balances[payee];
        uint256 payment = balances[msg.sender];
        
        savedBalance = savedBalance.sub(payment);
        // balances[payee] = 0;
        balances[msg.sender] =0 ;
        // payee.send(payment); has to be replaced by:
        // payee.transfer(payment) which causes a revert in case of failure
        // or by:
       
        (bool sent,) = payable(msg.sender).call{value: balances[msg.sender]}("");
        require(sent,"Sent failure!");
    
        // these state modifications should be placed before the send
        // otherwise the function withdrawPayment can be used for a reentrancy attack
        // savedBalance = savedBalance.sub(payment);
        // balances[payee] = 0;
   }
}
