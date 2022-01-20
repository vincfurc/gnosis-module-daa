// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.8.0;

import "./Enum.sol";
import "./SignatureDecoder.sol";

interface GnosisSafe {
    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(address to, uint256 value, bytes calldata data, Enum.Operation operation)
        external
        returns (bool success);
    
    function getOwners() external view returns (address[] memory);
}

contract DaaModule is SignatureDecoder {

    address public _whitelisted;
    GnosisSafe public _safe;
    address[] public spenders;

    constructor(address whitelisted, GnosisSafe safe){
        _whitelisted = whitelisted;
        _safe = safe;
        spenders = safe.getOwners();
    }

    



}