import 'constants.dart';
import 'package:flutter/services.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

Future<DeployedContract> loadContract() async {
  String abi = await rootBundle.loadString('assets/abi.json');
  String contractAddress = contractAddress1;
  final contract = DeployedContract(ContractAbi.fromJson(abi, 'Verify'),
      EthereumAddress.fromHex(contractAddress));
  return contract;
}

Future<String> callFunction(String funcname, List<dynamic> args,
    Web3Client ethClient, String privateKey) async {
  EthPrivateKey credentials = EthPrivateKey.fromHex(privateKey);
  String privateKeyHex = bytesToHex(credentials.privateKey, include0x: true);
  print(privateKeyHex);
  EthereumAddress ownerAddress = await credentials.address;
  print(ownerAddress);
  EtherAmount balance = await ethClient.getBalance(ownerAddress);
  print("Balance: ${balance.getValueInUnit(EtherUnit.ether)}");
  DeployedContract contract = await loadContract();
  final ethFunction = contract.function(funcname);
  final result = await ethClient.sendTransaction(
      credentials,
      Transaction.callContract(
          contract: contract, function: ethFunction, parameters: args),
      chainId: 31337,
      fetchChainIdFromNetworkId: false);
  return result;
}

Future<String> registerUser(
    String userID, String cid, Web3Client ethClient) async {
  var response = await callFunction(
      'registerUser', [userID, cid], ethClient, owner_private_key);
  print('User registered successfully');
  return response;
}

Future<String> verifyUser(String userID, Web3Client ethClient) async {
  var response =
      await callFunction('verifyUser', [userID], ethClient, owner_private_key);
  print('User verified successfully');
  return response;
}

Future<List<dynamic>> getUserInfo(String userID, Web3Client ethClient) async {
  // Load the contract
  DeployedContract contract = await loadContract();

  // Define the function
  final ethFunction = contract.function('getUserInfo');

  // Call the function and get the result
  final result = await ethClient.call(
    contract: contract,
    function: ethFunction,
    params: [userID],
  );

  // Result is a List<dynamic> containing the values returned by getUserInfo
  return result;
}