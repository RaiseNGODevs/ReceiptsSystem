public class RCPT_ReceiptPDF_CTRL {
    
    public Receipt__c receipt 	{get;set;}
 
    public RCPT_ReceiptPDF_CTRL(){
        try {
            String receiptId = ApexPages.currentPage().getParameters().get('id');
            if( String.isBlank(receiptId) ){
                System.debug(LoggingLevel.ERROR, 'Invalid Object ID');
            } else {
                this.receipt = [SELECT ID, Encrypted_Id__c, Transaction_Type__c, Status__c, Original_Amount__c, Name__c, Email__c, Payment_Date__c, Receipt_Number__c
                                FROM Receipt__c 
                                WHERE Encrypted_Id__c =: receiptId 
                                LIMIT 1];
            }
        }catch (Exception e) {
            System.debug(e.getCause() + ' ' + e.getLineNumber() + ' ' + e.getMessage() + ' ' + e.getStackTraceString());
        }
    }
}