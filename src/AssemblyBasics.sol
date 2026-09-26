// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title AssemblyBasics - Core Assembly (Yul) Operations
/// @author Blockchain Accelerator - Carlos Gutiérrez
/// @notice Learn the fundamental EVM opcodes through inline assembly.
///
/// ====================================================================
/// WHAT IS INLINE ASSEMBLY (YUL)?
/// ====================================================================
///
/// Solidity compiles to EVM bytecode, but sometimes you want direct
/// control over the EVM. Inline assembly lets you write "Yul" code
/// inside Solidity functions using the `assembly { ... }` block.
///
/// WHY USE IT?
///   1. Gas optimization - skip Solidity's safety checks when you know
///      the operation is safe
///   2. Access EVM features Solidity doesn't expose (e.g., raw storage
///      slots, specific opcodes like extcodesize, coinbase, etc.)
///   3. Understand how Solidity works under the hood
///
/// THE EVM HAS 3 DATA LOCATIONS:
///   - Stack:   Temporary values during computation (max 1024 items)
///   - Memory:  Temporary byte array, erased between external calls
///   - Storage: Persistent key-value store (256-bit key -> 256-bit value)
///
/// IMPORTANT: Assembly bypasses Solidity's safety features (overflow
/// checks, bounds checking, etc.). Use it carefully!
///
contract AssemblyBasics {
    
    // ═══════════════════════════════════════════════════════════════════════
    // SECTION 1: STORAGE - Persistent Data (sstore / sload)
    // ═══════════════════════════════════════════════════════════════════════

    /// @notice Store a value at a specific storage slot
    /// @dev `sstore(slot, value)` writes `value` to storage `slot`.
    /// In Solidity, each state variable gets a slot automatically.
    /// With assembly, you can write to ANY slot directly.
    ///
    /// Gas cost: ~20,000 for first write to a slot, ~5,000 for updates
    function store(uint256 slot, uint256 value) external {
        assembly {
            sstore(slot, value)
        }
    }

    /// @notice Load a value from a specific storage slot
    /// @dev `sload(slot)` reads the 256-bit value from storage `slot`.
    /// Returns 0 if the slot has never been written to.
    ///
    /// Gas cost: ~2,100 for first read (cold), ~100 for subsequent (warm)
    function load(uint256 slot) external view returns (uint256 result) {
        assembly {
            result := sload(slot)
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // SECTION 2: ARITHMETIC - Math Operations
    // ═══════════════════════════════════════════════════════════════════════
    //
    // These opcodes operate on 256-bit unsigned integers.
    // IMPORTANT: Unlike Solidity 0.8+, assembly arithmetic does NOT
    // revert on overflow! It wraps around silently (modular arithmetic).
    //

    /// @notice Add two numbers: a + b
    /// @dev `add(a, b)` - If result > 2^256-1, it wraps around (no revert!)
    function assemblyAdd(uint256 a, uint256 b) external pure returns (uint256 result) {
        assembly {
            result := add(a, b)
        }
    }

    /// @notice Subtract: a - b
    /// @dev `sub(a, b)` - If b > a, wraps to a huge number (no revert!)
    function assemblySub(uint256 a, uint256 b) external pure returns (uint256 result) {
        assembly {
            result := sub(a, b)
        }
    }

    /// @notice Multiply: a * b
    /// @dev `mul(a, b)` - Overflow wraps silently
    function assemblyMul(uint256 a, uint256 b) external pure returns (uint256 result) {
        assembly {
            result := mul(a, b)
        }
    }

    /// @notice Divide: a / b (integer division, rounds down)
    /// @dev `div(a, b)` - Division by zero returns 0 (does NOT revert!)
    function assemblyDiv(uint256 a, uint256 b) external pure returns (uint256 result) {
        assembly {
            result := div(a, b)
        }
    }

    /// @notice Modulo: a % b
    /// @dev `mod(a, b)` - Modulo by zero returns 0 (does NOT revert!)
    function assemblyMod(uint256 a, uint256 b) external pure returns (uint256 result) {
        assembly {
            result := mod(a, b)
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // SECTION 3: BITWISE OPERATIONS
    // ═══════════════════════════════════════════════════════════════════════
    //
    // The EVM works with 256-bit words. Bitwise operations are extremely
    // gas-efficient (3 gas each) and are the foundation of:
    //   - Packing multiple values into one storage slot
    //   - Permission systems (bitmasks)
    //   - Efficient flag checking
    //

    /// @notice Bitwise AND: a & b
    /// @dev Each bit is 1 only if BOTH corresponding bits are 1.
    /// Common use: masking - extract specific bits from a value.
    /// Example: 0xFF & 0x0F = 0x0F (extract lower 4 bits)
    function bitwiseAnd(uint256 a, uint256 b) external pure returns (uint256 result) {
        assembly {
            result := and(a, b)
        }
    }

    /// @notice Bitwise OR: a | b
    /// @dev Each bit is 1 if EITHER corresponding bit is 1.
    /// Common use: setting flags/bits.
    /// Example: 0xF0 | 0x0F = 0xFF
    function bitwiseOr(uint256 a, uint256 b) external pure returns (uint256 result) {
        assembly {
            result := or(a, b)
        }
    }

    /// @notice Bitwise XOR: a ^ b
    /// @dev Each bit is 1 if the corresponding bits DIFFER.
    /// Common use: toggling bits, simple encryption.
    /// Property: a ^ b ^ b = a (XOR is its own inverse!)
    function bitwiseXor(uint256 a, uint256 b) external pure returns (uint256 result) {
        assembly {
            result := xor(a, b)
        }
    }

    /// @notice Bitwise NOT: ~a (flip all 256 bits)
    /// @dev `not(a)` flips every bit: 0 becomes 1, 1 becomes 0.
    /// For uint256: not(a) = type(uint256).max - a
    function bitwiseNot(uint256 a) external pure returns (uint256 result) {
        assembly {
            result := not(a)
        }
    }

    /// @notice Shift left: a << bits
    /// @dev `shl(bits, value)` - NOTE the parameter order in Yul!
    /// Yul order: shl(shift, value) vs Solidity: value << shift
    /// Shifting left by N is the same as multiplying by 2^N.
    function shiftLeft(uint256 value, uint256 bits) external pure returns (uint256 result) {
        assembly {
            // Note: Yul uses (shift, value) order, opposite of Solidity!
            result := shl(bits, value)
        }
    }

    /// @notice Shift right: a >> bits
    /// @dev `shr(bits, value)` - logical shift right (fills with zeros)
    /// Shifting right by N is the same as dividing by 2^N.
    function shiftRight(uint256 value, uint256 bits) external pure returns (uint256 result) {
        assembly {
            result := shr(bits, value)
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // SECTION 4: COMPARISON OPERATIONS
    // ═══════════════════════════════════════════════════════════════════════
    //
    // Comparisons return 1 (true) or 0 (false) as uint256.
    //

    /// @notice Check if value is zero
    /// @dev `iszero(x)` returns 1 if x == 0, else 0.
    /// Very common in assembly for boolean logic: iszero(iszero(x)) = bool(x)
    function isZero(uint256 value) external pure returns (bool result) {
        assembly {
            result := iszero(value)
        }
    }

    /// @notice Check if a < b (unsigned)
    /// @dev `lt(a, b)` returns 1 if a < b, else 0
    function lessThan(uint256 a, uint256 b) external pure returns (bool result) {
        assembly {
            result := lt(a, b)
        }
    }

    /// @notice Check if a > b (unsigned)
    /// @dev `gt(a, b)` returns 1 if a > b, else 0
    function greaterThan(uint256 a, uint256 b) external pure returns (bool result) {
        assembly {
            result := gt(a, b)
        }
    }

    /// @notice Check if a == b
    /// @dev `eq(a, b)` returns 1 if a equals b, else 0
    function equalTo(uint256 a, uint256 b) external pure returns (bool result) {
        assembly {
            result := eq(a, b)
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // SECTION 5: MEMORY OPERATIONS (mstore / mload)
    // ═══════════════════════════════════════════════════════════════════════
    //
    // Memory is a temporary byte array that exists only during a transaction.
    // It's addressed by byte offset and reads/writes in 32-byte (256-bit) words.
    //
    // Layout convention:
    //   0x00 - 0x3F: Scratch space (Solidity uses for hashing)
    //   0x40 - 0x5F: Free memory pointer (points to next available slot)
    //   0x60 - 0x7F: Zero slot
    //   0x80+:       Free memory (where Solidity allocates)
    //

    /// @notice Write a 32-byte value to memory at a given offset
    /// @dev `mstore(offset, value)` writes 32 bytes starting at `offset`.
    /// We use offset >= 0x80 to avoid overwriting Solidity's reserved areas.
    function writeToMemory(uint256 offset, uint256 value) external pure returns (uint256 result) {
        assembly {
            // Write value to memory at the specified offset
            mstore(offset, value)
            // Read it back to verify
            result := mload(offset)
        }
    }

    /// @notice Read a 32-byte value from memory at a given offset
    /// @dev `mload(offset)` reads 32 bytes starting at `offset`.
    /// Uninitialized memory is zero.
    function readFromMemory(uint256 offset) external pure returns (uint256 result) {
        assembly {
            result := mload(offset)
        }
    }

}
