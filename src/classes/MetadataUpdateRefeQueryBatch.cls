global class MetadataUpdateRefeQueryBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts{

   global final String Query;
   global integer ReferenceBatchNo;
   global string componentType;
   global string markUpField;
  
   global MetadataUpdateRefeQueryBatch(integer refbatchNo){       
       ReferenceBatchNo = refbatchNo;
       List<Metadata_Batch__c> refBatches = [select id,Name,Data_Field_API_Name__c,Source__c,query__c,Batch_Sequence__c from Metadata_Batch__c where Batch_Sequence__c =: refbatchNo];
       if(refBatches.size() > 0){
           componentType = refBatches[refBatches.size()-1].Name;
           Query = refBatches[refBatches.size()-1].query__c;
           markUpField = refBatches[refBatches.size()-1].Data_Field_API_Name__c;
       }       
   }

   global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator(query);
   }
   
   global void execute(Database.BatchableContext BC, List<sObject> scope){
      list<MetadataComponents> compReferenceList = new list<MetadataComponents>(); 
      for(sObject s : scope){
            //ApexClass cls = (ApexClass)s;
            // Get the Component Body 
            string strBody = string.valueof(s.get(markUpField));
            integer chunkSize = 100000;
            list<string> subStringChunks = new list<string>();
            while (strBody != null) {
                if (strBody.length() < chunkSize) {
                    subStringChunks.add(strBody);
                    break;
                }
                else {
                    subStringChunks.add(strBody.substring(0, chunkSize));                
                    strBody = strBody.substring(chunkSize);
                }
            }   
            for(string subStrBody:  subStringChunks){
                string removedComments = MetadataReferenceUtil.RemoveApexComments(subStrBody);
                MetadataComponents comp  = new MetadataComponents();
                comp.MetadataApiName = string.valueof(s.get('Name'));
                system.debug('&&&&&&&comp.MetadataApiName---'+comp.MetadataApiName);
                comp.MetadataType = componentType;
                compReferenceList.addAll(MetadataReferenceUtil.FindRefereceInMetadataBody(comp, removedComments));
            }
 
      }
      // Save the Reference Details in Database
      MetadataReferenceUtil.UpsertMetadataCompReferences(compReferenceList);
   }

   global void finish(Database.BatchableContext BC){ 
       ReferenceBatchNo++;
       system.debug('** batch No'+ReferenceBatchNo);
       List<Metadata_Batch__c> refBatches = [select id,Source__c,query__c,Batch_Sequence__c from Metadata_Batch__c where Batch_Sequence__c =: ReferenceBatchNo];
       if(refBatches.size() > 0 && refBatches[refBatches.size()-1].Source__c == 'Query'){
           MetadataUpdateRefeQueryBatch metadataRefCompbatch = new MetadataUpdateRefeQueryBatch(ReferenceBatchNo);
           Database.executeBatch(metadataRefCompbatch, 200);
       }else if(refBatches.size() > 0 && refBatches[refBatches.size()-1].Source__c == 'Metadata Api'){                      
           List<Attachment> atmnt = [SELECT Id,ParentId From Attachment WHERE ParentId =: refBatches[0].Id ];                 
           system.debug('** atmnt atmnt '+atmnt);
           if(atmnt.size() > 0){                   
               MetadataUpdateRefeXMLFileBatch metadataRefCompbatch = new MetadataUpdateRefeXMLFileBatch(ReferenceBatchNo);
               Database.executeBatch(metadataRefCompbatch, 100);         
           }                        
       }
   }
   
}