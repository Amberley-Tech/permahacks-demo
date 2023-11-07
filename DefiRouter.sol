// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

// Command implementations
import {Dispatcher} from "./Dispatcher.sol";
import {RouterParameters, RouterImmutables} from "./base/RouterImmutables.sol";
import {Commands} from "./utils/Commands.sol";
import {IDefiRouter} from "./interfaces/IDefiRouter.sol";

contract DefiRouter is RouterImmutables, IDefiRouter, Dispatcher {
    modifier checkDeadline(uint256 deadline) {
        if (block.timestamp > deadline) revert TransactionDeadlinePassed();
        _;
    }

    constructor(RouterParameters memory params) RouterImmutables(params) {}

    /// @inheritdoc IDefiRouter
    function execute(
        bytes calldata commands,
        bytes[] calldata inputs,
        uint256 deadline
    ) external payable checkDeadline(deadline) {
        execute(commands, inputs);
    }

    /// @inheritdoc Dispatcher
    function execute(
        bytes calldata commands,
        bytes[] calldata inputs
    ) public payable override isNotLocked {
        bool success;
        bytes memory output;
        uint256 numCommands = commands.length;
        if (inputs.length != numCommands) revert LengthMismatch();

        // loop through all given commands, execute them and pass along outputs as defined
        for (uint256 commandIndex = 0; commandIndex < numCommands; ) {
            bytes1 command = commands[commandIndex];

            bytes calldata input = inputs[commandIndex];

            (success, output) = dispatch(command, input);

            if (!success && successRequired(command)) {
                revert ExecutionFailed({
                    commandIndex: commandIndex,
                    message: output
                });
            }

            unchecked {
                commandIndex++;
            }
        }
    }

    function successRequired(bytes1 command) internal pure returns (bool) {
        return command & Commands.FLAG_ALLOW_REVERT == 0;
    }

    /// @notice To receive ETH from WETH
    receive() external payable {}
}
