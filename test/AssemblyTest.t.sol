// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {AssemblyBasics} from "../src/AssemblyBasics.sol";
import {AssemblyUtils} from "../src/AssemblyUtils.sol";
import {AssemblyErrors} from "../src/AssemblyErrors.sol";

contract AssemblyTest is Test {
    AssemblyBasics public basics;
    AssemblyUtils public utils;
    AssemblyErrors public errors;

    function setUp() public {
        basics = new AssemblyBasics();
        utils = new AssemblyUtils();
        errors = new AssemblyErrors();
    }

    // ═══════════════════════════════════════════════════════════════════════
    // SECTION 1: Storage Operations (sstore / sload)
    // ═══════════════════════════════════════════════════════════════════════

    function test_storeAndLoad() public {
        // Write 42 to slot 0, then read it back
        basics.store(0, 42);
        uint256 value = basics.load(0);
        assertEq(value, 42, "Should read back stored value");
    }

    function test_storeDifferentSlots() public {
        // Write to different slots, verify they're independent
        basics.store(1, 100);
        basics.store(2, 200);
        basics.store(3, 300);

        assertEq(basics.load(1), 100, "Slot 1 should be 100");
        assertEq(basics.load(2), 200, "Slot 2 should be 200");
        assertEq(basics.load(3), 300, "Slot 3 should be 300");
    }

    function test_storeOverwrite() public {
        // Write then overwrite the same slot
        basics.store(5, 111);
        assertEq(basics.load(5), 111);

        basics.store(5, 999);
        assertEq(basics.load(5), 999, "Should overwrite previous value");
    }

    // ═══════════════════════════════════════════════════════════════════════
    // SECTION 2: Arithmetic
    // ═══════════════════════════════════════════════════════════════════════

    function test_addSubMul() public view {
        assertEq(basics.assemblyAdd(10, 20), 30, "10 + 20 = 30");
        assertEq(basics.assemblySub(50, 20), 30, "50 - 20 = 30");
        assertEq(basics.assemblyMul(6, 7), 42, "6 * 7 = 42");
    }

    function test_divAndMod() public view {
        assertEq(basics.assemblyDiv(100, 3), 33, "100 / 3 = 33 (integer division)");
        assertEq(basics.assemblyMod(100, 3), 1, "100 % 3 = 1");

        // Division by zero returns 0 in assembly (no revert!)
        assertEq(basics.assemblyDiv(100, 0), 0, "Division by zero returns 0");
        assertEq(basics.assemblyMod(100, 0), 0, "Modulo by zero returns 0");
    }

    function test_arithmeticWithZero() public view {
        assertEq(basics.assemblyAdd(0, 0), 0, "0 + 0 = 0");
        assertEq(basics.assemblyMul(999, 0), 0, "999 * 0 = 0");
        assertEq(basics.assemblySub(0, 0), 0, "0 - 0 = 0");
    }

    // ═══════════════════════════════════════════════════════════════════════
    // SECTION 3: Bitwise Operations
    // ═══════════════════════════════════════════════════════════════════════

    function test_andOrXor() public view {
        // AND: 0xFF & 0x0F = 0x0F (keep lower 4 bits)
        assertEq(basics.bitwiseAnd(0xFF, 0x0F), 0x0F, "AND masks bits");

        // OR: 0xF0 | 0x0F = 0xFF (combine bits)
        assertEq(basics.bitwiseOr(0xF0, 0x0F), 0xFF, "OR combines bits");

        // XOR: 0xFF ^ 0x0F = 0xF0 (flip specific bits)
        assertEq(basics.bitwiseXor(0xFF, 0x0F), 0xF0, "XOR flips bits");
    }

    function test_shifts() public view {
        // Shift left 1 by 8 bits = 256 (multiply by 2^8)
        assertEq(basics.shiftLeft(1, 8), 256, "1 << 8 = 256");

        // Shift right 256 by 4 bits = 16 (divide by 2^4)
        assertEq(basics.shiftRight(256, 4), 16, "256 >> 4 = 16");

        // Shift left is the same as multiplying by 2^N
        assertEq(basics.shiftLeft(5, 3), 40, "5 << 3 = 5 * 8 = 40");
    }

    function test_bitwiseNot() public view {
        // NOT(0) = all 1s = type(uint256).max
        assertEq(basics.bitwiseNot(0), type(uint256).max, "NOT(0) = max uint256");

        // NOT(max) = 0
        assertEq(basics.bitwiseNot(type(uint256).max), 0, "NOT(max) = 0");
    }

    // ═══════════════════════════════════════════════════════════════════════
    // SECTION 4: Memory Operations (mstore / mload)
    // ═══════════════════════════════════════════════════════════════════════

    function test_writeAndReadMemory() public view {
        // Write a value to memory and read it back
        uint256 result = basics.writeToMemory(0x80, 12345);
        assertEq(result, 12345, "Should read back written value");
    }

    function test_memoryDifferentOffsets() public view {
        // Write to different memory offsets
        uint256 result1 = basics.writeToMemory(0x80, 111);
        uint256 result2 = basics.writeToMemory(0xA0, 222);

        assertEq(result1, 111, "First write should return 111");
        assertEq(result2, 222, "Second write should return 222");
    }

    // ═══════════════════════════════════════════════════════════════════════
    // SECTION 5: Practical Utilities
    // ═══════════════════════════════════════════════════════════════════════

    function test_getBalance() public {
        // Fund an address and check balance via assembly
        address target = makeAddr("rich");
        deal(target, 5 ether);

        uint256 bal = utils.getBalance(target);
        assertEq(bal, 5 ether, "Balance should be 5 ETH");
    }

    function test_isContract() public {
        // Our deployed contracts should be detected as contracts
        assertTrue(utils.isContract(address(basics)), "Deployed contract should be detected");
        assertTrue(utils.isContract(address(utils)), "Utils should be detected as contract");

        // EOA should NOT be a contract
        address eoa = makeAddr("eoa");
        assertFalse(utils.isContract(eoa), "EOA should not be a contract");
    }

    function test_efficientHash() public view {
        // Compare assembly hash with Solidity hash
        bytes32 assemblyHash = utils.efficientHash(42, 99);
        bytes32 solidityHash = keccak256(abi.encodePacked(uint256(42), uint256(99)));

        assertEq(assemblyHash, solidityHash, "Assembly and Solidity hash should match");
    }

    function test_packAndUnpack() public view {
        uint128 a = 12345;
        uint128 b = 67890;

        // Pack two values into one uint256
        uint256 packed = utils.packTwo128(a, b);

        // Unpack back
        (uint128 unpackedA, uint128 unpackedB) = utils.unpackTwo128(packed);

        assertEq(unpackedA, a, "Unpacked a should match");
        assertEq(unpackedB, b, "Unpacked b should match");
    }

    // ═══════════════════════════════════════════════════════════════════════
    // SECTION 6: Error Handling and Safe Math
    // ═══════════════════════════════════════════════════════════════════════

    function test_safeAddOverflowReverts() public {
        // Normal addition works
        uint256 result = errors.safeAdd(100, 200);
        assertEq(result, 300, "100 + 200 = 300");

        // Overflow should revert with Overflow() error
        vm.expectRevert(AssemblyErrors.Overflow.selector);
        errors.safeAdd(type(uint256).max, 1);
    }

    function test_safeMulOverflowReverts() public {
        // Normal multiplication works
        uint256 result = errors.safeMul(10, 20);
        assertEq(result, 200, "10 * 20 = 200");

        // Multiply by zero should return 0 (no overflow)
        assertEq(errors.safeMul(0, 999), 0, "0 * 999 = 0");

        // Overflow should revert
        vm.expectRevert(AssemblyErrors.Overflow.selector);
        errors.safeMul(type(uint256).max, 2);
    }

    function test_requireInAssembly() public {
        // True condition should not revert
        errors.requireInAssembly(true);

        // False condition should revert with ConditionFailed()
        vm.expectRevert(AssemblyErrors.ConditionFailed.selector);
        errors.requireInAssembly(false);
    }
}
