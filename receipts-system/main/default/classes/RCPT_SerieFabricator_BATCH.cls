public with sharing class RCPT_SerieFabricator_BATCH implements Database.Batchable<sObject>, Schedulable, Database.Stateful {
    public Integer insertSize;
    public String nextYear;
    public String thisYear;

    public void execute(SchedulableContext SC) { 
        Database.executeBatch( new RCPT_SerieFabricator_BATCH(), 200 );
    }

    public RCPT_SerieFabricator_BATCH(){
        this.insertSize = 0;
        this.nextYear = String.valueOf(Date.today().year()+1);
        this.thisYear = String.valueOf(Date.today().year());
    }

    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT ID, Prefix__c, Transaction_Type__c, Active__c 
                                        FROM Receipt_Serie__c
                                        WHERE Active__c = true
                                        AND Year__c = :this.thisYear]);
    }
    public void execute(Database.BatchableContext BC, List<Receipt_Serie__c> scope){
        List<Receipt_Serie__c> toInsert = new List<Receipt_Serie__c>();
        try{
            for (Receipt_Serie__c serie : scope) {
                Receipt_Serie__c newSerie = serie.clone(false);
                newSerie.Last_Number__c = 0;
                newSerie.Year__c = this.nextYear;
                toInsert.add(newSerie);
            }
            insert toInsert;
            this.insertSize =+ toInsert.size();
        }
        catch(Exception e){
            new DL_DebugLog_CTRL('Recibos',
                                'RCPT_SerieFabricator_BATCH',
                                'execute', 
                                'catchStatement', 
                                null, 
                                null, 
                                JSON.serializePretty(toInsert), 
                                e.getMessage() + ' ' + e.getStackTraceString(), 
                                null, 
                                false, 
                                false).publish();
        }
    }
    public void finish(Database.BatchableContext BC){
        new DL_DebugLog_CTRL('Recibos',
                                'RCPT_SerieFabricator_BATCH',
                                'finish', 
                                null, 
                                null, 
                                null, 
                                'Inserted ' + this.insertSize + ' new series for the year '+String.valueOf(Date.today().year()+1), 
                                null, 
                                null, 
                                true, 
                                false).publish();
    }
}