@isTest
public class ScheduledMetadataRetrieveReqTest{
    
    static testmethod void TestRetreiveMeta(){
    
        Metadata_Batch__c  batch = new Metadata_Batch__c ();
        batch.Name = 'CustomObject';
        batch.Batch_Sequence__c = 5;
        batch.Source__c  = 'Metadata Api';
        insert batch;
        Test.StartTest();
        String sch1 = '0 0 * * * ?';
        scheduledMetadataRetrieveReq sqrb1 = new scheduledMetadataRetrieveReq();
        system.schedule('Test Scheiduler Every Hour plus 0 min', sch1, sqrb1);
        Test.StopTest();
    }
    
}