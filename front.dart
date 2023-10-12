/// APPROVAL MCT METHOD

Future<bool> getMCTApproval({
  required double price,
  required String address,
}) async {
  Debug.printLog("price", BigInt.from((price) * pow(10, 18)).toString());
  String? transactionId;
  try {
    Transaction transaction = Transaction.callContract(
      from: EthereumAddress.fromHex(uData.walletAddress ?? ""),
      contract: contractService.mctContract,
      function:
          contractService.mctContract.function(ContractFunctionsName.approve),
      parameters: [
        EthereumAddress.fromHex(address),
        BigInt.from((price) * pow(10, 18))
      ],
    );

    EthereumTransaction ethereumTransaction = EthereumTransaction(
      from: uData.walletAddress ?? "",
      to: ContractAddressConstant.mctAddress,
      data: hex.encode(List<int>.from(transaction.data!)),
    );

    await _initGoToWallet();

    transactionId = await MyApp.walletConnectHelper.web3App?.request(
      topic: MyApp.walletConnectHelper.sessionData?.topic ?? "",
      chainId: MyApp.walletConnectHelper.chain.chainId,
      request: SessionRequestParams(
        method: EIP155.methods[EIP155Methods.ethSendTransaction] ?? "",
        params: [ethereumTransaction.toJson()],
      ),
    );

    Debug.printLog("TRANSACTION ID", transactionId.toString());
  } on Exception catch (_, e) {
    e.printError();
    Debug.printLog("Catch E", e.toString());
  }
  bool isApproved = transactionId != null;

  return isApproved;
}

/// TRANSFER MCT CONTRACT CALL METHOD

Future<String?> transferMCTTokens({
  required String amount,
  required String status,
  required String context,
  bool? isLevelUp,
}) async {
  amount = amount.trim();

  var parameters = [
    ///receiver_
    EthereumAddress.fromHex(
        ContractAddressConstant.clientAddressForMagicDrinksAndOthers),

    ///amount_
    BigInt.from(double.parse(amount) * pow(10, 18)),

    ///status_
    status,

    ///context_
    context,
  ];

  Debug.printLog("transferMCTTokens PARAMS", parameters.toString());

  Transaction transaction = Transaction.callContract(
    from: EthereumAddress.fromHex(uData.walletAddress ?? ""),
    contract: contractService.transferMCTManuallyContract,
    function: contractService.transferMCTManuallyContract
        .function(ContractFunctionsName.transferMCT),
    parameters: parameters,
  );

  EthereumTransaction ethereumTransaction = EthereumTransaction(
    from: uData.walletAddress ?? "",
    to: transaction.to?.hex ?? "",
    data: hex.encode(List<int>.from(transaction.data!)),
  );

  try {
    await _initGoToWallet();

    String transactionId = await MyApp.walletConnectHelper.web3App?.request(
      topic: MyApp.walletConnectHelper.sessionData?.topic ?? "",
      chainId: MyApp.walletConnectHelper.chain.chainId,
      request: SessionRequestParams(
        method: EIP155.methods[EIP155Methods.ethSendTransaction] ?? "",
        params: [ethereumTransaction.toJson()],
      ),
    );

    Debug.printLog("TRANSACTION ID", transactionId.toString());
    return transactionId;
  } catch (ex) {
    if (isLevelUp != null) {
      if (isLevelUp) {
        Get.find<SneakersDetailsController>().isShowLoading(false);
      } else {
        closeMainLoaderProgress();
      }

      CloudFirestoreHelper.database
          .errorLog(message: ex.toString(), isLevelUp: isLevelUp);
    }
    Debug.printLog("Transfer Error", ex.toString());
    Utils.showToast(Get.context!, ex.toString());
  }
  return null;
}
