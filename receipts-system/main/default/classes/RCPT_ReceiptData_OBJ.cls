public with sharing class RCPT_ReceiptData_OBJ {
    public Receipt__c receiptObject    {get;set;}
    public String action               {get;set;}
    public String oldReceipt           {get;set;}

    public RCPT_ReceiptData_OBJ(SObject inputObject, String oldReceipt, String action) {
        this.receiptObject = buildReceipt(inputObject);//inputObject != null ? buildReceipt(inputObject) : null;
        this.action = action;
        this.oldReceipt = oldReceipt;
    }
    private static Receipt__c buildReceipt(SObject inputObject){
        Map<String, Receipts_System_Mapping__mdt> customMetadataRecords = Receipts_System_Mapping__mdt.getAll();
        Receipt__c receiptObject = new Receipt__c();
        receiptObject.Status__c = 'Pending';
        receiptObject.Encrypted_Id__c = setEncryptedId();
        if(inputObject==null){
            return receiptObject;
        }
        for (Receipts_System_Mapping__mdt metadata : customMetadataRecords.values()) {
            if(inputObject.get(metadata.Source_Field__c) != null){
                    receiptObject.put(metadata.Destiny_Field__c, inputObject.get(metadata.Source_Field__c));
            }
        }
        return receiptObject;
    }
    private static String setEncryptedId(){
        UUID randomUUID = UUID.randomUUID();
        return randomUUID.toString();
    }
}