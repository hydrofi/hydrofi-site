
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title FounderLockerFixed (HYFI)
 * @notice Hard-coded schedule for HYFI founders/partners.
 *
 * Parameters (fixed in code):
 * - token:  0xc28dF9EbAD0D8A1E8Ab4480F3C94277d182e42e9
 * - partners:
 *     1) 0x251Fd09D5a64fb76a1912bf27033B883305dc239  — 200,000,000 HYFI / 30 days
 *     2) 0xC9934077D382bF5657683272AB05961de6f09fAb  — 200,000,000 HYFI / 30 days
 * - start:  2025-08-27 00:00:00 UTC  (unix: 1756252800)
 * - cliff:  12 months (31536000 seconds)
 * - month:  30 days (2592000 seconds)
 * - total:  36 months
 *
 * How to use:
 * 1) Deploy this contract (no constructor args).
 * 2) Fund it with the total required HYFI amount:
 *      (200,000,000 + 200,000,000) * 36 = 14,400,000,000 HYFI (x 10^18).
 * 3) Each partner calls claim() after cliff; or anyone may call claimFor(partner).
 */
contract FounderLockerFixed is Ownable {
    // ---- Fixed parameters ----

    // HYFI token
    IERC20 public constant token = IERC20(0xc28dF9EbAD0D8A1E8Ab4480F3C94277d182e42e9);

    // Schedule
    uint64 public constant start = 1756252800;        // 2025-08-27 00:00:00 UTC
    uint64 public constant cliffDuration = 31536000;  // 12 months
    uint64 public constant monthDuration = 2592000;   // 30 days
    uint16 public constant totalMonths = 36;          // 36 months

    // Recipients & monthly amounts
    address private constant PARTNER1 = 0x251Fd09D5a64fb76a1912bf27033B883305dc239;
    address private constant PARTNER2 = 0xC9934077D382bF5657683272AB05961de6f09fAb;

    uint256 private constant AMOUNT1 = 200000000000000000000000000; // 200,000,000 * 10^18
    uint256 private constant AMOUNT2 = 200000000000000000000000000; // 200,000,000 * 10^18

    // ---- State ----

    address[] private _recipients;
    mapping(address => uint256) public monthlyAmount;   // per recipient
    mapping(address => uint16) public monthsClaimed;    // per recipient

    event Claimed(address indexed recipient, uint16 months, uint256 amount);
    event Rescue(address indexed token, address indexed to, uint256 amount);

    error NotRecipient();
    error NothingToClaim();
    error CliffNotReached();

    constructor() Ownable(msg.sender) {
        // initialize fixed recipients
        _recipients.push(PARTNER1);
        _recipients.push(PARTNER2);

        monthlyAmount[PARTNER1] = AMOUNT1;
        monthlyAmount[PARTNER2] = AMOUNT2;

        // basic sanity
        require(address(token) != address(0), "TOKEN_ZERO");
    }

    // -------- Views --------

    function recipients() external view returns (address[] memory) {
        return _recipients;
    }

    function isRecipient(address who) public view returns (bool) {
        return monthlyAmount[who] != 0;
    }

    function monthsElapsed() public view returns (uint16) {
        if (block.timestamp < start) return 0;
        unchecked {
            uint256 elapsed = block.timestamp - start;
            uint256 months_ = elapsed / monthDuration;
            if (months_ > type(uint16).max) months_ = type(uint16).max;
            return uint16(months_);
        }
    }

    function monthsVested() public view returns (uint16) {
        uint16 m = monthsElapsed();
        return m > totalMonths ? totalMonths : m;
    }

    function claimableMonths(address r) public view returns (uint16) {
        uint16 vested = monthsVested();
        uint16 claimed = monthsClaimed[r];
        if (vested <= claimed) return 0;
        return vested - claimed;
    }

    function claimableAmount(address r) public view returns (uint256) {
        return uint256(claimableMonths(r)) * monthlyAmount[r];
    }

    function nextReleaseTime(address /*r*/) public view returns (uint256) {
        uint16 vested = monthsVested();
        uint256 next = uint256(start) + (uint256(vested) + 1) * monthDuration;
        return next;
    }

    // -------- Mutating --------

    function _precheck(address r) internal view {
        if (!isRecipient(r)) revert NotRecipient();
        if (block.timestamp < start + cliffDuration) revert CliffNotReached();
    }

    /// @notice Claim vested tokens for msg.sender.
    function claim() external {
        claimFor(msg.sender);
    }

    /// @notice Claim vested tokens for recipient `r`. Tokens are transferred to `r`.
    function claimFor(address r) public {
        _precheck(r);

        uint16 mths = claimableMonths(r);
        if (mths == 0) revert NothingToClaim();

        // Effects
        monthsClaimed[r] += mths;

        // Interactions
        uint256 amount = uint256(mths) * monthlyAmount[r];
        require(token.transfer(r, amount), "TRANSFER_FAILED");

        emit Claimed(r, mths, amount);
    }

    /// @notice Owner can rescue non-locked tokens accidentally sent to this contract.
    function rescueTokens(address token_, address to, uint256 amount) external onlyOwner {
        require(token_ != address(token), "LOCKED_TOKEN");
        require(IERC20(token_).transfer(to, amount), "RESCUE_FAILED");
        emit Rescue(token_, to, amount);
    }
}
