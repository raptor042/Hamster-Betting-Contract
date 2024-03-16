// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract Betting {
    enum Status {
        Active,
        Inactive
    }

    enum Outcome {
        Won,
        Lost,
        Pending
    }

    struct Pool {
        string hamster;
        uint256 wins;
        uint256 losses;
        uint256 balance;
        Staker[] stakers;
    }

    struct Staker {
        address user;
        uint256 amount;
    }

    struct User {
        address user;
        uint256 balance;
        Bet[] bets;
    }

    struct Bet {
        string id;
        uint256 amount;
        uint256 bet;
        Outcome outcome;
    }

    address public owner;

    uint256 public fee;

    uint256 public minBet = 0.005 ether;

    uint256 public maxBet = 100 ether;

    Status public status;

    Pool public rockyPool;

    Pool public charliePool;

    Pool public teddyPool;

    Pool public oliverPool;

    mapping (address => User) public users;

    User[] public _users;

    event User_Created(address indexed user);

    event Betting_Round_Started();

    event Betting_Round_Ended(uint256 winner);

    event Bet_Placed(address indexed user, uint256 amount, uint256 bet);

    event Withdrawal(address indexed user, uint256 amount);

    constructor(
        uint256 _fee,
        string memory hamsterA,
        string memory hamsterB,
        string memory hamsterC,
        string memory hamsterD
    ) {
        owner = msg.sender;

        fee = _fee;

        status = Status.Inactive;

        Staker[] memory _stakers;

        rockyPool = Pool({
            hamster: hamsterA,
            wins: 0,
            losses: 0,
            balance: 0,
            stakers: _stakers
        });

        charliePool = Pool({
            hamster: hamsterB,
            wins: 0,
            losses: 0,
            balance: 0,
            stakers: _stakers
        });

        teddyPool = Pool({
            hamster: hamsterC,
            wins: 0,
            losses: 0,
            balance: 0,
            stakers: _stakers
        });

        oliverPool = Pool({
            hamster: hamsterD,
            wins: 0,
            losses: 0,
            balance: 0,
            stakers: _stakers
        });
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function userExists(address user) internal view returns (bool) {
        bool user_exist = false;

        for(uint256 i = 0; i < _users.length; i++) {
            if(_users[i].user == user) {
                user_exist = true;

                break;
            }
        }

        return user_exist;
    }

    function createUser() public {
        require(userExists(msg.sender), "You already have an account");

        Bet[] memory _bets;

        User memory _user = User({
            user: msg.sender,
            balance: 0,
            bets: _bets
        });

        users[msg.sender] = _user;

        _users.push(_user);

        emit User_Created(msg.sender);
    }

    function start_betting_round() public onlyOwner {
        status = Status.Active;

        Staker[] memory _stakers;

        rockyPool.balance = 0;
        rockyPool.stakers = _stakers;

        charliePool.balance = 0;
        charliePool.stakers = _stakers;

        teddyPool.balance = 0;
        teddyPool.stakers = _stakers;

        oliverPool.balance = 0;
        oliverPool.stakers = _stakers;

        emit Betting_Round_Started();
    }

    function stop_betting_round(uint256 winner) public onlyOwner {
        status = Status.Inactive;

        uint256 totalDividends = rockyPool.balance + charliePool.balance + teddyPool.balance + oliverPool.balance;

        if(winner == 1) {
            for(uint256 i = 0; i < rockyPool.stakers.length; i++) {
                Staker memory _staker = rockyPool.stakers[i];
                address user = _staker.user;
                uint256 amount = _staker.amount;

                uint256 _dividend = (amount * totalDividends) / rockyPool.balance;
                uint256 dividend = ((100 - fee) * _dividend) / 100;

                users[user].balance += dividend;
                uint256 _bets = users[user].bets.length;
                users[user].bets[_bets - 1].outcome = Outcome.Won;
            }

            for(uint256 i = 0; i < charliePool.stakers.length; i++) {
                Staker memory _staker = charliePool.stakers[i];
                address user = _staker.user;

                uint256 _bets = users[user].bets.length;
                users[user].bets[_bets - 1].outcome = Outcome.Lost;
            }

            for(uint256 i = 0; i < teddyPool.stakers.length; i++) {
                Staker memory _staker = teddyPool.stakers[i];
                address user = _staker.user;

                uint256 _bets = users[user].bets.length;
                users[user].bets[_bets - 1].outcome = Outcome.Lost;
            }

            for(uint256 i = 0; i < oliverPool.stakers.length; i++) {
                Staker memory _staker = oliverPool.stakers[i];
                address user = _staker.user;

                uint256 _bets = users[user].bets.length;
                users[user].bets[_bets - 1].outcome = Outcome.Lost;
            }

            rockyPool.balance = totalDividends;
            charliePool.balance = 0;
            teddyPool.balance = 0;
            oliverPool.balance = 0;
            rockyPool.wins += 1;
            charliePool.losses += 1;
            teddyPool.losses += 1;
            oliverPool.losses += 1;
        } else if(winner == 2) {
            for(uint256 i = 0; i < charliePool.stakers.length; i++) {
                Staker memory _staker = charliePool.stakers[i];
                address user = _staker.user;
                uint256 amount = _staker.amount;

                uint256 _dividend = (amount * totalDividends) / charliePool.balance;
                uint256 dividend = ((100 - fee) * _dividend) / 100;

                users[user].balance += dividend;
                uint256 _bets = users[user].bets.length;
                users[user].bets[_bets - 1].outcome = Outcome.Won;
            }

            for(uint256 i = 0; i < rockyPool.stakers.length; i++) {
                Staker memory _staker = rockyPool.stakers[i];
                address user = _staker.user;

                uint256 _bets = users[user].bets.length;
                users[user].bets[_bets - 1].outcome = Outcome.Lost;
            }

            for(uint256 i = 0; i < teddyPool.stakers.length; i++) {
                Staker memory _staker = teddyPool.stakers[i];
                address user = _staker.user;

                uint256 _bets = users[user].bets.length;
                users[user].bets[_bets - 1].outcome = Outcome.Lost;
            }

            for(uint256 i = 0; i < oliverPool.stakers.length; i++) {
                Staker memory _staker = oliverPool.stakers[i];
                address user = _staker.user;

                uint256 _bets = users[user].bets.length;
                users[user].bets[_bets - 1].outcome = Outcome.Lost;
            }

            charliePool.balance = totalDividends;
            rockyPool.balance = 0;
            teddyPool.balance = 0;
            oliverPool.balance = 0;
            charliePool.wins += 1;
            rockyPool.losses += 1;
            teddyPool.losses += 1;
            oliverPool.losses += 1;
        } else if(winner == 3) {
            for(uint256 i = 0; i < teddyPool.stakers.length; i++) {
                Staker memory _staker = teddyPool.stakers[i];
                address user = _staker.user;
                uint256 amount = _staker.amount;

                uint256 _dividend = (amount * totalDividends) / teddyPool.balance;
                uint256 dividend = ((100 - fee) * _dividend) / 100;

                users[user].balance += dividend;
                uint256 _bets = users[user].bets.length;
                users[user].bets[_bets - 1].outcome = Outcome.Won;
            }

            for(uint256 i = 0; i < rockyPool.stakers.length; i++) {
                Staker memory _staker = rockyPool.stakers[i];
                address user = _staker.user;

                uint256 _bets = users[user].bets.length;
                users[user].bets[_bets - 1].outcome = Outcome.Lost;
            }

            for(uint256 i = 0; i < charliePool.stakers.length; i++) {
                Staker memory _staker = charliePool.stakers[i];
                address user = _staker.user;

                uint256 _bets = users[user].bets.length;
                users[user].bets[_bets - 1].outcome = Outcome.Lost;
            }

            for(uint256 i = 0; i < oliverPool.stakers.length; i++) {
                Staker memory _staker = oliverPool.stakers[i];
                address user = _staker.user;

                uint256 _bets = users[user].bets.length;
                users[user].bets[_bets - 1].outcome = Outcome.Lost;
            }

            teddyPool.balance = totalDividends;
            rockyPool.balance = 0;
            charliePool.balance = 0;
            oliverPool.balance = 0;
            teddyPool.wins += 1;
            rockyPool.losses += 1;
            charliePool.losses += 1;
            oliverPool.losses += 1;
        } else if(winner == 4) {
            for(uint256 i = 0; i < oliverPool.stakers.length; i++) {
                Staker memory _staker = oliverPool.stakers[i];
                address user = _staker.user;
                uint256 amount = _staker.amount;

                uint256 _dividend = (amount * totalDividends) / oliverPool.balance;
                uint256 dividend = ((100 - fee) * _dividend) / 100;

                users[user].balance += dividend;
                uint256 _bets = users[user].bets.length;
                users[user].bets[_bets - 1].outcome = Outcome.Won;
            }

            for(uint256 i = 0; i < rockyPool.stakers.length; i++) {
                Staker memory _staker = rockyPool.stakers[i];
                address user = _staker.user;

                uint256 _bets = users[user].bets.length;
                users[user].bets[_bets - 1].outcome = Outcome.Lost;
            }

            for(uint256 i = 0; i < teddyPool.stakers.length; i++) {
                Staker memory _staker = teddyPool.stakers[i];
                address user = _staker.user;

                uint256 _bets = users[user].bets.length;
                users[user].bets[_bets - 1].outcome = Outcome.Lost;
            }

            for(uint256 i = 0; i < charliePool.stakers.length; i++) {
                Staker memory _staker = charliePool.stakers[i];
                address user = _staker.user;

                uint256 _bets = users[user].bets.length;
                users[user].bets[_bets - 1].outcome = Outcome.Lost;
            }

            oliverPool.balance = totalDividends;
            rockyPool.balance = 0;
            charliePool.balance = 0;
            teddyPool.balance = 0;
            oliverPool.wins += 1;
            rockyPool.losses += 1;
            teddyPool.losses += 1;
            charliePool.losses += 1;
        }

        emit Betting_Round_Ended(winner);
    }

    function place_bet(string memory _id, uint256 _bet) public payable {
        require(status == Status.Active, "Betting is not active at the moment.");

        require(msg.value >= minBet, "Minimum betting wager is 0.005 ETH.");

        require(msg.value <= maxBet, "Maximum betting wager is 10 ETH.");

        Staker memory staker = Staker({
            user: msg.sender,
            amount: msg.value
        });

        if(_bet == 1) {
            rockyPool.balance += msg.value;
            rockyPool.stakers.push(staker);
        } else if(_bet == 2) {
            charliePool.balance += msg.value;
            charliePool.stakers.push(staker);
        }else if(_bet == 3) {
            teddyPool.balance += msg.value;
            teddyPool.stakers.push(staker);
        }else if(_bet == 4) {
            oliverPool.balance += msg.value;
            oliverPool.stakers.push(staker);
        }

        Bet memory bet = Bet({
            id: _id,
            amount: msg.value,
            bet: _bet,
            outcome: Outcome.Pending
        });

        Bet[] storage _bets = users[msg.sender].bets;

        _bets.push(bet);

        emit Bet_Placed(msg.sender, msg.value, _bet);
    }

    function getStakers(uint256 hamster) public view returns (Staker[] memory stakers) {
        if(hamster == 1) {
            Staker[] memory _stakers = rockyPool.stakers;

            return _stakers;
        } else if(hamster == 2) {
            Staker[] memory _stakers = charliePool.stakers;

            return _stakers;
        } else if(hamster == 3) {
            Staker[] memory _stakers = teddyPool.stakers;

            return _stakers;
        } else if(hamster == 4) {
            Staker[] memory _stakers = oliverPool.stakers;

            return _stakers;
        }
    }

    function getBets(address user) public view returns (Bet[] memory bets) {
        Bet[] memory _bets = users[user].bets;

        return _bets;
    }

    function withdrawal(uint256 _amount) public payable {
        require(_amount <= users[msg.sender].balance, "Insufficent balance.");

        (bool os, ) = payable(msg.sender).call{value: _amount}("");
        require(os);

        users[msg.sender].balance -= _amount;

        emit Withdrawal(msg.sender, _amount);
    }

    function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner).call{value: address(this).balance}("");
        require(os);
    }
}
