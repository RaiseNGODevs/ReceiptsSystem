public class RCPT_SetSerieNumber_CTRL {

    public List<Receipt__c> receipts;
    public Set<String> yearsSet = new Set<String>();
    Map<Id, Receipt_Serie__c> receiptSeriesMap;
    Map<String, Id> receiptBridgeMap;
    List<Receipt__c> toUpdate = new List<Receipt__c>();
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
            getYearsSet();
            getReceiptSeriesMap();
            getBridgeMap();
            setSerieNumber();
            if (!this.toUpdate.isEmpty()) {
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
                retry();
            }
        }
    }
    private void setSerieNumber(){
        for (Receipt__c receipt : this.receipts) {
            String mapKey = receipt.Transaction_Type__c + String.valueOf(receipt.Payment_Date__c.year());
            if(this.receiptBridgeMap.containsKey(mapKey)){
                Id key = this.receiptBridgeMap.get(mapKey);
                Receipt_Serie__c relatedSerie = this.receiptSeriesMap.get(key);
                relatedSerie.Last_Number__c++;
                this.receiptSeriesMap.put(key, relatedSerie);
                receipt.Receipt_Number__c  = relatedSerie.Prefix__c + ' ' + relatedSerie.Last_Number__c + '/' + relatedSerie.Year__c;
                receipt.Status__c = 'Active';
                this.toUpdate.add(receipt);
            }else{
                throw new DL_DebugLog_Exception('No series found for the given receipt: '+receipt.Id+' with Type: '+receipt.Transaction_Type__c+' and Year: '+receipt.Payment_Date__c.year());
            }
        }
        update this.receiptSeriesMap.values();
    }
    private void getReceiptSeriesMap(){
        this.receiptSeriesMap = new Map<Id, Receipt_Serie__c>([
                                                                    SELECT Id, Prefix__c, Last_Number__c, Year__c, Transaction_Type__c
                                                                    FROM Receipt_Serie__c
                                                                    WHERE Active__c = true AND Year__c IN :this.yearsSet
                                                                ]);
        if(this.receiptSeriesMap.isEmpty()){
            throw new DL_DebugLog_Exception('No series found for the given years');
        }
    }
    private void getBridgeMap(){
        this.receiptBridgeMap = new Map<String, Id>();
        for(Id key : receiptSeriesMap.keySet()) {
            Receipt_Serie__c serie = this.receiptSeriesMap.get(key);
            List<String> types = serie.Transaction_Type__c.split(';');
            for (String variable : types) {
                receiptBridgeMap.put(variable + serie.Year__c, key);
            }
        }
    }
    private void getYearsSet(){
        for(Receipt__c receipt : this.receipts){
            this.yearsSet.add(String.valueOf(receipt.Payment_Date__c.year()));
        }
    }
    private void retry() {
        System.enqueueJob(new RCPT_Retry_QUEUEABLE(this.receipts, this.retrys), 1);                            
    }
}