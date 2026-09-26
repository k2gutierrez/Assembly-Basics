// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title AssemblyUtils - Practical Assembly Patterns
/// @author Blockchain Accelerator - Carlos Gutiérrez
/// @notice Real-world use cases where assembly gives you capabilities
/// or gas savings that pure Solidity cannot match.
///
/// ====================================================================
/// WHY USE ASSEMBLY IN PRACTICE?
/// ====================================================================
///
/// 1. ACCESS EVM-ONLY FEATURES:
///    - `extcodesize` - check if address is a contract
///    - `balance` - get ETH balance without interface
///    - `caller`, `origin` - message sender context
///    - `coinbase`, `timestamp`, `number` - block info
///
/// 2. GAS OPTIMIZATION:
///    - Pack/unpack multiple values in one storage slot
///    - Avoid ABI encoding overhead for hashing
///    - Skip unnecessary checks when you know data is valid
///
/// 3. LOW-LEVEL CONTROL:
///    - Manual memory management
///    - Custom ABI encoding/decoding
///    - Delegate calls with precise control
///
contract AssemblyUtils {

    // ═══════════════════════════════════════════════════════════════════════
    // SECTION 1: ENVIRONMENT INFORMATION
    // ═══════════════════════════════════════════════════════════════════════

    /// @notice Get the ETH balance of any address
    /// @dev `balance(addr)` returns the wei balance.
    /// In Solidity you'd use `address(x).balance`, which compiles to the
    /// same opcode, but in assembly you have direct access.
    function getBalance(address addr) external view returns (uint256 bal) {
        assembly {
            bal := balance(addr)
        }
    }

    /// @notice Get the code size of an address (0 for EOAs)
    /// @dev `extcodesize(addr)` returns the size of code at `addr`.
    /// - EOAs (wallets) have code size 0
    /// - Contracts have code size > 0
    ///
    /// WARNING: During a constructor, a contract's extcodesize is 0!
    /// So this check is not reliable during construction.
    function getCodeSize(address addr) external view returns (uint256 size) {
        assembly {
            size := extcodesize(addr)
        }
    }

    /// @notice Check if an address is a contract
    /// @dev Returns true if extcodesize > 0.
    /// This is a very common pattern used in libraries like OpenZeppelin's
    /// Address.isContract(). Uses `iszero(iszero(x))` to convert to bool.
    function isContract(address addr) external view returns (bool result) {
        assembly {
            // extcodesize returns a number, iszero(iszero(x)) normalizes to 0 or 1
            result := gt(extcodesize(addr), 0)
        }
    }

    /// @notice Get msg.sender and tx.origin
    /// @dev Shows the difference between `caller()` and `origin()`:
    ///   - `caller()` = msg.sender (immediate caller, can be a contract)
    ///   - `origin()` = tx.origin (always the EOA that started the tx)
    ///
    /// Example: EOA -> ContractA -> ContractB
    ///   In ContractB: caller() = ContractA, origin() = EOA
    function getCallerAndOrigin() external view returns (address msgSender, address txOrigin) {
        assembly {
            msgSender := caller()
            txOrigin := origin()
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // SECTION 2: EFFICIENT HASHING
    // ═══════════════════════════════════════════════════════════════════════

    /// @notice Hash bytes data using keccak256 in assembly
    /// @dev `keccak256(offset, size)` hashes `size` bytes starting at `offset` in memory.
    ///
    /// In Solidity: keccak256(abi.encodePacked(data)) first copies data to memory,
    /// then hashes. In assembly, if data is already in memory (like calldata),
    /// we can hash it directly, saving gas on the copy step.
    ///
    /// Here we hash two uint256 values packed together (64 bytes total).
    function efficientHash(uint256 a, uint256 b) external pure returns (bytes32 result) {
        assembly {
            // Use scratch space (0x00-0x3F) for hashing - Solidity reserves this area
            mstore(0x00, a)      // Store `a` at memory position 0x00 (32 bytes)
            mstore(0x20, b)      // Store `b` at memory position 0x20 (32 bytes)
            result := keccak256(0x00, 0x40) // Hash 64 bytes starting at 0x00
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // SECTION 3: BIT PACKING - Store Multiple Values in One Slot
    // ═══════════════════════════════════════════════════════════════════════
    //
    // Storage is expensive (~20,000 gas per slot). If you have two values
    // that each fit in 128 bits, you can pack them into ONE 256-bit slot
    // instead of using two slots. This saves ~20,000 gas!
    //
    // Layout: [  upper 128 bits (a)  |  lower 128 bits (b)  ]
    //

    /// @notice Pack two uint128 values into a single uint256
    /// @dev Steps:
    ///   1. Shift `a` left by 128 bits to put it in the upper half
    ///   2. OR with `b` (which occupies the lower half)
    ///   Result: [aaaa...aaaa | bbbb...bbbb]
    function packTwo128(uint128 a, uint128 b) external pure returns (uint256 packed) {
        assembly {
            // Shift `a` to upper 128 bits, OR with `b` in lower 128 bits
            packed := or(shl(128, a), b)
        }
    }

    /// @notice Unpack a uint256 into two uint128 values
    /// @dev Steps:
    ///   1. Shift right 128 bits to extract `a` (upper half)
    ///   2. AND with a 128-bit mask to extract `b` (lower half)
    ///
    /// The mask 0xFFFF...FFFF (128 bits) isolates only the lower half.
    function unpackTwo128(uint256 packed) external pure returns (uint128 a, uint128 b) {
        assembly {
            // Extract upper 128 bits by shifting right
            a := shr(128, packed)
            // Extract lower 128 bits by masking with 128-bit mask
            // 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF = (2^128 - 1)
            b := and(packed, 0xffffffffffffffffffffffffffffffff)
        }
    }

}