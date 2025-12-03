pragma solidity ^0.8.24;

contract GuessVulnerable {
    uint256 public answer;
    uint256 public rewardPool;

    constructor(uint256 _answer) payable {
        answer = _answer;
        rewardPool = msg.value;
    }

    function guess(uint256 userGuess) external {
        if (userGuess == answer) {
            uint256 amount = rewardPool;
            rewardPool = 0;
            (bool ok,) = msg.sender.call{value: amount}("");
            require(ok, "fail");
        }
    }
}