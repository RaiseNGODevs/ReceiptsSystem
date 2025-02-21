public with sharing class RCPT_ReceiptData_OBJ {
    public Receipt__c receiptObject     {get;set;}
    public Receipt__c toCancelReceipt   {get;set;}

    public RCPT_ReceiptData_OBJ(SObject inputObject) {
        this.receiptObject = buildReceipt(inputObject);
    }
    private static Receipt__c buildReceipt(SObject inputObject){
        Map<String, Receipts_System_Mapping__mdt> customMetadataRecords = Receipts_System_Mapping__mdt.getAll();
        Receipt__c receiptObject = new Receipt__c();
        receiptObject.Status__c = 'Pending';
        receiptObject.Encrypted_Id__c = setEncryptedId();
        if(inputObject == null){
            return receiptObject;
        }
        for (Receipts_System_Mapping__mdt metadata : customMetadataRecords.values()) {
            if(metadata != null && inputObject.get(metadata.Source_Field__c) != null){
                receiptObject.put(metadata.Destiny_Field__c, inputObject.get(metadata.Source_Field__c));
            }
        }
        return receiptObject;
    }
    private static String setEncryptedId(){
        UUID randomUUID = UUID.randomUUID();
        return randomUUID.toString();
    }
    public List<SObject> getObjectsToUpsert(){
        List<SObject> objectsToInsert = new List<SObject>();
        objectsToInsert.add(this.receiptObject);
        if(this.toCancelReceipt != null){
            objectsToInsert.add(this.toCancelReceipt);
        }
        return objectsToInsert;
    }
}