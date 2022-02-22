// SPDX-License-Identifier: GPL

pragma solidity ^0.8.0;
/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
    constructor() {
        _transferOwnership(_msgSender());
    }
    */

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    /*
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    */
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract MinterRole is Ownable {
    mapping (address => bool) public minter_role;

    function setMinterRole(address _who, bool _status) public onlyOwner
    {
        minter_role[_who] = _status;
    }

    modifier onlyMinter
    {
        require(minter_role[msg.sender], "Minter role required");
        _;
    }
}

//https://github.com/willitscale/solidity-util/blob/000a42d4d7c1491cde4381c29d4b775fa7e99aac/lib/Strings.sol#L317-L336

/**
 * Strings Library
 * 
 * In summary this is a simple library of string functions which make simple 
 * string operations less tedious in solidity.
 * 
 * Please be aware these functions can be quite gas heavy so use them only when
 * necessary not to clog the blockchain with expensive transactions.
 * 
 * @author James Lockhart <james@n3tw0rk.co.uk>
 */
library Strings {

    /**
     * Concat (High gas cost)
     * 
     * Appends two strings together and returns a new value
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string which will be the concatenated
     *              prefix
     * @param _value The value to be the concatenated suffix
     * @return string The resulting string from combinging the base and value
     */
    function concat(string memory _base, string memory _value)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length > 0);

        string memory _tmpValue = new string(_baseBytes.length +
            _valueBytes.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for (i = 0; i < _baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for (i = 0; i < _valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }

        return string(_newValue);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function indexOf(string memory _base, string memory _value)
        internal
        pure
        returns (int) {
        return _indexOf(_base, _value, 0);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string starting
     * from a defined offset
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @param _offset The starting point to start searching from which can start
     *                from 0, but must not exceed the length of the string
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function _indexOf(string memory _base, string memory _value, uint _offset)
        internal
        pure
        returns (int) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length == 1);

        for (uint i = _offset; i < _baseBytes.length; i++) {
            if (_baseBytes[i] == _valueBytes[0]) {
                return int(i);
            }
        }

        return -1;
    }

    /**
     * Length
     * 
     * Returns the length of the specified string
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string to be measured
     * @return uint The length of the passed string
     */
    function length(string memory _base)
        internal
        pure
        returns (uint) {
        bytes memory _baseBytes = bytes(_base);
        return _baseBytes.length;
    }

    /**
     * Sub String
     * 
     * Extracts the beginning part of a string based on the desired length
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string that will be used for 
     *              extracting the sub string from
     * @param _length The length of the sub string to be extracted from the base
     * @return string The extracted sub string
     */
    function substring(string memory _base, int _length)
        internal
        pure
        returns (string memory) {
        return _substring(_base, _length, 0);
    }

    /**
     * Sub String
     * 
     * Extracts the part of a string based on the desired length and offset. The
     * offset and length must not exceed the lenth of the base string.
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string that will be used for 
     *              extracting the sub string from
     * @param _length The length of the sub string to be extracted from the base
     * @param _offset The starting point to extract the sub string from
     * @return string The extracted sub string
     */
    function _substring(string memory _base, int _length, int _offset)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);

        assert(uint(_offset + _length) <= _baseBytes.length);

        string memory _tmp = new string(uint(_length));
        bytes memory _tmpBytes = bytes(_tmp);

        uint j = 0;
        for (uint i = uint(_offset); i < uint(_offset + _length); i++) {
            _tmpBytes[j++] = _baseBytes[i];
        }

        return string(_tmpBytes);
    }
    
    function split(string memory _base, string memory _value)
        internal
        pure
        returns (string[] memory splitArr) {
        bytes memory _baseBytes = bytes(_base);

        uint _offset = 0;
        uint _splitsCount = 1;
        while (_offset < _baseBytes.length - 1) {
            int _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1)
                break;
            else {
                _splitsCount++;
                _offset = uint(_limit) + 1;
            }
        }

        splitArr = new string[](_splitsCount);

        _offset = 0;
        _splitsCount = 0;
        while (_offset < _baseBytes.length - 1) {

            int _limit = _indexOf(_base, _value, _offset);
            if (_limit == - 1) {
                _limit = int(_baseBytes.length);
            }

            string memory _tmp = new string(uint(_limit) - _offset);
            bytes memory _tmpBytes = bytes(_tmp);

            uint j = 0;
            for (uint i = _offset; i < uint(_limit); i++) {
                _tmpBytes[j++] = _baseBytes[i];
            }
            _offset = uint(_limit) + 1;
            splitArr[_splitsCount++] = string(_tmpBytes);
        }
        return splitArr;
    }

    /**
     * Compare To
     * 
     * Compares the characters of two strings, to ensure that they have an 
     * identical footprint
     * 
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string base to compare against
     * @param _value The string the base is being compared to
     * @return bool Simply notates if the two string have an equivalent
     */
    function compareTo(string memory _base, string memory _value)
        internal
        pure
        returns (bool) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        if (_baseBytes.length != _valueBytes.length) {
            return false;
        }

        for (uint i = 0; i < _baseBytes.length; i++) {
            if (_baseBytes[i] != _valueBytes[i]) {
                return false;
            }
        }

        return true;
    }

    /**
     * Compare To Ignore Case (High gas cost)
     * 
     * Compares the characters of two strings, converting them to the same case
     * where applicable to alphabetic characters to distinguish if the values
     * match.
     * 
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string base to compare against
     * @param _value The string the base is being compared to
     * @return bool Simply notates if the two string have an equivalent value
     *              discarding case
     */
    function compareToIgnoreCase(string memory _base, string memory _value)
        internal
        pure
        returns (bool) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        if (_baseBytes.length != _valueBytes.length) {
            return false;
        }

        for (uint i = 0; i < _baseBytes.length; i++) {
            if (_baseBytes[i] != _valueBytes[i] &&
            _upper(_baseBytes[i]) != _upper(_valueBytes[i])) {
                return false;
            }
        }

        return true;
    }

    /**
     * Upper
     * 
     * Converts all the values of a string to their corresponding upper case
     * value.
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to upper case
     * @return string 
     */
    function upper(string memory _base)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _upper(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Lower
     * 
     * Converts all the values of a string to their corresponding lower case
     * value.
     * 
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to lower case
     * @return string 
     */
    function lower(string memory _base)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _lower(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Upper
     * 
     * Convert an alphabetic character to upper case and return the original
     * value when not alphabetic
     * 
     * @param _b1 The byte to be converted to upper case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a lower case otherwise returns the original value
     */
    function _upper(bytes1 _b1)
        private
        pure
        returns (bytes1) {

        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1) - 32);
        }

        return _b1;
    }

    /**
     * Lower
     * 
     * Convert an alphabetic character to lower case and return the original
     * value when not alphabetic
     * 
     * @param _b1 The byte to be converted to lower case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a upper case otherwise returns the original value
     */
    function _lower(bytes1 _b1)
        private
        pure
        returns (bytes1) {

        if (_b1 >= 0x41 && _b1 <= 0x5A) {
            return bytes1(uint8(_b1) + 32);
        }

        return _b1;
    }
}

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

interface INFT {

    event NewBid       (uint256 indexed tokenID, uint256 indexed bidAmount, bytes bidData);
    event TokenTrade   (uint256 indexed tokenID, address indexed new_owner, address indexed previous_owner, uint256 priceInWEI);
    event Transfer     (address indexed from, address indexed to, uint256 indexed tokenId);
    event TransferData (bytes data);
    
    struct Properties {
        
        // In this example properties of the given NFT are stored
        // in a dynamically sized array of strings
        // properties can be re-defined for any specific info
        // that a particular NFT is intended to store.
        
        /* Properties could look like this:
        bytes   property1;
        bytes   property2;
        address property3;
        */
        
        string[] properties;
    }
    
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function standard() external view returns (string memory);
    function balanceOf(address _who) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function transfer(address _to, uint256 _tokenId, bytes calldata _data) external returns (bool);
    function silentTransfer(address _to, uint256 _tokenId) external returns (bool);
    
    function priceOf(uint256 _tokenId) external view returns (uint256);
    function bidOf(uint256 _tokenId) external view returns (uint256 price, address payable bidder, uint256 timestamp);
    function getTokenProperties(uint256 _tokenId) external view returns (Properties memory);
    
    function setBid(uint256 _tokenId, bytes calldata _data) payable external; // bid amount is defined by msg.value
    function setPrice(uint256 _tokenId, uint256 _amountInWEI) external;
    function withdrawBid(uint256 _tokenId) external returns (bool);
}

abstract contract NFTReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external virtual returns(bytes4);
}

// ExtendedNFT is a version of the CallistoNFT standard token
// that implements a set of function for NFT content management
contract ExtendedNFT is INFT, ReentrancyGuard {
    using Strings for string;
    using Address for address;
    
    mapping (uint256 => Properties) private _tokenProperties;
    mapping (uint32 => Fee)         public feeLevels; // level # => (fee receiver, fee percentage)
    
    uint256 public bidLock = 1 days; // Time required for a bid to become withdrawable.
    
    struct Bid {
        address payable bidder;
        uint256 amountInWEI;
        uint256 timestamp;
    }
    
    struct Fee {
        address payable feeReceiver;
        uint256 feePercentage; // Will be divided by 100000 during calculations
                               // feePercentage of 100 means 0.1% fee
                               // feePercentage of 2500 means 2.5% fee
    }
    
    mapping (uint256 => uint256) private _asks; // tokenID => price of this token (in WEI)
    mapping (uint256 => Bid)     private _bids; // tokenID => price of this token (in WEI)
    mapping (uint256 => uint32)  private _tokenFeeLevels; // tokenID => level ID / 0 by default

    uint256 public next_mint_id;

    // Token name
    string internal _name;

    // Token symbol
    string internal _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) internal _owners;

    // Mapping owner address to token count
    mapping(address => uint256) internal _balances;
    

    // Reward is always paid based on BID
    modifier checkTrade(uint256 _tokenId)
    {
        _;
        (uint256 _bid, address payable _bidder,) = bidOf(_tokenId);
        if(priceOf(_tokenId) > 0 && priceOf(_tokenId) <= _bid)
        {
            uint256 _reward = _bid - _claimFee(_bid, _tokenId);

            emit TokenTrade(_tokenId, _bidder, ownerOf(_tokenId), _reward);

            payable(ownerOf(_tokenId)).transfer(_reward);

            bytes calldata _empty;
            delete _bids[_tokenId];
            delete _asks[_tokenId];
            _transfer(ownerOf(_tokenId), _bidder, _tokenId, _empty);
            /*if(address(_bidder).isContract())
            {
                NFTReceiver(_bidder).onERC721Received(address(this), ownerOf(_tokenId), _tokenId, hex"000000");
            }*/
        }
    }
    
    function standard() public view virtual override returns (string memory)
    {
        return "NFT X";
    }

    function mint() internal /* onlyOwner or onlyAdmin */ returns (uint256 _mintedId)
    {
        _safeMint(msg.sender, next_mint_id);
        _mintedId = next_mint_id;
        next_mint_id++;

        _configureNFT(_mintedId);
    }
    
    function priceOf(uint256 _tokenId) public view virtual override returns (uint256)
    {
        address owner = _owners[_tokenId];
        require(owner != address(0), "NFT: owner query for nonexistent token");
        return _asks[_tokenId];
    }
    
    function bidOf(uint256 _tokenId) public view virtual override returns (uint256 price, address payable bidder, uint256 timestamp)
    {
        address owner = _owners[_tokenId];
        require(owner != address(0), "NFT: owner query for nonexistent token");
        return (_bids[_tokenId].amountInWEI, _bids[_tokenId].bidder, _bids[_tokenId].timestamp);
    }
    
    function getTokenProperties(uint256 _tokenId) public view virtual override returns (Properties memory)
    {
        return _tokenProperties[_tokenId];
    }

    function getTokenProperty(uint256 _tokenId, uint256 _propertyId)  public view virtual returns (string memory)
    {
        return _tokenProperties[_tokenId].properties[_propertyId];
    }

    function _addPropertyWithContent(uint256 _tokenId, string calldata _content) internal
    {
        // Check permission criteria

        _tokenProperties[_tokenId].properties.push(_content);
    }

    function _modifyProperty(uint256 _tokenId, uint256 _propertyId, string calldata _content) internal
    {
        _tokenProperties[_tokenId].properties[_propertyId] = _content;
    }

    function _appendProperty(uint256 _tokenId, uint256 _propertyId, string calldata _content) internal
    {
        _tokenProperties[_tokenId].properties[_propertyId] = _tokenProperties[_tokenId].properties[_propertyId].concat(_content);
    }
    
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "NFT: balance query for the zero address");
        return _balances[owner];
    }
    
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "NFT: owner query for nonexistent token");
        return owner;
    }
    
    /* 
        Price == 0, "NFT not on sale"
        Price > 0, "NFT on sale"
    */
    function setPrice(uint256 _tokenId, uint256 _amountInWEI) checkTrade(_tokenId) public virtual override nonReentrant {
        require(ownerOf(_tokenId) == msg.sender, "Setting asks is only allowed for owned NFTs!");
        _asks[_tokenId] = _amountInWEI;
    }
    
    function setBid(uint256 _tokenId, bytes calldata _data) payable checkTrade(_tokenId) public virtual override nonReentrant
    {
        (uint256 _previousBid, address payable _previousBidder, ) = bidOf(_tokenId);
        require(msg.value > _previousBid, "New bid must exceed the existing one");

        uint256 _bid;
        
        // Return previous bid if the current one exceeds it.
        if(_previousBid != 0)
        {
            _previousBidder.transfer(_previousBid);
        }
        // Refund overpaid amount.
        if (priceOf(_tokenId) < msg.value)
        {
            _bid = priceOf(_tokenId);
        }
        else
        {
            _bid = msg.value;
        }
        _bids[_tokenId].amountInWEI = _bid;
        _bids[_tokenId].bidder      = payable(msg.sender);
        _bids[_tokenId].timestamp   = block.timestamp;

        emit NewBid(_tokenId, _bid, _data);
        
        // Send back overpaid amount.
        // WARHNING: Creates possibility for reentrancy.
        if (priceOf(_tokenId) < msg.value)
        {
            payable(msg.sender).transfer(msg.value - priceOf(_tokenId));
        }
    }
    
    function withdrawBid(uint256 _tokenId) public virtual override nonReentrant returns (bool) 
    {
        (uint256 _bid, address payable _bidder, uint256 _timestamp) = bidOf(_tokenId);
        require(msg.sender == _bidder, "Can not withdraw someone elses bid");
        require(block.timestamp > _timestamp + bidLock, "Bid is time-locked");
        
        _bidder.transfer(_bid);
        delete _bids[_tokenId];
        return true;
    }
    
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    
    function transfer(address _to, uint256 _tokenId, bytes calldata _data) public override returns (bool)
    {
        _transfer(msg.sender, _to, _tokenId, _data);
        emit TransferData(_data);
        return true;
    }
    
    function silentTransfer(address _to, uint256 _tokenId) public override returns (bool)
    {
        require(ExtendedNFT.ownerOf(_tokenId) == msg.sender, "NFT: transfer of token that is not own");
        require(_to != address(0), "NFT: transfer to the zero address");
        
        _asks[_tokenId] = 0; // Zero out price on transfer
        
        // When a user transfers the NFT to another user
        // it does not automatically mean that the new owner
        // would like to sell this NFT at a price
        // specified by the previous owner.
        
        // However bids persist regardless of token transfers
        // because we assume that the bidder still wants to buy the NFT
        // no matter from whom.

        _beforeTokenTransfer(msg.sender, _to, _tokenId);

        _balances[msg.sender] -= 1;
        _balances[_to] += 1;
        _owners[_tokenId] = _to;

        emit Transfer(msg.sender, _to, _tokenId);
        return true;
    }
    
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }
    
    function _claimFee(uint256 _amountFrom, uint256 _tokenId) internal returns (uint256)
    {
        uint32 _level          = _tokenFeeLevels[_tokenId];
        address _feeReceiver   = feeLevels[_level].feeReceiver;
        uint256 _feePercentage = feeLevels[_level].feePercentage;
        
        uint256 _feeAmount = _amountFrom * _feePercentage / 100000;
        payable(_feeReceiver).transfer(_feeAmount);
        return _feeAmount;        
    }
    
    function _safeMint(
        address to,
        uint256 tokenId
    ) internal virtual {
        _mint(to, tokenId);
    }
    
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "NFT: mint to the zero address");
        require(!_exists(tokenId), "NFT: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }
    
    function _burn(uint256 tokenId) internal virtual {
        address owner = ExtendedNFT.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);
        

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }
    
    function _transfer(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) internal virtual {
        require(ExtendedNFT.ownerOf(tokenId) == from, "NFT: transfer of token that is not own");
        require(to != address(0), "NFT: transfer to the zero address");
        
        _asks[tokenId] = 0; // Zero out price on transfer
        
        // When a user transfers the NFT to another user
        // it does not automatically mean that the new owner
        // would like to sell this NFT at a price
        // specified by the previous owner.
        
        // However bids persist regardless of token transfers
        // because we assume that the bidder still wants to buy the NFT
        // no matter from whom.

        _beforeTokenTransfer(from, to, tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        if(to.isContract())
        {
            NFTReceiver(to).onERC721Received(msg.sender, msg.sender, tokenId, data);
        }

        emit Transfer(from, to, tokenId);
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function _configureNFT(uint256 _tokenId) internal
    {
        if(_tokenProperties[_tokenId].properties.length == 0)
        {
            _tokenProperties[_tokenId].properties.push("");
        }
    }
}

interface IClassifiedNFT is INFT {
    function setClassForTokenID(uint256 _tokenID, uint256 _tokenClass) external;
    function addNewTokenClass() external;
    function addTokenClassProperties(uint256 _propertiesCount) external;
    function modifyClassProperty(uint256 _classID, uint256 _propertyID, string memory _content) external;
    function getClassProperty(uint256 _classID, uint256 _propertyID) external view returns (string memory);
    function addClassProperty(uint256 _classID) external;
    function getClassProperties(uint256 _classID) external view returns (string[] memory);
    function getClassForTokenID(uint256 _tokenID) external view returns (uint256);
    function getClassPropertiesForTokenID(uint256 _tokenID) external view returns (string[] memory);
    function getClassPropertyForTokenID(uint256 _tokenID, uint256 _propertyID) external view returns (string memory);
    function mintWithClass(uint256 classId)  external  returns (uint256 _newTokenID);
    function appendClassProperty(uint256 _classID, uint256 _propertyID, string memory _content) external;
}


abstract contract ClassifiedNFT is MinterRole, ExtendedNFT, IClassifiedNFT {
    using Strings for string;

    mapping (uint256 => string[]) public class_properties;
    mapping (uint256 => uint256)  public token_classes;

    uint256 public nextClassIndex = 0;

    modifier onlyExistingClasses(uint256 classId)
    {
        require(classId < nextClassIndex, "Queried class does not exist");
        _;
    }

    function setClassForTokenID(uint256 _tokenID, uint256 _tokenClass) public onlyOwner override
    {
        token_classes[_tokenID] = _tokenClass;
    }

    function addNewTokenClass() public onlyOwner override
    {
        class_properties[nextClassIndex].push("");
        nextClassIndex++;
    }

    function addTokenClassProperties(uint256 _propertiesCount) public onlyOwner override
    {
        for (uint i = 0; i < _propertiesCount; i++)
        {
            class_properties[nextClassIndex].push("");
        }
    }

    function modifyClassProperty(uint256 _classID, uint256 _propertyID, string memory _content) public onlyOwner onlyExistingClasses(_classID) override
    {
        class_properties[_classID][_propertyID] = _content;
    }

    function getClassProperty(uint256 _classID, uint256 _propertyID) public view onlyExistingClasses(_classID) override returns (string memory)
    {
        return class_properties[_classID][_propertyID];
    }

    function addClassProperty(uint256 _classID) public onlyOwner onlyExistingClasses(_classID) override
    {
        class_properties[_classID].push("");
    }

    function getClassProperties(uint256 _classID) public view onlyExistingClasses(_classID) override returns (string[] memory)
    {
        return class_properties[_classID];
    }

    function getClassForTokenID(uint256 _tokenID) public view onlyExistingClasses(token_classes[_tokenID]) override returns (uint256)
    {
        return token_classes[_tokenID];
    }

    function getClassPropertiesForTokenID(uint256 _tokenID) public view onlyExistingClasses(token_classes[_tokenID]) override returns (string[] memory)
    {
        return class_properties[token_classes[_tokenID]];
    }

    function getClassPropertyForTokenID(uint256 _tokenID, uint256 _propertyID) public view onlyExistingClasses(token_classes[_tokenID]) override returns (string memory)
    {
        return class_properties[token_classes[_tokenID]][_propertyID];
    }
    
    function mintWithClass(uint256 classId)  public /* onlyOwner */ onlyExistingClasses(classId) onlyMinter override returns (uint256 _newTokenID)
    {
        //_mint(to, tokenId);
        _newTokenID = mint();
        token_classes[_newTokenID] = classId;
    }

    function appendClassProperty(uint256 _classID, uint256 _propertyID, string memory _content) public onlyOwner onlyExistingClasses(_classID) override
    {
        class_properties[_classID][_propertyID] = class_properties[_classID][_propertyID].concat(_content);
    }
}


abstract contract VersionableNFT is ExtendedNFT {
    event TokenUpdate(uint256 indexed tokenId, uint256 indexed previous_version, uint256 indexed relevant_version);
    uint256 public relevantVersion = 1;

    mapping (uint256 => uint256) public token_versions;
    mapping (string => uint256)  public property_to_class;

    function selfUpdate(uint256 _tokenID) internal
    {
        emit TokenUpdate(_tokenID, token_versions[_tokenID], relevantVersion);
        token_versions[_tokenID] = relevantVersion;
    }
}


contract ArtefinNFT is ExtendedNFT, VersionableNFT, ClassifiedNFT {

    function initialize(string memory name_, string memory symbol_, uint256 _defaultFee) external {
        require(_owner == address(0), "Already initialized");
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
        bidLock = 1 days;
        _name   = name_;
        _symbol = symbol_;
        feeLevels[0].feeReceiver   = payable(msg.sender);
        feeLevels[0].feePercentage = _defaultFee;
    }

    function NextUpdate() public onlyOwner
    {
        relevantVersion++;
    }

    function setPropertyToClass(string memory _propertyText, uint256 _newClassID) public onlyOwner
    {
        property_to_class[_propertyText] = _newClassID;
    }

    function addPropertyWithContent(uint256 _tokenId, string calldata _content) public onlyOwner
    {
        _addPropertyWithContent( _tokenId, _content);
    }

    function modifyProperty(uint256 _tokenId, uint256 _propertyId, string calldata _content) public onlyOwner
    {
        _modifyProperty(_tokenId, _propertyId, _content);
    }

    function appendProperty(uint256 _tokenId, uint256 _propertyId, string calldata _content) public onlyOwner
    {
        _appendProperty(_tokenId, _propertyId, _content);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override
    {
        if(token_versions[tokenId] < relevantVersion)
        {
            if(token_classes[tokenId] == 0)
            {
                selfUpdate(tokenId);
                setClassForTokenID(tokenId, property_to_class[getTokenProperties(tokenId).properties[0]]);
            }
        }
    }
}

contract ActivatedByOwner is Ownable {
    bool public active = true;

    function setActive(bool _active) public onlyOwner
    {
        active = _active;
    }

    modifier onlyActive
    {
        require(active, "This contract is deactivated by owner");
        _;
    }
}

contract NFTMulticlassLinearAuction is ActivatedByOwner {

    event AuctionCreated(uint256 indexed tokenClassAuctionID, uint256 timestamp);
    event TokenSold(uint256 indexed tokenID, uint256 indexed tokenClassID, address indexed buyer);
    event NFTContractSet(address indexed newNFTContract, address indexed oldNFTContract);
    event RevenueWithdrawal(uint256 amount);
    

    address public nft_contract;

    struct NFTAuctionClass
    {
        uint256 max_supply;
        uint256 amount_sold;
        uint256 start_timestamp;
        uint256 duration;
        uint256 priceInWei;
        string[] configuratin_properties;
    }

    mapping (uint256 => NFTAuctionClass) public auctions; // Mapping from classID (at NFT contract) to set of variables
                                                          //  defining the auction for this token class.

    address payable public revenue = payable(0x01000B5fE61411C466b70631d7fF070187179Bbf); // This address has the rights to withdraw funds from the auction.

    constructor()
    {
        _owner = msg.sender;
    }

    function createNFTAuction(uint256 _classID, uint256 _max_supply, uint256 _start_timestamp, uint256 _duration, uint256 _priceInWEI /*, string[] memory _properties */) public onlyOwner
    {
        /*
        max_supply_by_class[_classID]      = _max_supply;
        amount_sold_by_class[_classID]     = 0;
        start_timestamp_by_class[_classID] = _start_timestamp;
        duration_by_class[_classID]        = _duration;
        priceInWEI_by_class[_classID]      = _priceInWEI;
        */

        auctions[_classID].max_supply      = _max_supply;
        auctions[_classID].amount_sold     = 0;
        auctions[_classID].start_timestamp = _start_timestamp;
        auctions[_classID].duration        = _duration;
        auctions[_classID].priceInWei      = _priceInWEI;


        /* configuration_properties_by_class[_classID] = _properties; */

        emit AuctionCreated(_classID, block.timestamp);
    }

    function setNFTContract(address _nftContract) public onlyOwner
    {
        emit NFTContractSet(_nftContract, nft_contract);

        nft_contract = _nftContract;
    }

    function buyNFT(uint256 _classID) public payable onlyActive
    {
        // WARNING!
        // This function does not refund overpaid amount at the moment.
        // TODO

        require(msg.value >= auctions[_classID].priceInWei, "Insufficient funds");
        require(auctions[_classID].amount_sold < auctions[_classID].max_supply, "This auction has already sold all allocated NFTs");
        require(block.timestamp < auctions[_classID].start_timestamp + auctions[_classID].duration, "This auction already expired");
        require(block.timestamp > auctions[_classID].start_timestamp, "This auction is not yet started");
        require(auctions[_classID].priceInWei != 0, "Min price is not configured by the owner");

        uint256 _mintedId = ClassifiedNFT(nft_contract).mintWithClass(_classID);
        configureNFT(_mintedId, _classID);
        auctions[_classID].amount_sold++;

        ClassifiedNFT(nft_contract).transfer(msg.sender, _mintedId, "");

        emit TokenSold(_mintedId, _classID, msg.sender);
    }

    function configureNFT(uint256 _tokenId, uint256 _classId) internal
    {
        //Add Serial Number to the created Token
        uint256 tokenSerialNumber = auctions[_classId].amount_sold + 1;
        ArtefinNFT(nft_contract).addPropertyWithContent(_tokenId, toString(tokenSerialNumber));
    }

    function withdrawRevenue() public onlyOwner
    {
        require(msg.sender == revenue, "This action requires revenue permission");

        emit RevenueWithdrawal(address(this).balance);

        revenue.transfer(address(this).balance);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol#L15-L35

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}


contract NFTMulticlassBiddableAuction is ActivatedByOwner {

    event AuctionCreated(uint256 indexed tokenClassAuctionID, uint256 timestamp);
    //event TokenSold(uint256 indexed tokenID, uint256 indexed tokenClassID, address indexed buyer);
    event NFTContractSet(address indexed newNFTContract, address indexed oldNFTContract);
    event RevenueWithdrawal(uint256 amount);
    event RoundEnd(uint256 indexed tokenClassAuctionID, address indexed winner, uint256 indexed acquiredTokenID);
    event NewRound(uint256 indexed tokenClassAuctionID, uint256 indexed startTimestamp, uint256 indexed endTimestamp);

    address public nft_contract;

    struct NFTBiddableAuctionClass
    {
        uint256 max_supply;
        uint256 amount_sold;
        uint256 start_timestamp;
        uint256 duration;
        uint256 min_priceInWei;
        uint256 highest_bid;
        address winner;
        string[] configuratin_properties;
    }

    mapping (uint256 => NFTBiddableAuctionClass) public auctions; // Mapping from classID (at NFT contract) to set of variables
                                                                  //  defining the auction for this token class.

    mapping (uint256 => uint256) public max_supply_by_class; // This auction will sell exactly this number of NFTs.
    mapping (uint256 => uint256) public amount_sold_by_class; // Increments on each successful NFT purchase until it reachess `max_supply`.

    mapping (uint256 => uint256) public start_timestamp_by_class; // UNIX timestamp of the auction start event.
    mapping (uint256 => uint256) public duration_by_class;

    mapping (uint256 => uint256) public min_priceInWEI_by_class;
    mapping (uint256 => uint256) public highest_bid_by_class;
    mapping (uint256 => address) public winner_by_class;

    mapping (uint256 => string[]) public configuration_properties_by_class;

    uint256 public revenue_amount; // total amount of revenue

    address payable public revenue = payable(0x01000B5fE61411C466b70631d7fF070187179Bbf); // This address has the rights to withdraw funds from the auction.

    constructor()
    {
        _owner = msg.sender;
    }

    function createNFTAuction(uint256 _classID, uint256 _max_supply, uint256 _start_timestamp, uint256 _duration, uint256 _minPriceInWEI /*, string[] memory _properties */) public onlyOwner
    {
        auctions[_classID].max_supply      = _max_supply;
        auctions[_classID].amount_sold     = 0;
        auctions[_classID].start_timestamp = _start_timestamp;
        auctions[_classID].duration        = _duration;
        auctions[_classID].min_priceInWei  = _minPriceInWEI;

        /* configuration_properties_by_class[_classID] = _properties; */

        emit AuctionCreated(_classID, block.timestamp);
    }

    function setNFTContract(address _nftContract) public onlyOwner
    {
        emit NFTContractSet(nft_contract, _nftContract);

        nft_contract = _nftContract;
    }
    
    function bidOnNFT(uint256 _classID) public payable onlyActive
    {
        require(msg.value >= auctions[_classID].min_priceInWei, "Insufficient funds");

        require(auctions[_classID].start_timestamp < block.timestamp, "Auction did not start yet");
        if(auctions[_classID].start_timestamp + auctions[_classID].duration < block.timestamp)
        {
            endRound(_classID);
        }

        require(auctions[_classID].max_supply > auctions[_classID].amount_sold, "All NFTs of this artwork are already sold");

        require(
            msg.value >= auctions[_classID].highest_bid + auctions[_classID].highest_bid/20 && 
            msg.value >= auctions[_classID].highest_bid + 1e18,
            "Does not outbid current winner by 5%"
        );
        require(auctions[_classID].min_priceInWei != 0, "Min price is not configured by the owner");
        require(msg.value >= auctions[_classID].min_priceInWei, "Min price criteria is not met");

        payable(auctions[_classID].winner).transfer(auctions[_classID].highest_bid);

        auctions[_classID].winner      = msg.sender;
        auctions[_classID].highest_bid = msg.value;
    }

    function resetRound(uint256 _classID) internal
    {
        auctions[_classID].winner          = address(0);
        auctions[_classID].highest_bid     = 0;
        auctions[_classID].start_timestamp = block.timestamp;

        emit NewRound(_classID, block.timestamp, auctions[_classID].start_timestamp + auctions[_classID].duration);
    }

    function endRound(uint256 _classID) public
    {
        require(block.timestamp > auctions[_classID].start_timestamp + auctions[_classID].duration, "Auction is still in progress");
        auctions[_classID].amount_sold++;

        uint256 _mintedId = ClassifiedNFT(nft_contract).mintWithClass(_classID);
        configureNFT(_mintedId, _classID);

        ClassifiedNFT(nft_contract).transfer(auctions[_classID].winner, _mintedId, "");

        emit RoundEnd(_classID, auctions[_classID].winner, _mintedId);
        revenue_amount += auctions[_classID].highest_bid;

        if(auctions[_classID].amount_sold != auctions[_classID].max_supply)
        {
            resetRound(_classID);
        }
    }

    function configureNFT(uint256 _tokenId, uint256 _classId) internal
    {
        //Add Serial Number to the created Token
        uint256 tokenSerialNumber = auctions[_classId].amount_sold;
        ArtefinNFT(nft_contract).addPropertyWithContent(_tokenId, toString(tokenSerialNumber));
    }

    function withdrawRevenue() public onlyOwner
    {
        require(msg.sender == revenue, "This action requires revenue permission");

        emit RevenueWithdrawal(address(this).balance);

        revenue.transfer(revenue_amount);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol#L15-L35

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
