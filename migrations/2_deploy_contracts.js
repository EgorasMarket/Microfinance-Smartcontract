var EgorasLending = artifacts.require("./EgorasLending.sol");

module.exports = async (deployer) => {
  await deployer.deploy(
    EgorasLending,
    "0x9534a50Af8569a4411BBbb551bDB9561Cbb55956",
    "0x73Cee8348b9bDd48c64E13452b8a6fbc81630573",
    200,
    "100000000000000000000000000",
    "10000000000000000000000",
    "10000000000000000000",
    8000
  );
};
