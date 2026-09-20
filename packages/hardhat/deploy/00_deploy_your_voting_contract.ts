import { artifacts, deployScript } from "../rocketh/deploy.js";

export default deployScript(
  async ({ deploy, namedAccounts }) => {
    const { deployer } = namedAccounts;
    const poseidon3 = await deploy("PoseidonT3", {
      account: deployer,
      artifact: artifacts.PoseidonT3,
      args: [],
    });
    const leanIMT = await deploy(
      "LeanIMT",
      { account: deployer, artifact: artifacts.LeanIMT, args: [] },
      { libraries: { PoseidonT3: poseidon3.address } },
    );
    const verifier = await deploy("VerifierMock", {
      account: deployer,
      artifact: artifacts.VerifierMock,
      args: [],
    });
    await deploy(
      "Voting",
      {
        account: deployer,
        artifact: artifacts.Voting,
        args: [deployer, verifier.address, "Should we build zk apps?"],
      },
      { libraries: { LeanIMT: leanIMT.address } },
    );
  },
  { tags: ["YourVotingContract"] },
);