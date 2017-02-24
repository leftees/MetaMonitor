@isTest
public class MetaDataRetrieveReqQueueableJobTest{
    
    static testmethod void TestRetreiveMeta(){
    
        Metadata_Batch__c  batch = new Metadata_Batch__c ();
        batch.Name = 'CustomObject';
        batch.Batch_Sequence__c = 5;
        batch.Source__c  = 'Metadata Api';
        insert batch;
        Test.StartTest();
            ID jobID = System.enqueueJob(new MetaDataRetrieveReqQueueableJob(batch));
            Async_Process_Queue__c acync = new Async_Process_Queue__c(Job_Id__c = null ,Metadata_Batch__c = batch.Id, 
                                                            Status__c = 'Queued',Type__c='Retrieve Request');                   
            insert acync;
        Test.StopTest();
    }
    
}