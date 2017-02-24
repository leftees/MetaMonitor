public class MetadataAsyncService{

/*
    @future(callout=true)
    public static void CheckMetadataAsyncStatus(string metadataBatchId,string SessionId){
        
        list<Metadata_Batch__c> metadataBatchList = [select id,Name,Async_Job_Id__c from Metadata_Batch__c where Id =: metadataBatchId ];
        Metadata_Batch__c currentbatch = metadataBatchList[metadataBatchList .size()-1];
        MetadataService.RetrieveResult retrieveResult;
        
        try{
            if(!test.isRunningTest()){
                retrieveResult = MetadataReferenceUtil.CheckAsyncStatusAndCreateZipFile(currentbatch.Async_Job_Id__c,SessionId );            
            }else{
                retrieveResult = new MetadataService.RetrieveResult();
                retrieveResult.done = true;
                retrieveResult.status = 'Succeeded';
                retrieveResult.zipFile = 'dsadsadsa';
            }
            if(retrieveResult != null){
                if(retrieveResult.done){
                    // Errors?
                    if(retrieveResult.status != 'Succeeded'){
                        currentbatch.Async_Job_Status__c = retrieveResult.status;     
                    }
                    else {
                         currentbatch.Async_Job_Status__c = 'Complete';  
                        // Delete All Parent Attachment Ids
                        list<attachment> atchmtList = [select id from attachment where parentId =: currentbatch.id ];
                        delete atchmtList;
                        // Place Base64 encoded zip data onto the page for the JSZip library to handle
                        attachment atch = new attachment ();
                        atch.Name = currentbatch.name+'.zip';
                        atch.body = EncodingUtil.base64Decode( retrieveResult.zipFile);
                        atch.parentId = currentbatch.Id;
                        insert atch;
                    }
                }
                else{
                    currentbatch.Async_Job_Status__c = 'Pending';  
            }              
        }        
        currentbatch.Check_Async_Status__c = false;
        update currentbatch;
        }catch(exception e){
            MetadataService.AsyncResult AsyncResult = MetadataReferenceUtil.sendRetreiveRequest(currentbatch.Name,SessionId);
            if(AsyncResult != null && AsyncResult.Id != null){
                currentbatch.Async_Job_Id__c = AsyncResult.Id;
                currentbatch.Async_Job_Status__c= 'Pending';
            }else{
                currentbatch.Async_Job_Status__c= 'Not Requested';
            } 
            update currentbatch;
        }
    }

*/
}