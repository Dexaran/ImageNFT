// SPDX-License-Identifier: GPL

pragma solidity ^0.8.0;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

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

interface INFT {
    
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
    
    function setBid(uint256 _tokenId, bytes calldata _data) payable external;
    function withdrawBid(uint256 _tokenId) external returns (bool);
}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

abstract contract NFTReceiver {
    function nftReceived(address _from, uint256 _tokenId, bytes calldata _data) external virtual;
}

contract NFT is INFT, Ownable{
    
    using Address for address;
    
    event Transfer     (address indexed from, address indexed to, uint256 indexed tokenId);
    event TransferData (bytes data);
    
    mapping (uint256 => Properties) private _tokenProperties;
    mapping (uint32 => Fee)         public feeLevels; // level # => (fee receiver, fee percentage)
    
    uint256 public bidLock; // = 1 days; // Time required for a bid to become withdrawable.
    
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

    struct Auction {
        address winner;
        uint256 bet;
        uint256 start_timestamp;
        uint256 duration;
        uint256 min_price;
    }

    struct Artwork {
        bool exists;

        uint256 num_original;
        uint256 num_gold;
        uint256 num_silver;
        uint256 num_bronze;

        //uint256 price_original; // Price is not required as "Originals" are sold via auction
        //uint256 price_gold;     // Price is not required as "Golds" are also sold via auction
        uint256 price_silver;
        uint256 price_bronze;

        string propertyInfo; // Properties are assigned in JSON format:     {"autor":"John", "age":30}
        string propertyBronzeImage; // {"work_title":"Johns Work"}
        string propertyOriginalImage; // {"work_description":"Awesome work"}
        string propertySilverImage; // {"license":"https://mylicense.org"}
        string propertyGoldImage; // {"license":"https://mylicense.org"}
    }

    uint256 public default_auction_duration; // = 30 days;

    uint256 public revenue;

    mapping (uint256 => string) public artwork_names_list;
    uint256 public artworks_count;

    mapping (string => Artwork) public artworks;

    mapping (string => Auction) public gold_auctions;
    mapping (string => Auction) public original_auctions;
    
    mapping (uint256 => uint256) public _asks; // tokenID => price of this token (in WEI)
    mapping (uint256 => Bid)     public _bids; // tokenID => price of this token (in WEI)
    mapping (uint256 => uint32)  public _tokenFeeLevels; // tokenID => level ID / 0 by default

    uint256 public last_minted_id;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) public _owners;

    // Mapping owner address to token count
    mapping(address => uint256) public _balances;

    // Mapping artwork address to artist fee level
    mapping (string => uint32) public artworkFeeReceiver;

    struct ArtworkMaxCap {
        uint256 num_original;
        uint256 num_gold;
        uint256 num_silver;
        uint256 num_bronze;
    }

    mapping (string => ArtworkMaxCap) public artworksMaxCap;

    // Mapping artwork to start sale timestamp
    mapping (string => uint256) public silverStartSaleTimestamps;
    mapping (string => uint256) public bronzeStartSaleTimestamps;

    //Admins list
    mapping (address => bool) public admins;

    event bid(address _bidder, uint256 _bid);

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
    constructor(string memory name_, string memory symbol_, uint256 _defaultFee) {
        _name   = name_;
        _symbol = symbol_;
        feeLevels[0].feeReceiver   = payable(msg.sender);
        feeLevels[0].feePercentage = _defaultFee;
    }
    */

    function initialize(string memory name_, string memory symbol_, uint256 _defaultFee) external {
        require(_owner == address(0), "Already initialized");
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
        bidLock = 1 days;
        default_auction_duration = 30 days;
        _name   = name_;
        _symbol = symbol_;
        feeLevels[0].feeReceiver   = payable(msg.sender);
        feeLevels[0].feePercentage = _defaultFee;
    }

    function addAdmin (address _newAdmin) public onlyOwner {
        admins[_newAdmin] = true;
    }

    function removeAdmin (address _admin) public onlyOwner {
        admins[_admin] = false;
    }

    function changeDefaultAuctionDuration(uint256 _newDuration) public onlyOwner
    {
        default_auction_duration = _newDuration;
    }

    function configureAuction(
        string memory _artwork_name, 
        uint256 _goldMinPrice, 
        uint256 _originalMinPrice, 
        uint256 _goldStartTimestamp, 
        uint256 _originalStartTimestamp,
        uint256 _gold_duration_in_seconds,
        uint256 _original_duration_in_seconds
        ) public onlyOwner
    {
        gold_auctions[_artwork_name].min_price = _goldMinPrice;
        gold_auctions[_artwork_name].start_timestamp = _goldStartTimestamp;

        original_auctions[_artwork_name].min_price = _originalMinPrice;
        original_auctions[_artwork_name].start_timestamp = _originalStartTimestamp;

        original_auctions[_artwork_name].duration = _original_duration_in_seconds;
        gold_auctions[_artwork_name].duration = _gold_duration_in_seconds;

    }

    function setArtistFeeLevels(uint32 _artistIndex, address _artistWallet, uint256 _artistFeePercentage) public onlyOwner{
        feeLevels[_artistIndex].feeReceiver   = payable(_artistWallet);
        feeLevels[_artistIndex].feePercentage = _artistFeePercentage;
    }

    function setArtworkFeeReceiver (string memory _artwork_name, uint32 _artistIndex) public onlyOwner{
        artworkFeeReceiver[_artwork_name] = _artistIndex;
    }

    function addArtwork(string memory _artwork_name,
        uint256 num_original,
        uint256 num_gold,
        uint256 num_silver,
        uint256 num_bronze,
        uint256 price_silver,
        uint256 price_bronze,
        string memory propertyInfo,
        string memory propertyBronzeImage,
        string memory propertyGoldImage,
        string memory propertySilverImage,
        string memory propertyOriginalImage) public onlyOwner
    {
        require(!artworks[_artwork_name].exists, "This artwork NFT already exists!");
        artworks[_artwork_name].exists = true;

        artworks[_artwork_name].num_original = num_original;
        artworks[_artwork_name].num_gold     = num_gold;
        artworks[_artwork_name].num_silver   = num_silver;
        artworks[_artwork_name].num_bronze   = num_bronze;

        artworksMaxCap[_artwork_name].num_original = num_original;
        artworksMaxCap[_artwork_name].num_gold     = num_gold;
        artworksMaxCap[_artwork_name].num_silver   = num_silver;
        artworksMaxCap[_artwork_name].num_bronze   = num_bronze;

        artworks[_artwork_name].price_silver = price_silver;
        artworks[_artwork_name].price_bronze = price_bronze;

        artworks[_artwork_name].propertyInfo = propertyInfo;
        artworks[_artwork_name].propertyBronzeImage = propertyBronzeImage;
        artworks[_artwork_name].propertyGoldImage = propertyGoldImage;
        artworks[_artwork_name].propertySilverImage = propertySilverImage;
        artworks[_artwork_name].propertyOriginalImage = propertyOriginalImage;

        gold_auctions[_artwork_name].duration = default_auction_duration;
        original_auctions[_artwork_name].duration = default_auction_duration;

        artwork_names_list[artworks_count] = _artwork_name;
        artworks_count++;
    }

    function deleteArtwork(string memory _artwork_name, uint256 _artwork_number) public onlyOwner{
        delete artworks[_artwork_name];
        delete artworksMaxCap[_artwork_name];
        delete gold_auctions[_artwork_name];
        delete original_auctions[_artwork_name];
        delete silverStartSaleTimestamps[_artwork_name];
        delete bronzeStartSaleTimestamps[_artwork_name];
        delete artwork_names_list[_artwork_number];
    }

    function addStartSaleTimestamp(string memory _artwork_name, uint256 silver_start_sales_timestamp, uint256 bronze_start_sales_timestamp) public onlyOwner{
        silverStartSaleTimestamps[_artwork_name] = silver_start_sales_timestamp;
        bronzeStartSaleTimestamps[_artwork_name] = bronze_start_sales_timestamp;
    }

    function rewardsWithdraw() public onlyOwner
    {
        uint256 _revenue = revenue;
        revenue = 0;
        payable(msg.sender).transfer(_revenue);
    }

    //Remove after debbugin period
    function modifyArtworkInfo(string memory _artwork_name, string memory _newInfo) public onlyOwner
    {
        artworks[_artwork_name].propertyInfo = _newInfo;
    }

    //Remove after debbugin period
    function addTokenClassAndSerialNumber(uint256 _tokenId, string memory _tokenClass , string memory _serialNumber) public {
        require(admins[msg.sender],"You are not an admin");
        if(_tokenProperties[_tokenId].properties.length == 2){
            _tokenProperties[_tokenId].properties.push(_tokenClass);
            _tokenProperties[_tokenId].properties.push(_serialNumber);  
        }
        if(_tokenProperties[_tokenId].properties.length == 3){
            _tokenProperties[_tokenId].properties.push(_serialNumber);  
        }
    }

    //Remove after debbugin period
    function modifyTokenClass(uint256 _tokenId, string memory _tokenClass) public {
        require(admins[msg.sender],"You are not an admin");
       _tokenProperties[_tokenId].properties[2] = _tokenClass;  
    }

    //Remove after debbugin period
    function modifySerialNumber(uint256 _tokenId, string memory _serialNumber) public {
        require(admins[msg.sender],"You are not an admin");
       _tokenProperties[_tokenId].properties[3] = _serialNumber;  
    }

    //Remove after debbugin period
    function addArtworkMaxCap (
        string memory _artwork_name,
        uint256 num_original,
        uint256 num_gold,
        uint256 num_silver,
        uint256 num_bronze
    )public onlyOwner{
        artworksMaxCap[_artwork_name].num_original = num_original;
        artworksMaxCap[_artwork_name].num_gold     = num_gold;
        artworksMaxCap[_artwork_name].num_silver   = num_silver;
        artworksMaxCap[_artwork_name].num_bronze   = num_bronze;
    }

    function updateAuctionDuration(
        string calldata _artwork_name,
        uint256 _index, // 1 = gold, 0 = original.
        uint256 _new_duration_in_seconds
    ) public onlyOwner{
        if(_index == 0)
        {
            original_auctions[_artwork_name].duration = _new_duration_in_seconds;
        }
        if(_index == 1)
        {
            gold_auctions[_artwork_name].duration = _new_duration_in_seconds;
        }
    }

    function buyBronze(string calldata _artwork_name) public payable
    {
        require(artworks[_artwork_name].num_bronze > 0, "All Bronze NFTs of this artwork are already sold");
        require(msg.value >= artworks[_artwork_name].price_bronze, "Insufficient value");
        require(block.timestamp >= bronzeStartSaleTimestamps[_artwork_name], "Sale has not begun");
        require(bronzeStartSaleTimestamps[_artwork_name] != 0, "Start sale timestamp has not been set");
        revenue += msg.value;

        artworks[_artwork_name].num_bronze--;

        _mintNext(msg.sender);
        _tokenProperties[last_minted_id - 1].properties.push( artworks[_artwork_name].propertyInfo );  
        _tokenProperties[last_minted_id - 1].properties.push( artworks[_artwork_name].propertyBronzeImage );
        _tokenProperties[last_minted_id - 1].properties.push( "Bronze" );
        _tokenProperties[last_minted_id - 1].properties.push( toString(artworksMaxCap[_artwork_name].num_bronze - artworks[_artwork_name].num_bronze) );
        _tokenFeeLevels[last_minted_id - 1] = artworkFeeReceiver[_artwork_name];
     //   _tokenProperties[last_minted_id - 1].properties.push( artworks[_artwork_name].property4 );      
    }

    function buySilver(string calldata _artwork_name) public payable
    {
        require(artworks[_artwork_name].num_silver > 0, "All Silver NFTs of this artwork are already sold");
        require(msg.value >= artworks[_artwork_name].price_silver, "Insufficient value");
        require(block.timestamp >= silverStartSaleTimestamps[_artwork_name], "Sale has not begun");
        require(silverStartSaleTimestamps[_artwork_name] != 0, "Start sale timestamp has not been set");

        revenue += msg.value;

        artworks[_artwork_name].num_silver--;

        _mintNext(msg.sender);
        _tokenProperties[last_minted_id - 1].properties.push( artworks[_artwork_name].propertyInfo );  
        _tokenProperties[last_minted_id - 1].properties.push( artworks[_artwork_name].propertySilverImage );
        _tokenProperties[last_minted_id - 1].properties.push( "Silver" );
        _tokenProperties[last_minted_id - 1].properties.push( toString(artworksMaxCap[_artwork_name].num_silver - artworks[_artwork_name].num_silver) );
        _tokenFeeLevels[last_minted_id - 1] = artworkFeeReceiver[_artwork_name];
     //   _tokenProperties[last_minted_id - 1].properties.push( artworks[_artwork_name].property4 );      
    }

    function buyOriginal(string calldata _artwork_name) public payable
    {
        revenue += msg.value;

        require(original_auctions[_artwork_name].start_timestamp < block.timestamp, "Auction did not start yet");
        if(original_auctions[_artwork_name].start_timestamp == 0)
        {
            startOriginalRound(_artwork_name);
        }
        if(original_auctions[_artwork_name].start_timestamp + original_auctions[_artwork_name].duration < block.timestamp)
        {
            endOriginalRound(_artwork_name);
        }

        require(artworks[_artwork_name].num_original > 0, "All Original NFTs of this artwork are already sold");
        require(
            msg.value >= original_auctions[_artwork_name].bet + original_auctions[_artwork_name].bet/20 && 
            msg.value >= original_auctions[_artwork_name].bet + 1000000000000000000,
            "Does not outbid current winner by 5%"
        );
        require(original_auctions[_artwork_name].min_price != 0, "Min price is not configured by the owner");
        require(msg.value >= original_auctions[_artwork_name].min_price, "Min price criteria is not met");

        payable(original_auctions[_artwork_name].winner).transfer(original_auctions[_artwork_name].bet);

        original_auctions[_artwork_name].winner = msg.sender;
        original_auctions[_artwork_name].bet = msg.value;
        emit bid(msg.sender,msg.value);
    }

    function startOriginalRound(string calldata _artwork_name) internal
    {
        original_auctions[_artwork_name].winner = address(0);
        original_auctions[_artwork_name].bet = 0;
        original_auctions[_artwork_name].start_timestamp += original_auctions[_artwork_name].duration;
    }

    function endOriginalRound(string calldata _artwork_name) public
    {
        require(block.timestamp > original_auctions[_artwork_name].start_timestamp + original_auctions[_artwork_name].duration, "Auction is still in progress");
        artworks[_artwork_name].num_original--;

        /*_mintNext(msg.sender);
        _tokenProperties[last_minted_id - 1].properties.push( artworks[_artwork_name].propertyInfo );  
        _tokenProperties[last_minted_id - 1].properties.push( artworks[_artwork_name].propertyOriginalImage );
        */

        _mintNext(original_auctions[_artwork_name].winner);
        _tokenProperties[last_minted_id - 1].properties.push( artworks[_artwork_name].propertyInfo );  
        _tokenProperties[last_minted_id - 1].properties.push( artworks[_artwork_name].propertyOriginalImage );
        _tokenProperties[last_minted_id - 1].properties.push( "Original" );
        _tokenProperties[last_minted_id - 1].properties.push( "1" );
        _tokenFeeLevels[last_minted_id - 1] = artworkFeeReceiver[_artwork_name];

        if(artworks[_artwork_name].num_original != 0)
        {
            startOriginalRound(_artwork_name);
        }
    }

    function buyGold(string calldata _artwork_name) public payable
    {
        revenue += msg.value;

        require(gold_auctions[_artwork_name].start_timestamp < block.timestamp, "Auction did not start yet");
        if(gold_auctions[_artwork_name].start_timestamp == 0)
        {
            startGoldRound(_artwork_name);
        }
        if(gold_auctions[_artwork_name].start_timestamp + gold_auctions[_artwork_name].duration < block.timestamp)
        {
            endGoldRound(_artwork_name);
        }

        require(artworks[_artwork_name].num_gold > 0, "All Gold NFTs of this artwork are already sold");
        require(
            msg.value >= gold_auctions[_artwork_name].bet + gold_auctions[_artwork_name].bet/20 && 
            msg.value >= gold_auctions[_artwork_name].bet + 1000000000000000000,
            "Does not outbid current winner by 5%"
        );
        require(gold_auctions[_artwork_name].min_price != 0, "Min price is not configured by the owner");
        require(msg.value >= gold_auctions[_artwork_name].min_price, "Min price criteria is not met");

        payable(gold_auctions[_artwork_name].winner).transfer(gold_auctions[_artwork_name].bet);

        gold_auctions[_artwork_name].winner = msg.sender;
        gold_auctions[_artwork_name].bet = msg.value;
        emit bid(msg.sender,msg.value);
    }

    function startGoldRound(string calldata _artwork_name) internal
    {
        gold_auctions[_artwork_name].winner = address(0);
        gold_auctions[_artwork_name].bet = 0;
        gold_auctions[_artwork_name].start_timestamp += gold_auctions[_artwork_name].duration;
    }

    function endGoldRound(string calldata _artwork_name) public
    {
        require(block.timestamp > gold_auctions[_artwork_name].start_timestamp + gold_auctions[_artwork_name].duration, "Auction is still in progress");
        artworks[_artwork_name].num_gold--;

        /*_mintNext(msg.sender);
        _tokenProperties[last_minted_id - 1].properties.push( artworks[_artwork_name].propertyInfo );  
        _tokenProperties[last_minted_id - 1].properties.push( artworks[_artwork_name].propertyOriginalImage );
        */

        _mintNext(gold_auctions[_artwork_name].winner);
        _tokenProperties[last_minted_id - 1].properties.push( artworks[_artwork_name].propertyInfo );  
        _tokenProperties[last_minted_id - 1].properties.push( artworks[_artwork_name].propertyGoldImage );
        _tokenProperties[last_minted_id - 1].properties.push( "Gold" );
        _tokenProperties[last_minted_id - 1].properties.push( toString(artworksMaxCap[_artwork_name].num_gold - artworks[_artwork_name].num_gold) );
        _tokenFeeLevels[last_minted_id - 1] = artworkFeeReceiver[_artwork_name];

        if(artworks[_artwork_name].num_gold != 0)
        {
            startGoldRound(_artwork_name);
        }
    }

/*
    function endGoldRound(string calldata _artwork_name) public
    {
        artworks[_artwork_name].num_gold--;
        _mintNext(msg.sender);
        _tokenProperties[last_minted_id - 1].properties.push( artworks[_artwork_name].propertyInfo );  
        _tokenProperties[last_minted_id - 1].properties.push( artworks[_artwork_name].propertyGoldImage );
        if(artworks[_artwork_name].num_gold != 0)
        {
            startGoldRound(_artwork_name);
        }
    }
    */
    
    modifier checkTrade(uint256 _tokenId)
    {
        _;
        (uint256 _bid, address payable _bidder,) = bidOf(_tokenId);
        if(priceOf(_tokenId) > 0 && priceOf(_tokenId) <= _bid)
        {
            uint256 _reward = _bid - _claimFee(_bid, _tokenId);
            payable(ownerOf(_tokenId)).transfer(_reward);
            delete _bids[_tokenId];
            delete _asks[_tokenId];
            _transfer(ownerOf(_tokenId), _bidder, _tokenId);
            if(address(_bidder).isContract())
            {
                NFTReceiver(_bidder).nftReceived(ownerOf(_tokenId), _tokenId, hex"000000");
            }
        }
    }
    
    function standard() public view virtual override returns (string memory)
    {
        return "NFT X";
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
    
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "NFT: balance query for the zero address");
        return _balances[owner];
    }
    
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "NFT: owner query for nonexistent token");
        return owner;
    }
    
    function setPrice(uint256 _tokenId, uint256 _amountInWEI) checkTrade(_tokenId) public
    {
        require(ownerOf(_tokenId) == msg.sender, "Setting asks is only allowed for owned NFTs!");
        _asks[_tokenId] = _amountInWEI;
    }
    
    function setBid(uint256 _tokenId, bytes calldata _data) payable checkTrade(_tokenId) public virtual override
    {
        (uint256 _previousBid, address payable _previousBidder, ) = bidOf(_tokenId);
        require(ownerOf(_tokenId) != msg.sender, "Can not bid for your own NFT");
        require(msg.value > _previousBid, "New bid must exceed the existing one");
        
        // Return previous bid if the current one exceeds it.
        if(_previousBid != 0)
        {
            _previousBidder.transfer(_previousBid);
        }
        _bids[_tokenId].amountInWEI = msg.value;
        _bids[_tokenId].bidder      = payable(msg.sender);
        _bids[_tokenId].timestamp   = block.timestamp;
    }
    
    function withdrawBid(uint256 _tokenId) public virtual override returns (bool)
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
        _transfer(msg.sender, _to, _tokenId);
        if(_to.isContract())
        {
            NFTReceiver(_to).nftReceived(msg.sender, _tokenId, _data);
        }
        emit TransferData(_data);
        return true;
    }
    
    function silentTransfer(address _to, uint256 _tokenId) public override returns (bool)
    {
        _transfer(msg.sender, _to, _tokenId);
        return true;
    }
    
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }
    
    function _claimFee(uint256 _amountFrom, uint256 _tokenId) internal returns (uint256)
    {
        uint32  _level         = _tokenFeeLevels[_tokenId];
        address _feeReceiver   = feeLevels[_level].feeReceiver;
        uint256 _feePercentage = feeLevels[_level].feePercentage;
        
        uint256 _feeAmount = _amountFrom * _feePercentage / 100000;
        payable(_feeReceiver).transfer(_feeAmount);
        return _feeAmount;        
    }

    function _mintNext(address to) internal 
    {
        _safeMint(to, last_minted_id);
        last_minted_id++;
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
        address owner = NFT.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);
        

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }
    
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(NFT.ownerOf(tokenId) == msg.sender, "NFT: transfer of token that is not own");
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

        emit Transfer(from, to, tokenId);
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual {
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
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
