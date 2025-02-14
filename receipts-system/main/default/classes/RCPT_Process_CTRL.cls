global class RCPT_Process_CTRL {
    @InvocableMethod(label='Create Receipts' description='Makes the creation of the receipts')
    global static List<RCPT_FlowData_OBJ.RCPT_OutputVariables_OBJ> generateFirstReceipts(List<RCPT_FlowData_OBJ.RCPT_InputVariables_OBJ> flowList) {
            List<RCPT_FlowData_OBJ.RCPT_OutputVariables_OBJ> outputList = new List<RCPT_FlowData_OBJ.RCPT_OutputVariables_OBJ>();
            for (RCPT_FlowData_OBJ.RCPT_InputVariables_OBJ flowData : flowList) {
                try{
                RCPT_ReceiptData_OBJ receiptData = new RCPT_ReceiptData_OBJ(flowData.transactionSObject, flowData.cancelReceiptId, flowData.actionType);
                receiptData = RCPT_Process_CTRL.processReceipt(receiptData);
                outputList.add(buildOutput(receiptData.receiptObject.Id, true, null));
                }
                catch(Exception e){
                    String exceptionDetails = 'Exception Type: ' + e.getTypeName() + '\n' +
                                                'Message: ' + e.getMessage() + '\n' +
                                                'Cause: ' + e.getCause() + '\n' +
                                                'Line Number: ' + e.getLineNumber() + '\n' +
                                                'Stack Trace: ' + e.getStackTraceString();
                    outputList.add(buildOutput(null, false, exceptionDetails));
                } 
            }
            return outputList;
    }
    
    public static RCPT_ReceiptData_OBJ processReceipt(RCPT_ReceiptData_OBJ receiptData) {
        switch on receiptData.action {
            when 'create' {
                receiptData = createReceipt(receiptData);
            }
            when 'cancel' {
                receiptData = cancelReceipt(receiptData);
            }
            when 'update' {
                receiptData = updateReceipt(receiptData);
            }
            when else {
                throw new DL_DebugLog_Exception('Action not supported');
            }
        }
        return receiptData;
    }
    private static RCPT_ReceiptData_OBJ createReceipt(RCPT_ReceiptData_OBJ receiptData) {
        Database.SaveResult result = Database.insert(receiptData.receiptObject);
        checkErrors(result);
        return receiptData;
    }
    private static RCPT_ReceiptData_OBJ updateReceipt(RCPT_ReceiptData_OBJ receiptData) {
        cancelReceipt(receiptData);
        receiptData = createReceipt(receiptData);
        return receiptData;
    }
    private static RCPT_ReceiptData_OBJ cancelReceipt(RCPT_ReceiptData_OBJ receiptData) {
        Receipt__c oldReceipt = new Receipt__c(
                    Id = receiptData.oldReceipt,
                    Status__c = 'Cancelled'
                );
        Database.SaveResult result = Database.update(oldReceipt);
        checkErrors(result);
        return receiptData;
    }
    private static RCPT_FlowData_OBJ.RCPT_OutputVariables_OBJ buildOutput(String receiptId, Boolean success, String errorMessage){
        RCPT_FlowData_OBJ.RCPT_OutputVariables_OBJ output = new RCPT_FlowData_OBJ.RCPT_OutputVariables_OBJ();
        output.returnReceiptId = receiptId;
        output.success = success;
        output.errorMessage = errorMessage;
        return output;
    }
    private static void checkErrors(Database.SaveResult result){
        if(!result.isSuccess()){
            for(Database.Error error : result.getErrors()){
                throw new DL_DebugLog_Exception('Error Inserting the Account'+error);
            }
        }
    }
}