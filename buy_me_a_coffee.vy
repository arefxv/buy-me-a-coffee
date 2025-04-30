# pragma version 0.4.1
"""
@license MIT 
@title Buy Me A Coffee
@author ArefXV
"""

interface AggregatorV3Interface:
    def decimals() -> uint8: view
    def description() -> String[1000]: view
    def version() -> uint256: view
    def latestAnswer() -> int256: view

MINIMUM_USD: constant(uint256) = as_wei_value(5, "ether")
PRICE_FEED: immutable(AggregatorV3Interface)
OWNER: immutable(address)
PRECISION: constant(uint256) = (1 * (10 ** 18))


funders: public(DynArray[address, 1000])
funder_to_amount_funded: public(HashMap[address, uint256])

@deploy
def __init__(price_feed_address: address):
    PRICE_FEED = AggregatorV3Interface(price_feed_address)
    OWNER = msg.sender

@external 
@payable 
def fund():
    self._fund()

@external 
@payable
def __default__():
    self._fund()


@payable
def _fund():

    usd_value_of_eth: uint256 = self._get_eth_to_usd_rate(msg.value)
    assert usd_value_of_eth >= MINIMUM_USD, "You Must Send More Than $5"
    self.funders.append(msg.sender)
    self.funder_to_amount_funded[msg.sender] += msg.value

@external  
def withdraw():
    assert msg.sender == OWNER, "Not The Contract Owner!"
    #send(OWNER, self.balance)
    raw_call(OWNER, b"", value = self.balance)

    for funders: address in self.funders:
        self.funder_to_amount_funded[funders] = 0
    self.funders = []

@external 
@view 
def get_minimum_usd() -> uint256:
    return MINIMUM_USD

@view
def _get_eth_to_usd_rate(eth_amount: uint256) -> uint256:
    price: int256 = staticcall PRICE_FEED.latestAnswer()
    eth_price: uint256 = convert(price, uint256) * (10 ** 10)

    eth_amount_in_usd: uint256 = (eth_amount * eth_price) // PRECISION
    return eth_amount_in_usd

@external 
@view 
def get_eth_to_usd_rate(eth_amount: uint256) -> uint256:
    return self._get_eth_to_usd_rate(eth_amount)

@external 
@view 
def get_owner() -> address:
    return OWNER

@external 
@view 
def get_eth_price() -> int256:
    return staticcall PRICE_FEED.latestAnswer()
    