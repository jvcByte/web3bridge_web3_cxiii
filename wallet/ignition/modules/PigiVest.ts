import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const unlockTime = BigInt(Math.floor(Date.now() / 1000) + 3600); // 1 hour from now

const PigiVestModule = buildModule("PigiVestModule", (m) => {
    const pigiVest = m.contract("PigiVest", [unlockTime], {
        value: 0n
    });

    return { pigiVest };
});

export default PigiVestModule;