global class RCPT_FlowData_OBJ { 
    global class RCPT_InputVariables_OBJ{
        @InvocableVariable(label = 'Action Type')
        global String actionType;
        @InvocableVariable(label = 'Transaction SObject') 
        global SObject transactionSObject;  
        @InvocableVariable(label = 'To Cancel Receipt Id') 
        global String cancelReceiptId;  
    }
    global class RCPT_OutputVariables_OBJ{  
        @InvocableVariable(label = 'Created Receipt Id') 
        global String returnReceiptId;
        @InvocableVariable(label = 'Success') 
        global Boolean success;
        @InvocableVariable(label = 'Error Message') 
        global String errorMessage;
    }
}