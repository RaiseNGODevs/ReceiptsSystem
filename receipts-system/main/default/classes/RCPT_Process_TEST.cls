@isTest
public with sharing class RCPT_Process_TEST {
    @TestSetup
    static void makeData(){
        Receipt_Serie__c serie = new Receipt_Serie__c();
        serie.Prefix__c = 'TT';
        serie.Last_Number__c = 0;
        serie.Year__c = String.valueOf(Date.today().year());
        serie.Transaction_Type__c = 'Individual';
        serie.Active__c = true;
        insert serie;
    }
    @isTest 
    public static void createReceiptFlow() {
        SObject obj ;
        RCPT_FlowData_OBJ.RCPT_InputVariables_OBJ input = new RCPT_FlowData_OBJ.RCPT_InputVariables_OBJ();
        input.transactionSObject = obj;
        input.cancelReceiptId = null;
        input.actionType = 'create';
        List<RCPT_FlowData_OBJ.RCPT_InputVariables_OBJ> flowList = new List<RCPT_FlowData_OBJ.RCPT_InputVariables_OBJ>{input};
        Test.startTest();
            List<RCPT_FlowData_OBJ.RCPT_OutputVariables_OBJ> output = RCPT_Process_CTRL.invocableProcessMethod(flowList);
        Test.stopTest();
        List<Receipt__c> updatedReceipts = [SELECT Id, Receipt_Number__c, Status__c FROM Receipt__c];
        Assert.areEqual(1, updatedReceipts.size(), 'Should have created Receipt');
    }
    @isTest 
    public static void cancelReceiptFlow() {
        Receipt__c receipt = new Receipt__c();
        receipt.Status__c = 'Active';
        receipt.Encrypted_Id__c = '123';
        receipt.Name__c = 'Test';
        receipt.Original_Amount__c = 25;
        receipt.Transaction_Type__c = 'Individual';
        receipt.Payment_Date__c = Date.today();
        insert receipt;
        RCPT_FlowData_OBJ.RCPT_InputVariables_OBJ input = new RCPT_FlowData_OBJ.RCPT_InputVariables_OBJ();
        input.transactionSObject = null;
        input.cancelReceiptId = receipt.Id;
        input.actionType = 'cancel';
        List<RCPT_FlowData_OBJ.RCPT_InputVariables_OBJ> flowList = new List<RCPT_FlowData_OBJ.RCPT_InputVariables_OBJ>{input};
        Test.startTest();
            List<RCPT_FlowData_OBJ.RCPT_OutputVariables_OBJ> output = RCPT_Process_CTRL.invocableProcessMethod(flowList);
        Test.stopTest();
        List<Receipt__c> updatedReceipts = [SELECT Id, Receipt_Number__c, Status__c FROM Receipt__c];
        Assert.areEqual('Cancelled', updatedReceipts[0].Status__c, 'Should have cancelled Receipt');
    }
    @isTest 
    public static void updateReceipt() {
        Receipt__c receipt = new Receipt__c();
        receipt.Status__c = 'Active';
        receipt.Encrypted_Id__c = '123';
        receipt.Name__c = 'Test';
        receipt.Original_Amount__c = 25;
        receipt.Transaction_Type__c = 'Individual';
        receipt.Payment_Date__c = Date.today();
        insert receipt;
        SObject obj;
        RCPT_FlowData_OBJ.RCPT_InputVariables_OBJ input = new RCPT_FlowData_OBJ.RCPT_InputVariables_OBJ();
        input.transactionSObject = obj;
        input.cancelReceiptId = receipt.Id;
        input.actionType = 'update';
        List<RCPT_FlowData_OBJ.RCPT_InputVariables_OBJ> flowList = new List<RCPT_FlowData_OBJ.RCPT_InputVariables_OBJ>{input};
        Test.startTest();
            List<RCPT_FlowData_OBJ.RCPT_OutputVariables_OBJ> output = RCPT_Process_CTRL.invocableProcessMethod(flowList);
        Test.stopTest();
        List<Receipt__c> canceledReceipts = [SELECT Id, Receipt_Number__c, Status__c FROM Receipt__c Where Id = :receipt.Id];
        Assert.areEqual('Cancelled', canceledReceipts[0].Status__c, 'Should have cancelled first Receipt');
        List<Receipt__c> updatedReceipts = [SELECT Id, Receipt_Number__c, Status__c FROM Receipt__c Where Id != :receipt.Id];
        Assert.areEqual(1, updatedReceipts.size(), 'Should have created new Receipt');
    }
    @isTest 
    public static void ErrorReceiptFlow() {
        SObject obj ;
        RCPT_FlowData_OBJ.RCPT_InputVariables_OBJ input = new RCPT_FlowData_OBJ.RCPT_InputVariables_OBJ();
        input.transactionSObject = obj;
        input.cancelReceiptId = null;
        input.actionType = 'noSupport';
        List<RCPT_FlowData_OBJ.RCPT_InputVariables_OBJ> flowList = new List<RCPT_FlowData_OBJ.RCPT_InputVariables_OBJ>{input};
        Test.startTest();
            List<RCPT_FlowData_OBJ.RCPT_OutputVariables_OBJ> output = RCPT_Process_CTRL.invocableProcessMethod(flowList);
        Test.stopTest();
        List<Debug_Log__c> log = [SELECT Id, Error_Message__c, Success__c FROM Debug_Log__c WHERE Source__c = 'Recibos'];
        Assert.areEqual(1, log.size(), 'Should have created Error Log');
        Assert.isNotNull(log[0].Error_Message__c, 'Should have Error Message');
        Assert.isFalse(log[0].Success__c, 'Should have failed');
    }
    @isTest 
    public static void testReceiptSerieSuccess() {
        Receipt__c receipt = new Receipt__c();
        receipt.Status__c = 'Pending';
        receipt.Encrypted_Id__c = '123';
        receipt.Name__c = 'Test';
        receipt.Original_Amount__c = 25;
        receipt.Transaction_Type__c = 'Individual';
        receipt.Payment_Date__c = Date.today();
        insert receipt;
        Test.startTest();
            RCPT_SetSerieNumber_CTRL.invocableProcess(new List<Receipt__c>{receipt});
        Test.stopTest();
        List<Receipt__c> updatedReceipts = [SELECT Id, Receipt_Number__c, Status__c FROM Receipt__c WHERE Id = :receipt.Id];
        Assert.isNotNull(updatedReceipts[0].Receipt_Number__c, 'Should have updated Receipt Number');
    }
    @isTest 
    public static void testReceiptSerieFailure() {
        Receipt__c receipt = new Receipt__c();
        receipt.Status__c = 'Pending';
        receipt.Encrypted_Id__c = '123';
        receipt.Name__c = 'Test';
        receipt.Original_Amount__c = 25;
        receipt.Transaction_Type__c = 'Individual';
        receipt.Payment_Date__c = Date.newInstance(2024, 1, 1);
        insert receipt;
        Test.startTest();
            new RCPT_SetSerieNumber_CTRL(new List<Receipt__c>{receipt}, 1).process();
        Test.stopTest();
        List<Debug_Log__c> log = [SELECT Id, Error_Message__c FROM Debug_Log__c WHERE Source__c = 'Recibos'];
        Assert.areEqual(2, log.size(), 'Should have created 2 error Logs, one for the first another for the retry');
    }
}