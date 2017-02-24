public class MetadataReferenceUtil{        
    
    /****************************************************************************
    Find the Refereces of the components
    Parameters:  
    Retrun: 
    *****************************************************************************/        
    public static list<MetadataComponents> FindRefereceInMetadataBody(MetadataComponents metadataComp,string ComponentData){
        list<MetadataComponents> metadacompReferences = new list<MetadataComponents>();
        Map<String, RefTypeRegExMapping__c> regExMapping = RefTypeRegExMapping__c.getAll();
        for(RefTypeRegExMapping__c rexMap : regExMapping.Values()){            
            if(rexMap.Target_Type__c == metadataComp.MetadataType){
                /*MetadataComponents metadataComp = new MetadataComponents();
                metadataComp.MetadataApiName = metaCompApiName;
                metadataComp.MetadataType = metaCompType;*/
                Pattern RegExptrn = Pattern.compile(rexMap.RegEx__c);
                Matcher RegExmachr = RegExptrn.matcher(ComponentData);
                list<MetadataComponents> CompReferenceList = new list<MetadataComponents>();
                while(RegExmachr.find()) {                    
                    MetadataComponents refComp = new MetadataComponents();
                    refComp.MetadataApiName = RegExmachr.group(1);
                    refComp.MetadataType = rexMap.Reference_Type__c; 
                    CompReferenceList.add(refComp);                   
                    System.debug('param details: ' + RegExmachr.group(1));
                }  
                metadataComp.metadataReferences = CompReferenceList;             
            }            
        }                 
        metadacompReferences.add(metadataComp); 
        return metadacompReferences ;   
    }

    /****************************************************************************
    Find the Refereces of the components retreived by Metadaapi of XML file
    Parameters:  
    Retrun: 
    *****************************************************************************/      
    public static map<string,MetadataComponents> FindRefereceByRefTypeXML(string compApiName, string refData, map<string,MetadataComponents> processeReferencesMap){
        
        DOM.Document doc = new DOM.Document(); 
        doc.load(refData); 
        Dom.XMLNode referenceNode = doc.getRootElement();        
        
        Map<String, RefTypeRegExMapping__c> regExMapping = RefTypeRegExMapping__c.getAll();
        map<string,MetadataNodeMapping__c> metadataMapping = MetadataNodeMapping__c.getAll();
        
        list<MetadataComponents> CompReferenceList = new list<MetadataComponents>();
        MetadataComponents metadataComp = new MetadataComponents();
        // Get the MetadaAPI name from Node element
        // Ex: fullName on WorflowRule
        system.debug('** Root Node'+referenceNode.getName());
        if(metadataMapping.containskey(referenceNode.getName())){
            metadataComp.MetadataType = metadataMapping.get(referenceNode.getName()).Metadata_Type__c;
            if(metadataMapping.get(referenceNode.getName()).API_Node_Name__c == null || metadataMapping.get(referenceNode.getName()).API_Node_Name__c == ''){
                 metadataComp.MetadataApiName = compApiName;
            }else if(referenceNode.getName() == metadataMapping.get(referenceNode.getName()).API_Node_Name__c){
                metadataComp.MetadataApiName = referenceNode.getText();
            }
            if(!processeReferencesMap.containskey(metadataComp.MetadataType+'-'+metadataComp.MetadataApiName.toLowerCase())){
                processeReferencesMap.put(metadataComp.MetadataType+'-'+metadataComp.MetadataApiName.toLowerCase(),metadataComp);
            }        
        }
                       
        for(Dom.XMLNode childNode: referenceNode.getChildElements()){
            if(metadataMapping.containskey(childNode.getName())){
                processeReferencesMap.putall(FindReferenceByRefType(metadataMapping.get(childNode.getName()),childNode,processeReferencesMap));
            }
            system.debug('** chil Node'+childNode.getName());
        }        
                              
        return processeReferencesMap;    
    }
    
    
    public static map<string,MetadataComponents> FindReferenceByRefType(MetadataNodeMapping__c metaRef,Dom.XMLNode referenceNode,map<string,MetadataComponents> processeReferencesMap){
        Map<String, RefTypeRegExMapping__c> regExMapping = RefTypeRegExMapping__c.getAll();
        map<string,MetadataNodeMapping__c> metadataMapping = MetadataNodeMapping__c.getAll();
        list<MetadataComponents> CompReferenceList = new list<MetadataComponents>();
        MetadataComponents metadataComp = new MetadataComponents();         
        system.debug('** inner root Node'+referenceNode.getName());
        for(Dom.XMLNode childNode: referenceNode.getChildElements()){
            
            if(childNode.getName() == metaRef.API_Node_Name__c){
                system.debug('** referenceNode.getName%%%%%'+childNode.getName() );
                metadataComp.MetadataApiName = childNode.getText();
                metadataComp.MetadataType = metaRef.Metadata_Type__c;
            }
            if(childNode.getText() != null){  
                system.debug('** inner childNode.getText'+childNode.getText() );                                   
                 for(RefTypeRegExMapping__c rexMap : regExMapping.Values()){            
                    if(rexMap.Target_Type__c == metaRef.Metadata_Type__c){   
                        Pattern RegExptrn = Pattern.compile(rexMap.RegEx__c);
                        Matcher RegExmachr = RegExptrn.matcher(string.valueof(childNode.getText()));                        
                        while(RegExmachr.find()) {                                               
                            MetadataComponents refComp = new MetadataComponents();
                            refComp.MetadataApiName = RegExmachr.group(1);
                            refComp.MetadataType = rexMap.Reference_Type__c; 
                            CompReferenceList.add(refComp);                   
                            System.debug('param details: ' + RegExmachr.group(1));
                        }    
                        metadataComp.metadataReferences = CompReferenceList;  
                    }            
                }
                if(metadataComp != null && metadataComp.MetadataApiName != null && metadataComp.MetadataType != null){
                    if(!processeReferencesMap.containskey((metadataComp.MetadataType+'-'+metadataComp.MetadataApiName).toLowerCase())){
                        processeReferencesMap.put((metadataComp.MetadataType+'-'+metadataComp.MetadataApiName).toLowerCase(),metadataComp);
                    }  
                }                
                if(metadataMapping.containskey(childNode.getName())){
                    processeReferencesMap.putall(FindReferenceByRefType(metadataMapping.get(childNode.getName()),childNode,processeReferencesMap));
                }                                                               
            }                                       
        }                        
        return processeReferencesMap;
    }    
    

    public static void UpsertMetadataCompReferences(list<MetadataComponents>  metadataCompReferencelist){
        
        // Unique Key and Component Map
        map<string,Components__c> CompUniqueKeyMap = new map<string,Components__c>();
        map<string,Components__c> MainCompRefMap = new map<string,Components__c>();
        map<string,Components__c> refrnceCompMap = new map<string,Components__c>();
        
        // Upsert List
        list<Component_Reference__c> upsertCompReferenceList = new list<Component_Reference__c>();
        
        for(MetadataComponents compRef: metadataCompReferencelist){
            Components__c comp = new Components__c();
            comp.Component_API_Name__c = compRef.MetadataApiName;
            comp.Component_Type__c = compRef.MetadataType;
            comp.APINameAndType__c = (compRef.MetadataType+'-'+compRef.MetadataApiName).toLowerCase();
            if(!CompUniqueKeyMap.containskey((compRef.MetadataType+'-'+compRef.MetadataApiName).toLowerCase())){
                CompUniqueKeyMap.put((compRef.MetadataType+'-'+compRef.MetadataApiName).toLowerCase(),comp);
            }
            if(!MainCompRefMap.containskey((compRef.MetadataType+'-'+compRef.MetadataApiName).toLowerCase()) ){
                Components__c compRefRec = new Components__c();
                compRefRec.APINameAndType__c = (compRef.MetadataType+'-'+compRef.MetadataApiName).toLowerCase();
                MainCompRefMap.put((compRef.MetadataType+'-'+compRef.MetadataApiName).toLowerCase(),compRefRec);
            }
            if(compRef.metadataReferences != null && compRef.metadataReferences.size() > 0){
                for(MetadataComponents childRef: compRef.metadataReferences){    
                    Components__c refComp = new Components__c();
                    refComp.Component_API_Name__c = childRef.MetadataApiName;
                    refComp.Component_Type__c = childRef.MetadataType;
                    refComp.APINameAndType__c = (childRef.MetadataType+'-'+childRef.MetadataApiName).toLowerCase();                                                
                    if(!CompUniqueKeyMap.containskey((childRef.MetadataType+'-'+childRef.MetadataApiName).toLowerCase())){
                        CompUniqueKeyMap.put((childRef.MetadataType+'-'+childRef.MetadataApiName).toLowerCase(),refComp);
                    } 
                    //if(!refrnceCompMap.containskey((childRef.MetadataType+'-'+childRef.MetadataApiName).toLowerCase()) ){
                    Components__c compRefRec = new Components__c();
                    compRefRec.APINameAndType__c = (childRef.MetadataType+'-'+childRef.MetadataApiName).toLowerCase();
                    refrnceCompMap.put((childRef.MetadataType+'-'+childRef.MetadataApiName).toLowerCase(),compRefRec);
                    Component_Reference__c compRefeRec = new Component_Reference__c();
                    compRefeRec.Parent_Component__r = MainCompRefMap.get((compRef.MetadataType+'-'+compRef.MetadataApiName).toLowerCase());
                    compRefeRec.Child_Component__r = refrnceCompMap.get((childRef.MetadataType+'-'+childRef.MetadataApiName).toLowerCase());
                    compRefeRec.UniqueKey__c = CompUniqueKeyMap.get((childRef.MetadataType+'-'+childRef.MetadataApiName).toLowerCase()).APINameAndType__c+'-'+CompUniqueKeyMap.get((compRef.MetadataType+'-'+compRef.MetadataApiName).toLowerCase()).APINameAndType__c;
                    upsertCompReferenceList.add(compRefeRec);
                    //}                                       
                }
            }
        }        
        
        Schema.SObjectField f = Components__c.APINameAndType__c ;        
        
        Database.UpsertResult[] pareteRecResults = Database.upsert(CompUniqueKeyMap.values(),f,false);
        for(Database.UpsertResult res: pareteRecResults ){
            system.debug('*******'+res);        
        }
        
        for(string c: CompUniqueKeyMap.keySet()){
            if(CompUniqueKeyMap.get(c).APINameAndType__c == 'customlabel-errormsg'){
                system.debug('&&&&&&&----str----'+c);
            }
            
        }
                
        Database.UpsertResult[] childObjResults = Database.upsert(upsertCompReferenceList,false);
        for(Database.UpsertResult res: childObjResults ){
           system.debug('CCCC*******'+res);        
        }             
        
    }    
    
    
    public static string RemoveApexComments(string body){
        string finalUnCommentedBody = '';
        list<string> subStringChunks = new list<string>();
        
        list<string> unCommentedSubStringChunks = new list<string>();
        //Chunk largeSize Body to 400 size chunks
        integer chunkSize = 500;
        double numChunks = Math.ceil(body.length() / chunkSize );
        integer startIndex = 0;

        while (body != null) {
            if (body.length() < chunkSize) {
                subStringChunks.add(body);
                break;
            }
            else {
                subStringChunks.add(body.substring(0, chunkSize));
                body = body.substring(chunkSize);
            }
        }                
        
        for(string chunk:subStringChunks ){
            // RegEx to Identify Single Line Comments
            String regExp = '"(?:/\\*(?:[^*]|(?:\\*+[^*/]))*\\*+/)|(?://.*)';
            chunk  = chunk.replaceAll(regExp, '');        
            // RegEx to Find MultiLine Comments       
            //regExp = '/\\*(?:.|[\\n\\r])*?\\*/';
            //chunk  = chunk.replaceAll(regExp, '');   
            unCommentedSubStringChunks.add(chunk);
        }   
            
        finalUnCommentedBody = String.join(unCommentedSubStringChunks, ' ');      
        system.debug('######'+finalUnCommentedBody );               
        return finalUnCommentedBody ;
    }         
    
    
    
    public static MetadataService.AsyncResult sendRetreiveRequest(string metadataType,string sessionId){
            MetadataService.AsyncResult AsyncResult;
            MetadataService.MetadataPort portService = new MetadataService.MetadataPort();
            portService.SessionHeader = new MetadataService.SessionHeader_element();
            portService.SessionHeader.sessionId = sessionId;
            // Construct unmanaged package with component Type to retrieve in zip
            MetadataService.MetadataPort service = portService;        
            MetadataService.RetrieveRequest retrieveRequest = new MetadataService.RetrieveRequest();
            retrieveRequest.apiVersion = 36;
            retrieveRequest.packageNames = null;
            retrieveRequest.singlePackage = true;
            retrieveRequest.specificFiles = null;
            retrieveRequest.unpackaged = new MetadataService.Package_x();
            retrieveRequest.unpackaged.types = new List<MetadataService.PackageTypeMembers>();
            MetadataService.PackageTypeMembers packageType = new MetadataService.PackageTypeMembers();
            packageType.name = metadataType; 
            packageType.members = new String[] { '*' };
            retrieveRequest.unpackaged.types.add(packageType);
            AsyncResult = service.retrieve(retrieveRequest);        
        return AsyncResult;        
    }
    


    public static MetadataService.RetrieveResult CheckAsyncStatusAndCreateZipFile(string asyncId,string SessionId){
        MetadataService.MetadataPort portService = new MetadataService.MetadataPort();
        portService.SessionHeader = new MetadataService.SessionHeader_element();
        portService.SessionHeader.sessionId = SessionId;
        // Construct unmanaged package with component Type to retrieve in zip
        MetadataService.MetadataPort service = portService;    
        MetadataService.RetrieveResult retrieveResult = service.checkRetrieveStatus(asyncId, true);      
        return retrieveResult ;        
    }
    
}