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
        uint256 round;
        uint256 amount;
        uint256 bet;
        Outcome outcome;
    }

    address public owner;

    mapping (address => bool) public admin;

    uint256 public fee;

    uint256 public fees;

    address public wallet;

    uint256 public duration;

    uint256 public timestamp;

    uint256 public minBet = 0.005 ether;

    uint256 public maxBet = 100 ether;

    Status public status;

    uint256 public round;

    Pool public hamsterAPool;

    Pool public hamsterBPool;

    Pool public hamsterCPool;

    Pool public hamsterDPool;

    mapping (address => User) public users;

    User[] public _users;

    event User_Created(address indexed user);

    event Betting_Round_Started(uint256 duration);

    event Betting_Round_Ended();

    event Winner(uint256 winner);

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

        admin[owner] = true;

        require(_fee <= 10, "Fee must not be greater than 10%");

        fee = _fee;

        fees = 0;

        wallet = msg.sender;

        status = Status.Inactive;

        duration = 0;

        timestamp = 0;

        round = 0;

        Staker[] memory _stakers;

        hamsterAPool = Pool({
            hamster: hamsterA,
            wins: 0,
            losses: 0,
            balance: 0,
            stakers: _stakers
        });

        hamsterBPool = Pool({
            hamster: hamsterB,
            wins: 0,
            losses: 0,
            balance: 0,
            stakers: _stakers
        });

        hamsterCPool = Pool({
            hamster: hamsterC,
            wins: 0,
            losses: 0,
            balance: 0,
            stakers: _stakers
        });

        hamsterDPool = Pool({
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

    modifier onlyAdmin {
        require(admin[msg.sender], "Only admin can call this function.");
        _;
    }

    function addAdmin(address _admin) public onlyOwner {
        admin[_admin] = true;
    }

    function changeFee(uint256 _fee) public onlyAdmin {
        require(_fee <= 10, "Fee must not be greater than 10%");

        fee = _fee;
    }

    function changeWallet(address _wallet) public onlyAdmin {
        wallet = _wallet;
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
        require(!userExists(msg.sender), "You already have an account");

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

    function start_betting_round(uint256 _duration) public onlyAdmin {
        status = Status.Active;

        duration = _duration;

        timestamp = block.timestamp;

        round += 1;

        Staker[] memory _stakers;

        hamsterAPool.balance = 0;
        hamsterAPool.stakers = _stakers;

        hamsterBPool.balance = 0;
        hamsterBPool.stakers = _stakers;

        hamsterCPool.balance = 0;
        hamsterCPool.stakers = _stakers;

        hamsterDPool.balance = 0;
        hamsterDPool.stakers = _stakers;

        emit Betting_Round_Started(_duration);
    }

    function stop_betting_round() public onlyAdmin {
        uint256 timeElapsed = block.timestamp - timestamp;

        require(timeElapsed >= duration, "Betting duration not yet exceeded.");

        status = Status.Inactive;

        duration = 0;

        timestamp = 0;

        emit Betting_Round_Ended();
    }

    function pick_winner(uint256 winner) public onlyAdmin {
        uint256 totalDividends = hamsterAPool.balance + hamsterBPool.balance + hamsterCPool.balance + hamsterDPool.balance;

        if(winner == 1) {
            for(uint256 i = 0; i < hamsterAPool.stakers.length; i++) {
                Staker memory _staker = hamsterAPool.stakers[i];
                address user = _staker.user;
                uint256 amount = _staker.amount;

                uint256 _dividend = (amount * totalDividends) / hamsterAPool.balance;
                uint256 dividend = ((100 - fee) * _dividend) / 100;

                users[user].balance += dividend;
                Bet[] storage _bets = users[user].bets;

                for(uint256 a = 0; a < _bets.length; a++) {
                    uint256 _round = _bets[a].round;
                    uint256 _bet = _bets[a].bet;

                    if(_round == round && _bet == 1) {
                        _bets[a].outcome = Outcome.Won;
                    }
                }

                uint256 _fees = (fee * _dividend) / 100;
                fees += _fees;
            }

            for(uint256 i = 0; i < hamsterBPool.stakers.length; i++) {
                Staker memory _staker = hamsterBPool.stakers[i];
                address user = _staker.user;

                Bet[] storage _bets = users[user].bets;

                for(uint256 a = 0; a < _bets.length; a++) {
                    uint256 _round = _bets[a].round;
                    uint256 _bet = _bets[a].bet;

                    if(_round == round && _bet == 2) {
                        _bets[a].outcome = Outcome.Lost;
                    }
                }
            }

            for(uint256 i = 0; i < hamsterCPool.stakers.length; i++) {
                Staker memory _staker = hamsterCPool.stakers[i];
                address user = _staker.user;

                Bet[] storage _bets = users[user].bets;

                for(uint256 a = 0; a < _bets.length; a++) {
                    uint256 _round = _bets[a].round;
                    uint256 _bet = _bets[a].bet;

                    if(_round == round && _bet == 3) {
                        _bets[a].outcome = Outcome.Lost;
                    }
                }
            }

            for(uint256 i = 0; i < hamsterDPool.stakers.length; i++) {
                Staker memory _staker = hamsterDPool.stakers[i];
                address user = _staker.user;

                Bet[] storage _bets = users[user].bets;

                for(uint256 a = 0; a < _bets.length; a++) {
                    uint256 _round = _bets[a].round;
                    uint256 _bet = _bets[a].bet;

                    if(_round == round && _bet == 4) {
                        _bets[a].outcome = Outcome.Lost;
                    }
                }
            }

            hamsterAPool.balance = totalDividends;
            hamsterBPool.balance = 0;
            hamsterCPool.balance = 0;
            hamsterDPool.balance = 0;
            hamsterAPool.wins += 1;
            hamsterBPool.losses += 1;
            hamsterCPool.losses += 1;
            hamsterDPool.losses += 1;
        } else if(winner == 2) {
            for(uint256 i = 0; i < hamsterBPool.stakers.length; i++) {
                Staker memory _staker = hamsterBPool.stakers[i];
                address user = _staker.user;
                uint256 amount = _staker.amount;

                uint256 _dividend = (amount * totalDividends) / hamsterBPool.balance;
                uint256 dividend = ((100 - fee) * _dividend) / 100;

                users[user].balance += dividend;
                Bet[] storage _bets = users[user].bets;

                for(uint256 a = 0; a < _bets.length; a++) {
                    uint256 _round = _bets[a].round;
                    uint256 _bet = _bets[a].bet;

                    if(_round == round && _bet == 2) {
                        _bets[a].outcome = Outcome.Won;
                    }
                }

                uint256 _fees = (fee * _dividend) / 100;
                fees += _fees;
            }

            for(uint256 i = 0; i < hamsterAPool.stakers.length; i++) {
                Staker memory _staker = hamsterAPool.stakers[i];
                address user = _staker.user;

                Bet[] storage _bets = users[user].bets;

                for(uint256 a = 0; a < _bets.length; a++) {
                    uint256 _round = _bets[a].round;
                    uint256 _bet = _bets[a].bet;

                    if(_round == round && _bet == 1) {
                        _bets[a].outcome = Outcome.Lost;
                    }
                }
            }

            for(uint256 i = 0; i < hamsterCPool.stakers.length; i++) {
                Staker memory _staker = hamsterCPool.stakers[i];
                address user = _staker.user;

                Bet[] storage _bets = users[user].bets;

                for(uint256 a = 0; a < _bets.length; a++) {
                    uint256 _round = _bets[a].round;
                    uint256 _bet = _bets[a].bet;

                    if(_round == round && _bet == 3) {
                        _bets[a].outcome = Outcome.Lost;
                    }
                }
            }

            for(uint256 i = 0; i < hamsterDPool.stakers.length; i++) {
                Staker memory _staker = hamsterDPool.stakers[i];
                address user = _staker.user;

                Bet[] storage _bets = users[user].bets;

                for(uint256 a = 0; a < _bets.length; a++) {
                    uint256 _round = _bets[a].round;
                    uint256 _bet = _bets[a].bet;

                    if(_round == round && _bet == 4) {
                        _bets[a].outcome = Outcome.Lost;
                    }
                }
            }

            hamsterBPool.balance = totalDividends;
            hamsterAPool.balance = 0;
            hamsterCPool.balance = 0;
            hamsterDPool.balance = 0;
            hamsterBPool.wins += 1;
            hamsterAPool.losses += 1;
            hamsterCPool.losses += 1;
            hamsterDPool.losses += 1;
        } else if(winner == 3) {
            for(uint256 i = 0; i < hamsterCPool.stakers.length; i++) {
                Staker memory _staker = hamsterCPool.stakers[i];
                address user = _staker.user;
                uint256 amount = _staker.amount;

                uint256 _dividend = (amount * totalDividends) / hamsterCPool.balance;
                uint256 dividend = ((100 - fee) * _dividend) / 100;

                users[user].balance += dividend;
                Bet[] storage _bets = users[user].bets;

                for(uint256 a = 0; a < _bets.length; a++) {
                    uint256 _round = _bets[a].round;
                    uint256 _bet = _bets[a].bet;

                    if(_round == round && _bet == 3) {
                        _bets[a].outcome = Outcome.Won;
                    }
                }

                uint256 _fees = (fee * _dividend) / 100;
                fees += _fees;
            }

            for(uint256 i = 0; i < hamsterAPool.stakers.length; i++) {
                Staker memory _staker = hamsterAPool.stakers[i];
                address user = _staker.user;

                Bet[] storage _bets = users[user].bets;

                for(uint256 a = 0; a < _bets.length; a++) {
                    uint256 _round = _bets[a].round;
                    uint256 _bet = _bets[a].bet;

                    if(_round == round && _bet == 1) {
                        _bets[a].outcome = Outcome.Lost;
                    }
                }
            }

            for(uint256 i = 0; i < hamsterBPool.stakers.length; i++) {
                Staker memory _staker = hamsterBPool.stakers[i];
                address user = _staker.user;

                Bet[] storage _bets = users[user].bets;

                for(uint256 a = 0; a < _bets.length; a++) {
                    uint256 _round = _bets[a].round;
                    uint256 _bet = _bets[a].bet;

                    if(_round == round && _bet == 2) {
                        _bets[a].outcome = Outcome.Lost;
                    }
                }
            }

            for(uint256 i = 0; i < hamsterDPool.stakers.length; i++) {
                Staker memory _staker = hamsterDPool.stakers[i];
                address user = _staker.user;

                Bet[] storage _bets = users[user].bets;

                for(uint256 a = 0; a < _bets.length; a++) {
                    uint256 _round = _bets[a].round;
                    uint256 _bet = _bets[a].bet;

                    if(_round == round && _bet == 4) {
                        _bets[a].outcome = Outcome.Lost;
                    }
                }
            }

            hamsterCPool.balance = totalDividends;
            hamsterAPool.balance = 0;
            hamsterBPool.balance = 0;
            hamsterDPool.balance = 0;
            hamsterCPool.wins += 1;
            hamsterAPool.losses += 1;
            hamsterBPool.losses += 1;
            hamsterDPool.losses += 1;
        } else if(winner == 4) {
            for(uint256 i = 0; i < hamsterDPool.stakers.length; i++) {
                Staker memory _staker = hamsterDPool.stakers[i];
                address user = _staker.user;
                uint256 amount = _staker.amount;

                uint256 _dividend = (amount * totalDividends) / hamsterDPool.balance;
                uint256 dividend = ((100 - fee) * _dividend) / 100;

                users[user].balance += dividend;
                Bet[] storage _bets = users[user].bets;

                for(uint256 a = 0; a < _bets.length; a++) {
                    uint256 _round = _bets[a].round;
                    uint256 _bet = _bets[a].bet;

                    if(_round == round && _bet == 4) {
                        _bets[a].outcome = Outcome.Won;
                    }
                }

                uint256 _fees = (fee * _dividend) / 100;
                fees += _fees;
            }

            for(uint256 i = 0; i < hamsterAPool.stakers.length; i++) {
                Staker memory _staker = hamsterAPool.stakers[i];
                address user = _staker.user;

                Bet[] storage _bets = users[user].bets;

                for(uint256 a = 0; a < _bets.length; a++) {
                    uint256 _round = _bets[a].round;
                    uint256 _bet = _bets[a].bet;

                    if(_round == round && _bet == 1) {
                        _bets[a].outcome = Outcome.Lost;
                    }
                }
            }

            for(uint256 i = 0; i < hamsterCPool.stakers.length; i++) {
                Staker memory _staker = hamsterCPool.stakers[i];
                address user = _staker.user;

                Bet[] storage _bets = users[user].bets;

                for(uint256 a = 0; a < _bets.length; a++) {
                    uint256 _round = _bets[a].round;
                    uint256 _bet = _bets[a].bet;

                    if(_round == round && _bet == 3) {
                        _bets[a].outcome = Outcome.Lost;
                    }
                }
            }

            for(uint256 i = 0; i < hamsterBPool.stakers.length; i++) {
                Staker memory _staker = hamsterBPool.stakers[i];
                address user = _staker.user;

                Bet[] storage _bets = users[user].bets;

                for(uint256 a = 0; a < _bets.length; a++) {
                    uint256 _round = _bets[a].round;
                    uint256 _bet = _bets[a].bet;

                    if(_round == round && _bet == 2) {
                        _bets[a].outcome = Outcome.Lost;
                    }
                }
            }

            hamsterDPool.balance = totalDividends;
            hamsterAPool.balance = 0;
            hamsterBPool.balance = 0;
            hamsterCPool.balance = 0;
            hamsterDPool.wins += 1;
            hamsterAPool.losses += 1;
            hamsterCPool.losses += 1;
            hamsterBPool.losses += 1;
        }

        emit Winner(winner);
    }

    function place_bet(string memory _id, uint256 _bet) public payable {
        require(status == Status.Active, "Betting is not active at the moment.");

        uint256 timeElapsed = block.timestamp - timestamp;

        require(timeElapsed <= duration, "Betting round is over.");

        require(msg.value >= minBet, "Minimum betting wager is 0.005 ETH.");

        require(msg.value <= maxBet, "Maximum betting wager is 10 ETH.");

        Staker memory staker = Staker({
            user: msg.sender,
            amount: msg.value
        });

        if(_bet == 1) {
            hamsterAPool.balance += msg.value;
            hamsterAPool.stakers.push(staker);
        } else if(_bet == 2) {
            hamsterBPool.balance += msg.value;
            hamsterBPool.stakers.push(staker);
        }else if(_bet == 3) {
            hamsterCPool.balance += msg.value;
            hamsterCPool.stakers.push(staker);
        }else if(_bet == 4) {
            hamsterDPool.balance += msg.value;
            hamsterDPool.stakers.push(staker);
        }

        Bet memory bet = Bet({
            id: _id,
            round: round,
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
            Staker[] memory _stakers = hamsterAPool.stakers;

            return _stakers;
        } else if(hamster == 2) {
            Staker[] memory _stakers = hamsterBPool.stakers;

            return _stakers;
        } else if(hamster == 3) {
            Staker[] memory _stakers = hamsterCPool.stakers;

            return _stakers;
        } else if(hamster == 4) {
            Staker[] memory _stakers = hamsterDPool.stakers;

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

    function withdrawFees() public payable onlyAdmin {
        (bool os, ) = payable(wallet).call{value: fees}("");
        require(os);

        fees = 0;
    }

    function withdraw() public payable onlyAdmin {
        uint256 balance = address(this).balance;
        uint256 usersBalance = 0;

        for(uint256 i = 0; i < _users.length; i++) {
            User memory _user = _users[i];

            usersBalance += _user.balance;
        }

        uint256 amount = balance - (usersBalance + fees);

        if(amount > 0) {
            (bool os, ) = payable(wallet).call{value: amount}("");
            require(os);
        }
    }
}
