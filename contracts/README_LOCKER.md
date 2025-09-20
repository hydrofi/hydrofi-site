# HYFI FounderLocker (Fixed Schedule)

This repository includes a **hard‑coded** vesting contract for HYFI partners.  
File: `contracts/FounderLocker.sol` (HYFI schedule embedded in code).

## What it does
The contract distributes a fixed **monthly** amount of HYFI to multiple recipients after a **cliff**. 
Recipients pull their vested tokens with `claim()`; anyone can call `claimFor(address)` to pull to a recipient.

## Fixed parameters (in code)
- **Token (HYFI):** `0xc28dF9EbAD0D8A1E8Ab4480F3C94277d182e42e9`
- **Start:** 2025‑08‑27 00:00:00 UTC (`1756252800`)
- **Cliff:** 12 months (`31536000` seconds)
- **Month:** 30 days (`2592000` seconds)
- **Total duration:** 36 months
- **Recipients & amount/month:**
  - `0x251Fd09D5a64fb76a1912bf27033B883305dc239` — **200,000,000 HYFI**
  - `0xC9934077D382bF5657683272AB05961de6f09fAb` — **200,000,000 HYFI**

**Total required funding:** `14,400,000,000 HYFI` (2 × 200M × 36).

## How to deploy (Remix)
1. Open `contracts/FounderLocker.sol` in **Remix**, select compiler **0.8.20**, and **Compile**.
2. In **Deploy & Run**, select the network (BSC mainnet), connect MetaMask, and click **Deploy** *(no constructor args)*.
3. **Fund the contract**: transfer the full HYFI amount to the **contract address**.
4. After the **cliff** and whenever whole months have accrued, a recipient calls `claim()`; anyone may call `claimFor(<address>)`.

## Transparency / On-chain checks
- On **BscScan** (tab *Read Contract*):
  - `recipients()` returns the addresses.
  - `monthlyAmount(<address>)` shows each monthly allocation.
  - `monthsClaimed(<address>)` shows vesting progress.
- Parameters are **hard‑coded** in the source; there are no constructor arguments.

## Security notes
- The owner **cannot** withdraw the locked HYFI; only `rescueTokens` for non‑HYFI tokens is allowed.
- Always verify the contract address and source before sending funds.
- There is no treasury account; claims are pulled directly by recipients.

---

**License:** MIT

