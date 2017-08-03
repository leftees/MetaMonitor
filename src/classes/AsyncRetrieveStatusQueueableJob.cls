public class AsyncRetrieveStatusQueueableJob implements Queueable, Database.AllowsCallouts {
    
    public Metadata_Batch__c  currentBatch;
    public MetadataService.RetrieveResult retrieveResult;
    public string SESSION_ID ;
    public list<Async_Process_Queue__c> asyncQueueList = new list<Async_Process_Queue__c>();
    
    public AsyncRetrieveStatusQueueableJob(Metadata_Batch__c  currentBatch){    
        this.currentBatch = currentBatch ;
    }
    
    public void execute(QueueableContext context) {
		//TODO : TEST CODE SCAN
        string currentJobId ;
        if(!test.isRunningTest()){
            currentJobId = context.getJobId();
        } 

        //gets the created Async_Process_Queue__c record 
        List<Async_Process_Queue__c>  asyncQueueRecList = [Select Id,Async_Request_Id__c, Status__c, Start_Time__c , Type__c , Metadata_Batch__c ,
                                     Job_Id__c  From Async_Process_Queue__c  Where Job_Id__c  = : currentJobId ];     
        
        Async_Process_Queue__c  asyncQueueRec = new   Async_Process_Queue__c();     
        if(asyncQueueRecList != null && asyncQueueRecList.size() > 0){
            asyncQueueRec = asyncQueueRecList[asyncQueueRecList.size()-1];                                            
            try{
                HttpRequest getSessionReq = new HttpRequest();
                //TODO: Put the string in Label                 
                getSessionReq.setEndpoint('callout:MetaCheck/services/apexrest/CompDepSrchDev/UserInfoSessionInfo');
                getSessionReq.setMethod('GET');
                Http http = new Http();
                HTTPResponse getSessionRes = http.send(getSessionReq);        
                SESSION_ID = getSessionRes.getbody();        
                if(SESSION_ID != null){
                    SESSION_ID = SESSION_ID.replace('"','');            
                    system.debug('&***********'+SESSION_ID); 
                    retrieveResult = MetadataReferenceUtil.CheckAsyncStatusAndCreateZipFile(asyncQueueRec.Async_Request_Id__c,SESSION_ID);
                    //if(retrieveResult != null){
                        if(retrieveResult != null && retrieveResult.done){
                            // Errors?
                            if(retrieveResult.status != 'Succeeded'){
                                // TODO Update Parent Record   
                                asyncQueueRec.status__c = 'Failed';
                                asyncQueueRec.Failed_Reason__c=retrieveResult.status+' Unknown error occured again retried with New Request';                    
                                ID jobID = System.enqueueJob(new MetaDataRetrieveReqQueueableJob(currentBatch));
                                asyncQueueList.add(new Async_Process_Queue__c(Job_Id__c = jobID ,Metadata_Batch__c = currentBatch.Id, 
                                                                        Status__c = 'Queued',Type__c='Retrieve Request'));                               
                            }
                            else {
                                currentbatch.Last_Refresh_Date__c = system.now();
                                asyncQueueRec.status__c = 'Complete';  
                                // Delete All Parent Attachment Ids
                                list<attachment> atchmtList = [select id from attachment where parentId =: currentbatch.id ];
                                delete atchmtList;
                                // Place Base64 encoded zip data 
                                attachment atch = new attachment ();
                                atch.Name = currentbatch.name+'.zip';
                                atch.body = EncodingUtil.base64Decode( retrieveResult.zipFile);
                                atch.parentId = currentbatch.Id;
                                insert atch;
                            }
                        }
                        else{
                            asyncQueueRec.status__c = 'Retry';
                            asyncQueueRec.Failed_Reason__c='Status Not Completed Retrying Again';
                            ID jobID = System.enqueueJob(new AsyncRetrieveStatusQueueableJob(currentBatch));
                            asyncQueueList.add(new Async_Process_Queue__c(Job_Id__c = jobID ,Async_Request_Id__c= asyncQueueRec.Async_Request_Id__c, 
                                                                            Metadata_Batch__c = currentBatch.Id, Status__c = 'Queued',Type__c='Check Async Status'));  
                        }              
                    }
                            
                //}
            }Catch(exception e){
                if(!test.isRunningTest()){
                    asyncQueueRec.status__c = 'Failed';
                    asyncQueueRec.Failed_Reason__c=e.getStackTraceString().replace('\n',' / ')+' - '+e.getMessage();
                    ID jobID = System.enqueueJob(new MetaDataRetrieveReqQueueableJob(currentBatch));
                    asyncQueueList.add(new Async_Process_Queue__c(Job_Id__c = jobID , Metadata_Batch__c = currentBatch.Id, Status__c = 'Queued',Type__c='Retrieve Request'));        
                }
            }   
            
            if(asyncQueueList.size()>0){
                insert asyncQueueList;
            }   
            update currentbatch;      
            update asyncQueueRec;
        }
    }
}