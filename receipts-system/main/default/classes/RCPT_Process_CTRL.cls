global class RCPT_Process_CTRL {
    @InvocableMethod(label='Create Receipts' description='Makes the creation of the receipts')
    global static List<RCPT_FlowData_OBJ.RCPT_OutputVariables_OBJ> invocableProcessMethod(List<RCPT_FlowData_OBJ.RCPT_InputVariables_OBJ> inputList) {
        List<RCPT_FlowData_OBJ.RCPT_OutputVariables_OBJ> outputList = new List<RCPT_FlowData_OBJ.RCPT_OutputVariables_OBJ>();
        List<SObject> objectsToUpsert = new List<SObject>();
        try {
            for (RCPT_FlowData_OBJ.RCPT_InputVariables_OBJ data : inputList) {
                    RCPT_ReceiptData_OBJ receiptData = processRequest(data);
                    objectsToUpsert.addAll(receiptData.getObjectsToUpsert());
            }
            if(!objectsToUpsert.isEmpty()){
                Database.UpsertResult[] resultList = Database.upsert(objectsToUpsert);
                outputList.addAll(checkErrors(resultList));
            }
            return outputList;
        }
        catch(Exception e){
            String exceptionDetails = 'Exception Type: ' + e.getTypeName() + '\n' +
                                            'Message: ' + e.getMessage() + '\n' +
                                            'Cause: ' + e.getCause() + '\n' +
                                            'Line Number: ' + e.getLineNumber() + '\n' +
                                            'Stack Trace: ' + e.getStackTraceString();
            System.debug(e.getLineNumber());
            new DL_DebugLog_CTRL('Recibos', 'RCPT_Process_CTRL', 'process', 'ErrorCreatingReceipts', null, null, JSON.serializePretty(inputList), exceptionDetails, null, false, false).publish();
            return null;
        }
    }
    private static RCPT_ReceiptData_OBJ processRequest(RCPT_FlowData_OBJ.RCPT_InputVariables_OBJ data){
        RCPT_ReceiptData_OBJ receiptData;
        switch on data.actionType {
            when 'create' {
                receiptData = createReceipt(data);
            }
            when 'cancel' {
                receiptData = cancelReceipt(data.cancelReceiptId);
            }
            when 'update' {
                receiptData = updateReceipt(data);
            }
            when else {
                throw new DL_DebugLog_Exception('Action not supported');
            }
        }
        return receiptData;
    }
    private static RCPT_ReceiptData_OBJ createReceipt(RCPT_FlowData_OBJ.RCPT_InputVariables_OBJ data) {
        RCPT_ReceiptData_OBJ receiptData = new RCPT_ReceiptData_OBJ(data.transactionSObject);
        return receiptData;
    }
    private static RCPT_ReceiptData_OBJ updateReceipt(RCPT_FlowData_OBJ.RCPT_InputVariables_OBJ data) {
        RCPT_ReceiptData_OBJ receiptData = createReceipt(data);
        receiptData.toCancelReceipt = cancelReceipt(data.cancelReceiptId).toCancelReceipt;
        return receiptData;
    }
    private static RCPT_ReceiptData_OBJ cancelReceipt(String oldId) {
        Receipt__c receipt = new Receipt__c(
                    Id = oldId,
                    Status__c = 'Cancelled'
                );
        RCPT_ReceiptData_OBJ receiptData = new RCPT_ReceiptData_OBJ(null);
        receiptData.toCancelReceipt = receipt;
        return receiptData;
    }
    private static RCPT_FlowData_OBJ.RCPT_OutputVariables_OBJ buildOutput(String receiptId, Boolean success, String errorMessage){
        RCPT_FlowData_OBJ.RCPT_OutputVariables_OBJ output = new RCPT_FlowData_OBJ.RCPT_OutputVariables_OBJ();
        output.returnReceiptId = receiptId;
        output.success = success;
        output.errorMessage = errorMessage;
        return output;
    }
    private static List<RCPT_FlowData_OBJ.RCPT_OutputVariables_OBJ> checkErrors(List<Database.UpsertResult> resultList){
        List<RCPT_FlowData_OBJ.RCPT_OutputVariables_OBJ> outputList = new List<RCPT_FlowData_OBJ.RCPT_OutputVariables_OBJ>();
        for (Database.UpsertResult result : resultList) {
            if(!result.isSuccess()){
                outputList.add(buildOutput(null, false, JSON.serializePretty(result.getErrors())));
            }else{
                outputList.add(buildOutput(result.getId(), true, null));
            }
        }
        return outputList;
    }
}