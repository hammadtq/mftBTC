contract Governance {
    address public admin;
    mapping(bytes32 => uint256) public parameters;

    event ParameterUpdated(bytes32 indexed param, uint256 value);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can update");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function setParameter(bytes32 param, uint256 value) external onlyAdmin {
        parameters[param] = value;
        emit ParameterUpdated(param, value);
    }
}