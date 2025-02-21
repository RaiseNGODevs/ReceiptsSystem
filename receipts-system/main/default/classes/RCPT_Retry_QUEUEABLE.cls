public with sharing class RCPT_Retry_QUEUEABLE implements Queueable {
    private List<Receipt__c> receipts;

    private Integer retrys;

    public RCPT_Retry_QUEUEABLE( List<Receipt__c> receipts, Integer retrys){
        this.receipts = receipts;
        this.retrys = retrys;
    }
    
    public void execute(QueueableContext context) {
        new RCPT_SetSerieNumber_CTRL(this.receipts, this.retrys-1).process();        
    }
}