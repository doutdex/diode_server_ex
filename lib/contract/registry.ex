# Diode Server
# Copyright 2019 IoT Blockchain Technology Corporation LLC (IBTC)
# Licensed under the Diode License, Version 1.0
defmodule Contract.Registry do
  @moduledoc """
    Wrapper for the DiodeRegistry contract functions
    as needed by the inner workings of the chain
  """

  @spec miner_value(0 | 1 | 2 | 3, <<_::160>> | Wallet.t(), any()) :: non_neg_integer
  def miner_value(type, address, blockRef) when type >= 0 and type <= 3 do
    call("MinerValue", ["uint8", "address"], [type, address], blockRef)
    |> :binary.decode_unsigned()
  end

  @spec epoch(any()) :: non_neg_integer
  def epoch(blockRef) do
    call("Epoch", [], [], blockRef)
    |> :binary.decode_unsigned()
  end

  def submit_ticket_raw_tx(ticket) do
    Shell.transaction(Diode.miner(), Diode.registry_address(), "SubmitTicketRaw", ["bytes32[]"], [
      ticket
    ])
  end

  defp call(name, types, values, blockRef) do
    {ret, _gas} = Shell.call(Diode.registry_address(), name, types, values, blockRef: blockRef)
    ret
  end

  # This is the code for the test/dev variant of the registry contract
  # Manually copied from https://diode.io/prenet/#/address/0x5000000000000000000000000000000000000000 on 2nd June 2020,
  # epoch length has been binary edited to 4, at two positions.
  def test_code() do
    "0x6080604052600436106100e25763ffffffff60e060020a6000350416630a938dff81146100e75780630ac168a1146101205780631b3b98c8146101375780631dd44706146101a15780634fb3ccc5146101b6578063534a2422146101e75780636f9874a4146101fb5780637fca4a29146102105780638d23fc61146102315780638da5cb5b1461025257806399ab110d14610267578063acc77cba14610287578063b0128d921461029b578063be3bb93c146102b3578063c487e3f7146102da578063c4a9e116146102e2578063c76a1173146102f7578063cb106cf81461031b575b600080fd5b3480156100f357600080fd5b5061010e60ff60043516600160a060020a0360243516610330565b60408051918252519081900360200190f35b34801561012c57600080fd5b5061013561059d565b005b34801561014357600080fd5b50604080516060818101909252610135916004803592600160a060020a0360243581169360443590911692606435926084359260a4359236929091610124919060c49060039083908390808284375093965061080695505050505050565b3480156101ad57600080fd5b50610135610ae4565b3480156101c257600080fd5b506101cb610cd5565b60408051600160a060020a039092168252519081900360200190f35b610135600160a060020a0360043516610ce4565b34801561020757600080fd5b5061010e610df4565b34801561021c57600080fd5b50610135600160a060020a0360043516610e0e565b34801561023d57600080fd5b506101cb600160a060020a036004351661108f565b34801561025e57600080fd5b506101cb6110aa565b34801561027357600080fd5b5061013560048035602481019101356110b9565b610135600160a060020a0360043516611241565b3480156102a757600080fd5b50610135600435611393565b3480156102bf57600080fd5b5061010e60ff60043516600160a060020a036024351661148a565b61013561149d565b3480156102ee57600080fd5b5061010e6114a9565b34801561030357600080fd5b50610135600160a060020a03600435166024356114af565b34801561032757600080fd5b5061010e6115c0565b600060ff831615156103bb57600160a060020a038216600090815260066020908152604091829020825160a0810184528154818501908152600183015460608084019190915260028401546080840152908252845190810185526003830154815260048301548185015260059092015493820193909352908201526103b4906115c6565b9050610597565b8260ff166001141561043f57600160a060020a038216600090815260066020908152604091829020825160a0810184528154818501908152600183015460608084019190915260028401546080840152908252845190810185526003830154815260048301548185015260059092015493820193909352908201526103b4906115d5565b8260ff16600214156104c357600160a060020a038216600090815260066020908152604091829020825160a0810184528154818501908152600183015460608084019190915260028401546080840152908252845190810185526003830154815260048301548185015260059092015493820193909352908201526103b4906115e4565b8260ff166003141561054757600160a060020a038216600090815260066020908152604091829020825160a0810184528154818501908152600183015460608084019190915260028401546080840152908252845190810185526003830154815260048301548185015260059092015493820193909352908201526103b4906115f3565b6040805160e560020a62461bcd02815260206004820152601260248201527f556e68616e646c656420617267756d656e740000000000000000000000000000604482015290519081900360640190fd5b92915050565b60008080803341148015906105b157504115155b80156105c85750600154600160a060020a03163314155b15610643576040805160e560020a62461bcd02815260206004820152603060248201527f4f6e6c7920746865206d696e6572206f662074686520626c6f636b2063616e2060448201527f63616c6c2074686973206d6574686f6400000000000000000000000000000000606482015290519081900360840190fd5b3341146106c0576040805160e560020a62461bcd02815260206004820152603060248201527f4f6e6c7920746865206d696e6572206f662074686520626c6f636b2063616e2060448201527f63616c6c2074686973206d6574686f6400000000000000000000000000000000606482015290519081900360840190fd5b6106c8610df4565b600754146106d8576106d8611602565b6106fb416106f6670de0b6b3a764000061271063ffffffff61188616565b6118bf565b600093505b6008548410156107f457600880548590811061071857fe5b6000918252602080832090910154600160a060020a031680835260099091526040909120549093506107529061271063ffffffff61198616565b915061075f6000846119a9565b905066038d7ea4c6800081101561077a575066038d7ea4c680005b80821115610786578091505b60008211156107d0576107998383611bbd565b6040518290600160a060020a038516907fc083a1647e3ee591bf42b82564ffb4d16fdbb26068f0080da911c8d8300fd84a90600090a35b600160a060020a038316600090815260096020526040812055600190930192610700565b6108006008600061277c565b50505050565b6060600088438110610862576040805160e560020a62461bcd02815260206004820152601760248201527f5469636b65742066726f6d20746865206675747572653f000000000000000000604482015290519081900360640190fd5b6007546000190161087b8261000463ffffffff61198616565b146108d0576040805160e560020a62461bcd02815260206004820152600b60248201527f57726f6e672065706f6368000000000000000000000000000000000000000000604482015290519081900360640190fd5b8686171515610929576040805160e560020a62461bcd02815260206004820152601460248201527f496e76616c6964207469636b65742076616c7565000000000000000000000000604482015290519081900360640190fd5b60408051600680825260e08201909252906020820160c080388339019050509250894083600081518110151561095b57fe5b602090810290910101528251600160a060020a038a16908490600190811061097f57fe5b602090810290910101528251600160a060020a03891690849060029081106109a357fe5b6020908102909101015282518790849060039081106109be57fe5b6020908102909101015282518690849060049081106109d957fe5b6020908102909101015282518590849060059081106109f457fe5b602090810290910101526001610a0984611c92565b60408087015187516020808a0151845160008082528184018088529790975260ff9094168486015260608401929092526080830191909152915160a080830194601f198301938390039091019190865af1158015610a6b573d6000803e3d6000fd5b505050602060405103519150610a818983611df0565b610a8e8989848a8a611edc565b81600160a060020a031688600160a060020a03168a600160a060020a03167fc21a4132cfb2e72d1dd6f45bcb2dabb1722a19b036c895975db93175b1c5c06f60405160405180910390a450505050505050505050565b336000818152600560208181526040808420815160a081018352815481840190815260018301546060808401919091526002840154608084015290825283519081018452600383015481526004830154818601529482015492850192909252918101929092529190610b55906115f3565b905060008111610baf576040805160e560020a62461bcd02815260206004820152601060248201527f43616e2774207769746864726177203000000000000000000000000000000000604482015290519081900360640190fd5b6040805160a08101825283548183019081526001850154606080840191909152600286015460808401529082528251908101835260038501548152600485015460208281019190915260058601549382019390935291810191909152610c1b908263ffffffff6120ff16565b600160a060020a0384166000818152600560208181526040808420865180518255808401516001830155820151600282015595820151805160038801559182015160048701559081015194909101939093559151909183156108fc02918491818181858888f19350505050158015610c97573d6000803e3d6000fd5b506040518190600160a060020a038516906000907f7f22ec7a37a3fa31352373081b22bb38e1e0abd2a05b181ee7138a360edd3e1a908290a4505050565b600154600160a060020a031681565b6000610cef8261218c565b600160a060020a038116600090815260066020908152604091829020825160a081018452815481850190815260018301546060808401919091526002840154608084015290825284519081018552600383015481526004830154818501526005909201549382019390935290820152909150610d71903463ffffffff61239a16565b600160a060020a038216600081815260066020908152604080832085518051825580840151600180840191909155908301516002830155958301518051600383015592830151600482015591810151600590920191909155513493917fd859864511fd3f512da77fc95a8c013b3a0e49bdface8f574b2df8527cecea7191a45050565b6000610e084361000463ffffffff61198616565b90505b90565b600080600080610e1d8561218c565b935083600160a060020a0316634fb3ccc56040518163ffffffff1660e060020a028152600401602060405180830381600087803b158015610e5d57600080fd5b505af1158015610e71573d6000803e3d6000fd5b505050506040513d6020811015610e8757600080fd5b5051600160a060020a038516600090815260066020908152604091829020825160a08101845281548185019081526001830154606080840191909152600284015460808401529082528451908101855260038301548152600483015481850152600583015494810194909452918201929092529194509250610f08906115f3565b905060008111610f62576040805160e560020a62461bcd02815260206004820152601060248201527f43616e2774207769746864726177203000000000000000000000000000000000604482015290519081900360640190fd5b6040805160a08101825283548183019081526001850154606080840191909152600286015460808401529082528251908101835260038501548152600485015460208281019190915260058601549382019390935291810191909152610fce908263ffffffff6120ff16565b600160a060020a038086166000908152600660209081526040808320855180518255808401516001830155820151600282015594820151805160038701559182015160048601559081015160059094019390935591519085169183156108fc02918491818181858888f1935050505015801561104e573d6000803e3d6000fd5b506040518190600160a060020a038616906001907f7f22ec7a37a3fa31352373081b22bb38e1e0abd2a05b181ee7138a360edd3e1a90600090a45050505050565b600460205260009081526040902054600160a060020a031681565b600054600160a060020a031681565b60006110c361279d565b8215806110d257506009830615155b15611127576040805160e560020a62461bcd02815260206004820152601560248201527f496e76616c6964207469636b6574206c656e6774680000000000000000000000604482015290519081900360640190fd5b600091505b828210156108005760408051606081019091528085856006860181811061114f57fe5b602090810292909201358352500185856007860181811061116c57fe5b602090810292909201358352500185856008860181811061118957fe5b60200291909101359091525090506112368484848181106111a657fe5b602002919091013590506111d28686600187018181106111c257fe5b9050602002013560001916610e0b565b6111e48787600288018181106111c257fe5b8787600388018181106111f357fe5b6020029190910135905088886004890181811061120c57fe5b60200291909101359050898960058a0181811061122557fe5b905060200201356000191687610806565b60098201915061112c565b600154600090600160a060020a0316331461125b57600080fd5b600160a060020a0382811660009081526004602052604090205416156112f1576040805160e560020a62461bcd02815260206004820152602560248201527f44656c656761746520616c726561647920686173206120666c65657420636f6e60448201527f7472616374000000000000000000000000000000000000000000000000000000606482015290519081900360840190fd5b60015430908390600160a060020a03166113096127bc565b600160a060020a03938416815291831660208301529091166040808301919091525190819003606001906000f080158015611348573d6000803e3d6000fd5b50600160a060020a038381166000908152600460205260409020805473ffffffffffffffffffffffffffffffffffffffff1916918316919091179055905061138f81610ce4565b5050565b33600081815260056020818152604092839020835160a0810185528154818601908152600183015460608084019190915260028401546080840152908252855190810186526003830154815260048301548185015291909301549381019390935281019190915261140a908363ffffffff6123bd16565b600160a060020a03821660008181526005602081815260408084208651805182558084015160018301558201516002820155958201518051600388015591820151600487015590810151949091019390935591518492907f81149c79fef0028ec92e02ee17f72b9bba024dce75220cba8d62f7bbcd0922b6908290a45050565b600061149683836119a9565b9392505050565b6114a73334612478565b565b60025481565b60006114ba8361218c565b600160a060020a038116600090815260066020908152604091829020825160a08101845281548185019081526001830154606080840191909152600284015460808401529082528451908101855260038301548152600483015481850152600590920154938201939093529082015290915061153c908363ffffffff6123bd16565b600160a060020a038216600081815260066020908152604080832085518051825580840151600180840191909155908301516002830155958301518051600383015592830151600482015591810151600590920191909155518593917f81149c79fef0028ec92e02ee17f72b9bba024dce75220cba8d62f7bbcd0922b691a4505050565b60035481565b60006105978260000151612578565b6000610597826000015161258f565b6000610597826020015161258f565b60006105978260200151612578565b6000808080808080808080805b600a5489101561186257600a80548a90811061162757fe5b600091825260209091200154600160a060020a03169750611647886125a3565b965061165a87606463ffffffff61198616565b600160a060020a0389166000908152600b602052604090206001810154919b5096506116a3906116929061040063ffffffff61188616565b60028801549063ffffffff61261d16565b9450600093505b600386015484101561181957600386018054859081106116c657fe5b6000918252602080832090910154600160a060020a03168083526004890190915260409091206001810154919c50935061171d9061170c9061040063ffffffff61188616565b60028501549063ffffffff61261d16565b9150611751856117458c6117398661271063ffffffff61188616565b9063ffffffff61188616565b9063ffffffff61198616565b915061175d8b836118bf565b5060005b60038301548110156117ce57826004016000846003018381548110151561178457fe5b6000918252602080832090910154600160a060020a031683528201929092526040018120805460ff1916815560018181018390556002820183905560039091019190915501611761565b600160a060020a038b1660009081526004870160205260408120805460ff1916815560018101829055600281018290559061180c600383018261277c565b50506001909301926116aa565b600160a060020a0388166000908152600b60205260408120805460ff19168155600181018290556002810182905590611855600383018261277c565b505060019098019761160f565b61186e600a600061277c565b611876610df4565b6007555050505050505050505050565b60008083151561189957600091506118b8565b508282028284828115156118a957fe5b04146118b457600080fd5b8091505b5092915050565b600081111561138f57600160a060020a038216600090815260096020526040902054151561194057600880546001810182556000919091527ff3f7a9fe364faab93b216da50a3214154f22a0a2b415b23a84c8169e8b636ee301805473ffffffffffffffffffffffffffffffffffffffff1916600160a060020a0384161790555b600160a060020a038216600090815260096020526040902054611969908263ffffffff61261d16565b600160a060020a0383166000908152600960205260409020555050565b60008080831161199557600080fd5b82848115156119a057fe5b04949350505050565b600060ff83161515611a2e57600160a060020a038216600090815260056020818152604092839020835160a081018552815481860190815260018301546060808401919091526002840154608084015290825285519081018652600383015481526004830154818501529190930154938101939093528101919091526103b4906115c6565b8260ff1660011415611ab357600160a060020a038216600090815260056020818152604092839020835160a081018552815481860190815260018301546060808401919091526002840154608084015290825285519081018652600383015481526004830154818501529190930154938101939093528101919091526103b4906115d5565b8260ff1660021415611b3857600160a060020a038216600090815260056020818152604092839020835160a081018552815481860190815260018301546060808401919091526002840154608084015290825285519081018652600383015481526004830154818501529190930154938101939093528101919091526103b4906115e4565b8260ff166003141561054757600160a060020a038216600090815260056020818152604092839020835160a081018552815481860190815260018301546060808401919091526002840154608084015290825285519081018652600383015481526004830154818501529190930154938101939093528101919091526103b4906115f3565b600160a060020a038216600090815260056020818152604092839020835160a08101855281548186019081526001830154606080840191909152600284015460808401529082528551908101865260038301548152600483015481850152919093015493810193909352810191909152611c3d908263ffffffff61262f16565b600160a060020a03909216600090815260056020818152604092839020855180518255808301516001830155840151600282015594810151805160038701559081015160048601559091015192019190915550565b600080606060008085519350836020026040519080825280601f01601f191660200182016040528015611ccf578160200160208202803883390190505b509250600091505b83821015611d8a575060005b6020811015611d7f578582815181101515611cfa57fe5b9060200190602002015181602081101515611d1157fe5b1a7f01000000000000000000000000000000000000000000000000000000000000000283828460200201815181101515611d4757fe5b9060200101907effffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1916908160001a905350600101611ce3565b600190910190611cd7565b826040518082805190602001908083835b60208310611dba5780518252601f199092019160209182019101611d9b565b5181516020939093036101000a600019018019909116921691909117905260405192018290039091209998505050505050505050565b604080517fd90bd651000000000000000000000000000000000000000000000000000000008152600160a060020a0383811660048301529151849283169163d90bd6519160248083019260209291908290030181600087803b158015611e5557600080fd5b505af1158015611e69573d6000803e3d6000fd5b505050506040513d6020811015611e7f57600080fd5b50511515611ed7576040805160e560020a62461bcd02815260206004820152601360248201527f556e726567697374657265642064657669636500000000000000000000000000604482015290519081900360640190fd5b505050565b600160a060020a0385166000908152600b60205260408120805490919081908190819060ff161515611f6b578454600160ff1990911681178655600a805491820181556000527fc65a7bb8d6351c1cf70c95a316cc6a92839c986682d98bc35f958f4883f9d2a801805473ffffffffffffffffffffffffffffffffffffffff1916600160a060020a038c161790555b600160a060020a03891660009081526004860160205260409020805490945060ff161515611fdd578354600160ff1990911681178555600386018054918201815560009081526020902001805473ffffffffffffffffffffffffffffffffffffffff1916600160a060020a038b161790555b600160a060020a03881660009081526004850160205260409020805490935060ff16151561204f578254600160ff1990911681178455600385018054918201815560009081526020902001805473ffffffffffffffffffffffffffffffffffffffff1916600160a060020a038a161790555b82600201548711156120a157600283018054908890556001850154908803925061207f908363ffffffff61261d16565b60018086019190915585015461209b908363ffffffff61261d16565b60018601555b82600301548611156120f35750600382018054908690556002840154908603906120d1908263ffffffff61261d16565b6002808601919091558501546120ed908263ffffffff61261d16565b60028601555b50505050505050505050565b6121076127cc565b816121158460200151612578565b101561216b576040805160e560020a62461bcd02815260206004820152601660248201527f496e737566666963656e742066726565207374616b6500000000000000000000604482015290519081900360640190fd5b6020830151612180908363ffffffff61265a16565b60208401525090919050565b600160a060020a0380821660009081526004602052604081205490911681811561223d57600154600160a060020a03163314612238576040805160e560020a62461bcd02815260206004820152602660248201527f4f6e6c79207468652063726f6e206163636f756e74616e742063616e2063616c60448201527f6c20746869730000000000000000000000000000000000000000000000000000606482015290519081900360840190fd5b6118b8565b61224f84600160a060020a03166126df565b15156122a5576040805160e560020a62461bcd02815260206004820152601e60248201527f496e76616c696420666c65657420636f6e747261637420616464726573730000604482015290519081900360640190fd5b83915081600160a060020a0316634fb3ccc56040518163ffffffff1660e060020a028152600401602060405180830381600087803b1580156122e657600080fd5b505af11580156122fa573d6000803e3d6000fd5b505050506040513d602081101561231057600080fd5b50519050600160a060020a03811633146118b8576040805160e560020a62461bcd02815260206004820152602560248201527f4f6e6c792074686520666c656574206163636f756e74616e742063616e20646f60448201527f2074686973000000000000000000000000000000000000000000000000000000606482015290519081900360840190fd5b6123a26127cc565b82516123b4908363ffffffff6126e716565b83525090919050565b6123c56127cc565b816123d38460000151612578565b101561244f576040805160e560020a62461bcd02815260206004820152602160248201527f43616e277420756e7374616b65206d6f7265207468616e206973207374616b6560448201527f6400000000000000000000000000000000000000000000000000000000000000606482015290519081900360840190fd5b8251612461908363ffffffff61265a16565b83526020830151612180908363ffffffff6126e716565b600160a060020a038216600090815260056020818152604092839020835160a081018552815481860190815260018301546060808401919091526002840154608084015290825285519081018652600383015481526004830154818501529190930154938101939093528101919091526124f8908263ffffffff61239a16565b600160a060020a03831660008181526005602081815260408084208651805182558084015160018301558201516002820155958201518051600388015591820151600487015590810151949091019390935591518392907fd859864511fd3f512da77fc95a8c013b3a0e49bdface8f574b2df8527cecea71908290a45050565b60006125858260006126e7565b6040015192915050565b600061259c8260006126e7565b5192915050565b600160a060020a0381166000908152600660209081526040808320815160a081018352815481840190815260018301546060808401919091526002840154608084015290825283519081018452600383015481526004830154818601526005909201549282019290925291810191909152610597906115c6565b6000828201838110156118b457600080fd5b6126376127cc565b82516040015161264d908363ffffffff61261d16565b8351604001525090919050565b6126626127f2565b61266d8360006126e7565b9050818160400151101515156126cd576040805160e560020a62461bcd02815260206004820152601b60248201527f496e737566666963656e742066756e647320746f206465647563740000000000604482015290519081900360640190fd5b60408101805192909203909152919050565b6000903b1190565b6126ef6127f2565b6126f88361276b565b15156127345760408051606081018252838152436020820152845185830151919283019161272b9163ffffffff61261d16565b90529050610597565b604080516060810190915283518190612753908563ffffffff61261d16565b81524360208201526040858101519101529050610597565b602001516202ac6043919091031090565b508054600082559060005260206000209081019061279a9190612814565b50565b6060604051908101604052806003906020820280388339509192915050565b6040516103018061283383390190565b60c0604051908101604052806127e06127f2565b81526020016127ed6127f2565b905290565b6060604051908101604052806000815260200160008152602001600081525090565b610e0b91905b8082111561282e576000815560010161281a565b50905600608060405234801561001057600080fd5b5060405160608061030183398101604090815281516020830151919092015160018054600160a060020a03938416600160a060020a03199182161790915560008054948416948216949094179093556002805492909116919092161790556102848061007d6000396000f3006080604052600436106100775763ffffffff7c01000000000000000000000000000000000000000000000000000000006000350416633c5f7d46811461007c5780634ef1aee4146100a45780634fb3ccc5146100df578063504f04b714610110578063570ca7351461013c578063d90bd65114610151575b600080fd5b34801561008857600080fd5b506100a2600160a060020a03600435166024351515610172565b005b3480156100b057600080fd5b506100cb600160a060020a03600435811690602435166101b4565b604080519115158252519081900360200190f35b3480156100eb57600080fd5b506100f46101d4565b60408051600160a060020a039092168252519081900360200190f35b34801561011c57600080fd5b506100a2600160a060020a036004358116906024351660443515156101e3565b34801561014857600080fd5b506100f4610234565b34801561015d57600080fd5b506100cb600160a060020a0360043516610243565b600154600160a060020a0316331461018957600080fd5b600160a060020a03919091166000908152600660205260409020805460ff1916911515919091179055565b600760209081526000928352604080842090915290825290205460ff1681565b600254600160a060020a031681565b600154600160a060020a031633146101fa57600080fd5b600160a060020a03928316600090815260076020908152604080832094909516825292909252919020805460ff1916911515919091179055565b600154600160a060020a031681565b60066020526000908152604090205460ff16815600a165627a7a72305820c30f6f49bb00fa39c472c00d622590b3a0464f9100b4ff9651776f69f0e128b60029a165627a7a7230582010bc9ecc2819d38100ce2dd59be238148f607b6b2e0a4edd24f21f2f575fcc700029"
    |> Base16.decode()
  end
end
