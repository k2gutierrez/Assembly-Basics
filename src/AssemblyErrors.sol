// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title AssemblyErrors - Error Handling and Control Flow in Assembly
/// @author Blockchain Accelerator - Carlos Gutiérrez
/// @notice Learn how reverts, requires, and overflow checks work at the EVM level.
///
/// ====================================================================
/// HOW ERRORS WORK UNDER THE HOOD
/// ====================================================================
///
/// When Solidity does `require(condition, "message")`, it compiles to:
///   1. Check the condition
///   2. If false, encode an Error(string) and call `revert(offset, size)`
///
/// The `revert(offset, size)` opcode:
///   - Stops execution
///   - Reverts all state changes
///   - Returns `size` bytes of data starting at memory `offset`
///   - The returned data is the error message (ABI encoded)
///
/// Error(string) ABI encoding:
///   [0x08c379a0] [offset=32] [length] [string bytes...]
///    ^selector   ^ABI encoding of the string parameter
///
/// Custom errors (e.g., `error Overflow()`) use their own 4-byte selector
/// and are more gas-efficient because they skip string encoding.
///
contract AssemblyErrors {
    // ─── Custom Errors ─────────────────────────────
    error Overflow();
    error ConditionFailed();

    // ═══════════════════════════════════════════════════════════════════════
    // SECTION 1: REVERT WITH ERROR STRING
    // ═══════════════════════════════════════════════════════════════════════

    /// @notice Revert with a custom Error(string) message, built manually in assembly
    /// @dev This does the same thing as `revert("Some error message")` but shows
    /// how the ABI encoding works step by step.
    ///
    /// Memory layout for Error(string):
    ///   0x00: 0x08c379a0  (Error(string) selector)
    ///   0x04: 0x20        (offset to string data = 32)
    ///   0x24: length      (string byte length)
    ///   0x44: string data (padded to 32 bytes)
    function revertWithMessage() external pure {
        assembly {
            // Store the Error(string) selector at position 0x00
            // We store it as a full 32-byte word, so the selector occupies bytes 0-3
            mstore(0x00, 0x08c379a000000000000000000000000000000000000000000000000000000000)
            // Offset to string data (32 = 0x20)
            mstore(0x04, 0x20)
            // String length (14 bytes = "Assembly error")
            mstore(0x24, 14)
            // String data: "Assembly error"
            mstore(0x44, 0x417373656d626c79206572726f72000000000000000000000000000000000000)
            // Revert with 100 bytes of data (4 + 32 + 32 + 32)
            revert(0x00, 0x64)
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // SECTION 2: REQUIRE PATTERN IN ASSEMBLY
    // ═══════════════════════════════════════════════════════════════════════

    /// @notice Require a condition to be true, revert with custom error if not
    /// @dev The `if iszero(condition) { revert(...) }` pattern is how
    /// Solidity's `require()` works under the hood.
    ///
    /// Custom error encoding is simpler and cheaper than Error(string):
    ///   Just the 4-byte selector, no string data needed.
    function requireInAssembly(bool condition) external pure {
        assembly {
            // if condition is false (iszero returns 1)...
            if iszero(condition) {
                // Store ConditionFailed() selector
                mstore(0x00, 0x0b1ad13b00000000000000000000000000000000000000000000000000000000)
                // Revert with just 4 bytes (the selector)
                revert(0x00, 0x04)
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // SECTION 3: SAFE MATH IN ASSEMBLY
    // ═══════════════════════════════════════════════════════════════════════
    //
    // Solidity 0.8+ has built-in overflow checks, but they add gas cost.
    // In assembly, you can write your own checks that are sometimes cheaper,
    // especially if you can skip checks you know are unnecessary.
    //

    /// @notice Safe addition with overflow check
    /// @dev How to detect overflow: if a + b < a, it overflowed.
    /// In assembly: add(a, b) wraps on overflow, so if result < a, it wrapped.
    function safeAdd(uint256 a, uint256 b) external pure returns (uint256 result) {
        assembly {
            result := add(a, b)
            // If result < a, overflow occurred (b was positive but result wrapped)
            if lt(result, a) {
                // Store Overflow() selector and revert
                mstore(0x00, 0x35278d1200000000000000000000000000000000000000000000000000000000)
                revert(0x00, 0x04)
            }
        }
    }

    /// @notice Safe multiplication with overflow check
    /// @dev How to detect overflow: if a != 0 and a * b / a != b, it overflowed.
    /// Special case: if a == 0, result is 0 (no overflow possible).
    function safeMul(uint256 a, uint256 b) external pure returns (uint256 result) {
        assembly {
            result := mul(a, b)
            // Check: if a != 0 AND result / a != b, then overflow
            if and(
                iszero(iszero(a)), // a != 0
                iszero(eq(div(result, a), b)) // result / a != b
            ) {
                mstore(0x00, 0x35278d1200000000000000000000000000000000000000000000000000000000)
                revert(0x00, 0x04)
            }
        }
    }
}
