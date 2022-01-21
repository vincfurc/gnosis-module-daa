// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./Enum.sol";



interface GnosisSafe {
    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(address to, uint256 value, bytes calldata data, Enum.Operation operation)
        external
        returns (bool success);
    
     /// @dev Gets list of safe owners
    function getOwners() external view returns (address[] memory);

}

contract DaaModule {
    using EnumerableSet for EnumerableSet.AddressSet;

    address payable public _whitelisted;
    GnosisSafe public _safe;
    EnumerableSet.AddressSet private _spenders;


    event ExecuteTransfer(address indexed safe, address token, address from, address to, uint96 value);
    event ExecuteTransferNFT(address indexed safe, address token, address from, address to, uint96 id);
    event ExecuteTransferERC1155(address indexed safe, address token, address from, address to, uint256 id, uint256 amount);
    
    constructor(address payable whitelisted, GnosisSafe safe){
        _whitelisted = whitelisted;
        _safe = safe;
    }
    

    /// @dev Allows to perform a transfer to the whitelisted address.
    /// @param token Token contract address. Address(0) for ETH transfers.
    /// @param amount Amount that should be transferred.
    function executeTransfer(
        address token,
        uint96 amount
    ) 
        public 
        isAuthorized(msg.sender)
    {
        // Transfer token
        transfer(_safe, token, _whitelisted, amount);
        emit ExecuteTransfer(address(_safe), token, msg.sender, _whitelisted, amount);
    }

    function transfer(GnosisSafe safe, address token, address payable to, uint96 amount) private {
        if (token == address(0)) {
            // solium-disable-next-line security/no-send
            require(safe.execTransactionFromModule(to, amount, "", Enum.Operation.Call), "Could not execute ether transfer");
        } else {
            bytes memory data = abi.encodeWithSignature("transfer(address,uint256)", to, amount);
            require(safe.execTransactionFromModule(token, 0, data, Enum.Operation.Call), "Could not execute token transfer");
        }
    }

    /// @dev Allows to perform a NFT transfer to the whitelisted address.
    /// @param token Token contract address. 
    /// @param id Id of NFT that should be transferred.
    function executeTransferNFT(
        address token,
        uint96 id
    ) 
        public 
        isAuthorized(msg.sender)
    {
        // Transfer token
        transferNFT(_safe, token, _whitelisted, id);
        emit ExecuteTransferNFT(address(_safe), token, msg.sender, _whitelisted, id);
    }

    function transferNFT(GnosisSafe safe, address token, address payable to, uint96 id) private {
        bytes memory data = abi.encodeWithSignature("transferFrom(address,address,uint256)", safe, to, id);
        require(safe.execTransactionFromModule(token, 0, data, Enum.Operation.Call), "Could not execute NFT token transfer");
    }


    /// @dev Allows to perform a ERC1155 transfer to the whitelisted address.
    /// @param token Token contract address. 
    /// @param id Id of ERC1155 that should be transferred.
    /// @param amount Number of tokens that should be transferred.
    function executeTransferERC1155(
        address token,
        uint256 id,
        uint256 amount
    ) 
        public 
        isAuthorized(msg.sender)
    {
        // Transfer token
        transferERC1155(_safe, token, _whitelisted, id, amount);
        emit ExecuteTransferERC1155(address(_safe), token, msg.sender, _whitelisted, id, amount);
    }

    function transferERC1155(GnosisSafe safe, address token, address payable to, uint256 id, uint256 amount) private {
        bytes memory data = abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", safe, to,id, amount, "0x0");
        require(safe.execTransactionFromModule(token, 0, data, Enum.Operation.Call), "Could not execute ERC1155 token transfer");
    }

    modifier isAuthorized(address sender) {
        address[] memory spenders = _safe.getOwners();
        uint256 len = spenders.length;
        for (uint256 i = 0; i < len; i++) {
            address spender = spenders[i];
            require(_spenders.add(spender), "Owner is already registered");
            _spenders.add(spender);
        }
        require(_spenders.contains(sender), "Sender not authorized");
        _;
    }
}