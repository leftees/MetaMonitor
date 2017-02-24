global class MetadataUpdateRefeXMLFileBatch implements Database.Batchable<String>, Database.Stateful{

   global final list<String> fileNames;
   global integer ReferenceBatchNo;
   global string componentType;
   global final Zippex ZipFile;
  
   global MetadataUpdateRefeXMLFileBatch(integer refbatchNo){       
       ReferenceBatchNo = refbatchNo;
       fileNames = new list<string>();
       List<Metadata_Batch__c> refBatches = [select id,Name,Data_Field_API_Name__c,Source__c,query__c,Batch_Sequence__c from Metadata_Batch__c where Batch_Sequence__c =: refbatchNo];
       if(refBatches.size() > 0 && refBatches[refBatches.size()-1].Source__c == 'Metadata Api'){       
           List<Attachment> atmnt = [SELECT Id,ParentId,Parent.name,Body From Attachment WHERE ParentId =: refBatches[0].Id ];                 
           system.debug('** atmnt atmnt '+atmnt);           
           if(atmnt.size() > 0){
               componentType = atmnt[atmnt.size()-1].Parent.Name;
                ZipFile = new Zippex(atmnt[atmnt.size()-1].Body);
                fileNames.addAll(ZipFile.getFileNames());      
           }         
       }     
   }

   global Iterable<String> start(Database.BatchableContext BC){
      return fileNames;
   }
   
   global void execute(Database.BatchableContext BC, List<String> scope){
      map<string,MetadataComponents> compReferenceMap = new map<string,MetadataComponents>(); 
      for(String s : scope){
            system.debug('@@@@ -- file anme ---'+s);
            list<string> filePathSplit = s.split('/');
            string folderName = '';
            string fileName = '';
            string fileExtension = '';
            if(filePathSplit.size() > 0){
                folderName = filePathSplit[0];  
                fileName = filePathSplit[filePathSplit.size()-1];
                if(fileName.contains('.')){
                    List<string> fileNameList = fileName.split('\\.');
                    if(fileNameList.size() > 0){
                        fileName = fileNameList[0];
                        fileExtension = fileNameList[fileNameList.size()-1];                    
                    }
                }                
            }   
            
            system.debug('$$$$$$'+fileName );        
            Blob fileData = ZipFile.getFile(s);
            string fileStrData = fileData.toString();   
            if(fileStrData != null && fileStrData != ''){               
                compReferenceMap.putall(MetadataReferenceUtil.FindRefereceByRefTypeXML(fileName,fileStrData,new map<string,MetadataComponents>())); 
            }                                       
      }
      // Save the Reference Details in Database
      MetadataReferenceUtil.UpsertMetadataCompReferences(compReferenceMap.values());
   }

   global void finish(Database.BatchableContext BC){ 
       ReferenceBatchNo++;
       List<Metadata_Batch__c> refBatches = [select id,Source__c,query__c,Batch_Sequence__c from Metadata_Batch__c where Batch_Sequence__c =: ReferenceBatchNo];
       if(refBatches.size() > 0 && refBatches[refBatches.size()-1].Source__c == 'Metadata Api'){                      
           List<Attachment> atmnt = [SELECT Id,ParentId From Attachment WHERE ParentId =: refBatches[0].Id ];                 
           system.debug('** atmnt atmnt '+atmnt);
           if(atmnt.size() > 0){                   
               MetadataUpdateRefeXMLFileBatch metadataRefCompbatch = new MetadataUpdateRefeXMLFileBatch(ReferenceBatchNo);
               Database.executeBatch(metadataRefCompbatch, 200);         
           }                        
       }
   }
   
}