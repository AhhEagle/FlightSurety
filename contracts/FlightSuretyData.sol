pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
    mapping (address => uint256) private authorizedContracts;
    uint256 public constant INSURANCE_PRICE_LIMIT = 1 ether;
    uint256 public constant MINIMUM_FUNDS = 10 ether;
    uint8 private constant MIN_AIRLINES = 4;
    uint256 public airlinesCount;

    struct Airline{
        string name;
        address airlineAdd;
        bool isRegistered;
        uint256 votes;
        uint256 funded;
    }
    mapping (address => Airline) private airlines;

    struct Passenger{
        address passengerAdd;
        uint256 credit;
        mapping(string => uint256) tickectBought;
    }

    mapping(address => Passenger) private passengers;
    address[] public passengerAddresses;


    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                ) 
                                public 
    {
        contractOwner = msg.sender;
        airlinesCount = 0;
        authorizedContracts[msg.sender] = 1;
        passengerAddresses = new address[](0);
        airlines[msg.sender] = Airline({
            name: "FlyOlad",
            airlineAdd: msg.sender,
            isRegistered: true,
            votes: 0,
            funded: 0
        });
        airlinesCount++;
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier requireIsCallerAuthorized(){
        require(authorizedContracts[msg.sender] == 1, "Caller is not auhtorized to perform is operation");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner 
    {
        operational = mode;
    }

    function authorizeCaller(address add) external requireContractOwner{
        authorizedContracts[add] =1;
    }

    function deauthorizeCaller(address add) external requireContractOwner{
        delete authorizedContracts[add];
    }

    function isAuthorized(address add) external view returns(bool){
        return (authorizedContracts[add] == 1);
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    function isActive(address airline) public view returns(bool) {
        return (airlines[airline].funded >= MINIMUM_FUNDS);
    }

    function isRegistered (address airline) public view returns(bool){
        return (airlines[airline].isRegistered);
    }

 function isVote(address voted) internal requireIsOperational returns(bool) {
        bool voting = false;
        airlines[voted].votes++;
        if (airlines[voted].votes >= airlinesCount.div(2)) {
            airlines[voted].isRegistered = true;
            airlinesCount++;
        }
        voting = true;
        return voting;
    }

 function getAirlineVotes(address airline) public view returns (uint256 votes) {
        return (airlines[airline].votes);
    }

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline (  
                                address airlineAdd,
                                string name
                            )
                            external
                            requireIsOperational
                            requireIsCallerAuthorized
                            returns(bool)
    {
                    require(airlineAddress != address(0), "'airlineAddress' must be a valid address.");
                    require(!airlines[airlineAddress].isRegistered, "Airline is already registered.");
                    if(airlinesCount < MIN_AIRLINES){
                        airlines[airlineAdd] = Airline({
                                                          name: name,
                                                          airlineAdd: airlineAdd,
                                                          isRegistered: true,
                                                          votes: 1,
                                                          funded: 0
                                                         });
        airlinesCount++;
     } else {
         require(isVote(airlineAdd), "error occured");
     }
     return (true);
    }


   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy(string flightCode)
                            external
                            payable
                            requireIsOperational
                            returns (uint256, address, uint256)
    {
        require(msg.sender == tx.origin, "Contracts are not allowed");
        require(msg.value > 0, 'You need to pay to buy an insurance');

        if(!checkIfContains(msg.sender)){
            passengerAddresses.push(msg.sender);
        }
        if (passengers[msg.sender].passengerWallet != msg.sender) {
            passengers[msg.sender] = Passenger({
                                                passengerAdd: msg.sender,
                                                credit: 0
                                        });
            passengers[msg.sender].boughtFlight[flightCode] = msg.value;
        } else {
            passengers[msg.sender].boughtFlight[flightCode] = msg.value;
        }
        if (msg.value > INSURANCE_PRICE_LIMIT) {
            msg.sender.transfer(msg.value.sub(INSURANCE_PRICE_LIMIT));
        }

    }

    function checkIfContains(address passenger) internal view returns(bool inList){
        listed = false;
        for (uint256 c = 0; c < passengerAddresses.length; c++) {
            if (passengerAddresses[c] == passenger) {
                listed = true;
                break;
            }
        }
        return listed;
    }




    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees(string flightCode)
                                external
                                requireIsOperational
    {
        for (uint256 c = 0; c < passengerAddresses.length; c++) {
            if(passengers[passengerAddresses[c]].boughtFlight[flightCode] != 0) {
                uint256 savedCredit = passengers[passengerAddresses[c]].credit;
                uint256 payedPrice = passengers[passengerAddresses[c]].boughtFlight[flightCode];
                passengers[passengerAddresses[c]].boughtFlight[flightCode] = 0;
                passengers[passengerAddresses[c]].credit = savedCredit + payedPrice + payedPrice.div(2);
            }
        }
    }

        function getCreditToPay() external view returns (uint256) {
        return passengers[msg.sender].credit;
    }

    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay(address payable insuredPassenger)  public requireIsOperational returns (uint256, uint256, uint256, uint256, address, address)
    {
        require(insuredPassenger == tx.origin, "Contracts not allowed");
        require(passengers[insuredPassenger].credit > 0, "The company didn't put any money to be withdrawed by you");
        uint256 initialBalance = address(this).balance;
        uint256 credit = passengers[insuredPassenger].credit;
        require(address(this).balance > credit, "The contract does not have enough funds to pay the credit");
        passengers[insuredPassenger].credit = 0;
        insuredPassenger.transfer(credit);
        uint256 finalCredit = passengers[insuredPassenger].credit;
        return (initialBalance, credit, address(this).balance, finalCredit, insuredPassenger, address(this));
    
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund
                            (   
                            )
                            public
                            payable
                            requireIsOperational
    {
        uint256 currentFunds = airlines[msg.sender].funded;
        airlines[msg.sender].funded =  currentFunds.add(msg.value);
    }

        function isAirline (
                            address airline
                        )
                        external
                        view
                        returns (bool) {
        if (airlines[airline].airlineWallet == airline) {
            return true;
        } else {
            return false;
        }
    }


    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() 
                            external 
                            payable 
    {
        fund();
    }


}

