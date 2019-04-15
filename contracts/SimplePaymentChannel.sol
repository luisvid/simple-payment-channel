pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

/**
 * @title SimplePaymentChannel
 * @author 
 *
 * @dev Ethereum payment channels allow for off-chain transactions with an on-chain
 * settlement. In this implementation, a party (sender) can open a channel with a 
 * deposit, expiration, and recipient. The sender can then sign transactions off-chain
 * and send them to the recipient, who can submit one of these signed transactions to 
 * chain to close and settle the channel.
 */
contract SimplePaymentChannel {
    using SafeMath for uint256;
    // using ECRecovery for bytes32;

    //============================================================================
    // EVENTS
    //============================================================================

    event ChannelOpened(address sender, address recipient, uint expiration, uint256 deposit);
    event ChannelClosed(uint256 senderBalance, uint256 recipientBalance);

    // Creator of channel
    address payable public sender;
    // Recipient of channel
    address payable public recipient;
    // When sender can close the channel
    uint256 public expiration;

    //============================================================================
    // PUBLIC FUNCTIONS
    //============================================================================

    /**
    * @dev Constructor
    * @param _recipient address Address of the receiving party
    * @param _duration uint256 Time period past creation that defines expiration
    */
    constructor(address payable _recipient, uint256 _duration) public payable {
        // sanity checks
        require(msg.value > 0);
        require(msg.sender != _recipient);

        sender = msg.sender;
        recipient = _recipient;
        expiration = now + _duration;

        emit ChannelOpened(sender, recipient, expiration, msg.value);
    }

    /**
    * @dev Close a channel with a signed message from the sender
    * @param _balance uint256 The balance agreed to by the sender in their signed message
    * @param _signedMessage bytes The signed hash of the balance by the sender
    */
    function closeChannel(uint256 _balance, bytes memory _signedMessage) public {
        // only recipient can call closeChannel
        require(msg.sender == recipient);
        require(isValidSignature(_balance, _signedMessage));

        // temp vars for calculating sender and recipient remittances
        uint256 balance = _balance;
        uint256 remainder = 0;

        // if _balance > address(this).balance, send address(this).balance to recipient
        if (_balance > address(this).balance) {
            balance = address(this).balance;
        } else {
            remainder = address(this).balance.sub(balance);
        }

        // remit payment to recipient
        recipient.transfer(balance);

        emit ChannelClosed(remainder, balance);

        // remit remainder to sender
        selfdestruct(sender);
    }

    /**
    * @dev Extend the expiration date of the channel
    * @param _expiration uint256 Updated expiration date
    */
    function extendExpiration(uint256 _expiration) public {
        // only sender can call extendExpiration
        require(msg.sender == sender);
        require(_expiration > expiration);

        // update expiration
        expiration = _expiration;
    }

    /**
    * @dev Allows sender to claim channel balance if expired
    */
    function claimTimeout() public {
        // must be beyond expiration date
        require(now >= expiration);

        // remit payment to sender
        selfdestruct(sender);
    }

    //============================================================================
    // INTERNAL FUNCTIONS
    //============================================================================

    /**
    * @dev Derive and verify sender address from signed message and message hash
    * @param _balance uint256 The balance agreed to by the sender in their signed message
    * @param _signedMessage bytes The signed hash of the balance by the sender
    */
    function isValidSignature(uint256 _balance, bytes memory _signedMessage)
        internal
        view
        returns (bool)
    {
        bytes32 message = prefixed(keccak256(abi.encodePacked(address(this), _balance)));

        // check that the signature is from the payment sender
        // return message.recover(_signedMessage) == sender;

        // Check that the signature is from the payment sender.
        return recoverSigner(message, _signedMessage) == sender;
    }

    // 
    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    // 
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }


    /**
    * @dev Builds a prefixed hash to mimic the behavior of eth_sign
    * @param _hash bytes32 Message hash to be prefixed
    */
    function prefixed(bytes32 _hash)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
    }
}