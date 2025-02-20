public class RCPT_SetSerieNumber_CTRL {
    
    public Receipt__c[] receipts;
    private Integer retrys;
    
    public RCPT_SetSerieNumber_CTRL( Receipt__c[] receipts, Integer retrys ){
        this.receipts = receipts;
        this.retrys = retrys;        
    }
    
    @InvocableMethod(label='Create Serie Number' description='Process the receipts and set their series numbers')
    public static void invocableProcess(List<Receipt__c> invocableReceiptsList) {
        new RCPT_SetSerieNumber_CTRL(invocableReceiptsList, 3).process();
    }
    
    public void process(){
        Savepoint sp = Database.setSavepoint();
        try{
            System.debug(this.receipts.size());
            Set<String> yearsSet = new Set<String>();
            Set<String> typesSet = new Set<String>();
            for( Receipt__c receipt : this.receipts ){
                yearsSet.add(String.valueOf(receipt.Payment_Date__c.year()));
                typesSet.addAll(receipt.Transaction_Type__c.split(';'));
            }
            Map<Id, Receipt_Serie__c> receiptSeriesList = getReceiptSeriesMap( yearsSet, typesSet );
            Map<String, Id> receiptBridgeMap = getBridgeMap( receiptSeriesList );
            List<SObject> toUpdate = setSerieNumber(this.receipts, receiptSeriesList, receiptBridgeMap);
            if (!toUpdate.isEmpty()) {
                update toUpdate;
            }
        } catch( Exception e ) {
            Database.rollback(sp);
            String exceptionDetails = 'Exception Type: ' + e.getTypeName() + '\n' +
                              'Message: ' + e.getMessage() + '\n' +
                              'Cause: ' + e.getCause() + '\n' +
                              'Line Number: ' + e.getLineNumber() + '\n' +
                              'Stack Trace: ' + e.getStackTraceString() + '\n' +
                              'Retrys: ' + this.retrys;
            new DL_DebugLog_CTRL('Recibos', 'RCPT_SetSerieNumber_CTRL', 'process', 'catchStatement', null, null, JSON.serializePretty(this.receipts), exceptionDetails, null, false, false).publish();
            if(this.retrys > 0){
                retry(this.receipts, this.retrys);
            }
        }
    }
    
    private static List<SObject> setSerieNumber(List<Receipt__c> receipts, Map<Id, Receipt_Serie__c> receiptSeriesList, Map<String, Id> receiptBridgeMap){
        List<SObject> toUpdate = new List<SObject>();
        List<Debug_Log_Event__e> debugLogEvents = new List<Debug_Log_Event__e>();
        for (Receipt__c receipt : receipts) {
            String mapKey = receipt.Transaction_Type__c + String.valueOf(receipt.Payment_Date__c.year());
            if(receiptBridgeMap.containsKey(mapKey)){
                Id key = receiptBridgeMap.get(mapKey);
                Receipt_Serie__c relatedSerie = receiptSeriesList.get(key);
                relatedSerie.Last_Number__c++;
                receiptSeriesList.put(key, relatedSerie);
                receipt.Receipt_Number__c  = relatedSerie.Prefix__c + ' ' + relatedSerie.Last_Number__c + '/' + relatedSerie.Year__c;
                receipt.Status__c = 'Active';
                toUpdate.add(receipt);
            }else{
                throw new DL_DebugLog_Exception('No series found for the given receipt: '+receipt.Id+' with Type: '+receipt.Transaction_Type__c+' and Year: '+receipt.Payment_Date__c.year());
            }
        }
        update receiptSeriesList.values();
        return toUpdate;
    }
    
    private static Map<Id, Receipt_Serie__c> getReceiptSeriesMap(Set<String> yearsSet, Set<String> typesSet){
        String typesString = '(\'' + String.join(typesSet, '\', \'') + '\')';
        String query = 'SELECT Id, Prefix__c, Last_Number__c, Year__c, Transaction_Type__c '+
                        'FROM Receipt_Serie__c '+
                        'WHERE Year__c IN :yearsSet AND Transaction_Type__c INCLUDES ' + typesString;
        List<Receipt_Serie__c> serieList = Database.query(query);
        Map<Id, Receipt_Serie__c> serieMap = new Map<Id, Receipt_Serie__c>();
        for (Receipt_Serie__c serie : serieList) {
            serieMap.put(serie.Id, serie);
        }
        if(serieMap.isEmpty()){
            throw new DL_DebugLog_Exception('No series found for the given years and types');
        }
        return serieMap;
    }
    private static Map<String, Id> getBridgeMap(Map<Id, Receipt_Serie__c> serieMap){
        Map<String, Id> keyBridgeMap = new Map<String, Id>();
        for(Id key : serieMap.keySet()) {
            Receipt_Serie__c serie = serieMap.get(key);
            List<String> types = serie.Transaction_Type__c.split(';');
            for (String variable : types) {
                keyBridgeMap.put(variable + serie.Year__c, key);
            }
        }
        return keyBridgeMap;
    }
    private static void retry(List<Receipt__c> receiptsString, Integer retrys) {
        System.enqueueJob(new RCPT_Retry_QUEUEABLE(receiptsString, retrys), 1);                            
    }
}