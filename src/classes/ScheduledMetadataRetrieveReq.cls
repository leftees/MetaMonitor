global class ScheduledMetadataRetrieveReq implements Schedulable {

    global void execute(SchedulableContext sc) {        
        string METADATA_TYPE = 'Metadata Api';
        String Query = 'select id,Name,Data_Field_API_Name__c,Source__c,query__c,Batch_Sequence__c from Metadata_Batch__c where Source__c =: METADATA_TYPE';          
        string SESSION_ID;
        list<Metadata_Batch__c> metadataBatches = database.query(Query);
        list<Async_Process_Queue__c> asyncQueueList = new list<Async_Process_Queue__c>();
        for(Metadata_Batch__c currentBatch : metadataBatches ){
                ID jobID = System.enqueueJob(new MetaDataRetrieveReqQueueableJob(currentBatch));
                asyncQueueList.add(new Async_Process_Queue__c(Job_Id__c = jobID ,Metadata_Batch__c = currentBatch.Id, 
                                                                Status__c = 'Queued',Type__c='Retrieve Request'));                
        } 
        
        if(asyncQueueList.size() > 0 ){
            insert asyncQueueList;
        }                
    }
   
}