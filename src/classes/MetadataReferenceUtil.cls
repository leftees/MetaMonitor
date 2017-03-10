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
            if(rexMap.Target_Type__c == metadataComp.MetadataType && rexMap.Component_Index__c != null){
                /*MetadataComponents metadataComp = new MetadataComponents();
                metadataComp.MetadataApiName = metaCompApiName;
                metadataComp.MetadataType = metaCompType;*/
                Pattern RegExptrn = Pattern.compile(rexMap.RegEx__c);
                Matcher RegExmachr = RegExptrn.matcher(ComponentData);
                list<MetadataComponents> CompReferenceList = new list<MetadataComponents>();
                while(RegExmachr.find()) {                    
                    MetadataComponents refComp = new MetadataComponents();
                    refComp.MetadataApiName = RegExmachr.group(integer.valueOf(rexMap.Component_Index__c));
                    refComp.MetadataType = rexMap.Reference_Type__c; 
                    CompReferenceList.add(refComp);                   
                    System.debug('param details: ' + RegExmachr.group(integer.valueOf(rexMap.Component_Index__c)));
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
                metadataComp.ParentObject = compApiName;
            }     
        }
        if(metadataComp != null && metadataComp.MetadataApiName != null && metadataComp.MetadataType != null){
            if(!processeReferencesMap.containskey(metadataComp.MetadataType+'-'+metadataComp.MetadataApiName.toLowerCase())){
                processeReferencesMap.put(metadataComp.MetadataType+'-'+metadataComp.MetadataApiName.toLowerCase(),metadataComp);
            }  
        }

        for(Dom.XMLNode childNode: referenceNode.getChildElements()){      
            if( metadataMapping.containsKey(referenceNode.getName()) && 
                childNode.getName() == metadataMapping.get(referenceNode.getName()).ValueNode__c){
                system.debug('Label Assigned*'+childNode.getText());
                metadataComp.Value = childNode.getText();
            }             
            if(metadataMapping.containskey(childNode.getName())){
                processeReferencesMap.putall(FindReferenceByRefType(compApiName,metadataMapping.get(childNode.getName()),childNode,processeReferencesMap));
            }            
        }        
                             
        return processeReferencesMap;    
    }
    
    
    public static map<string,MetadataComponents> FindReferenceByRefType(string compApiName,MetadataNodeMapping__c metaRef,Dom.XMLNode referenceNode,map<string,MetadataComponents> processeReferencesMap){
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
                metadataComp.ParentObject = compApiName;
            }
            // Other Field Mapping
            if(childNode.getName() == metaRef.ValueNode__c){
                system.debug('** referenceNode.getName%%%%%'+childNode.getName() );
                metadataComp.value = childNode.getText();                
            }     

            // isActive Node Mapping
            // For Exp: Validation Rule and Workflow Rules Etc..
            if(childNode.getName() == 'active'){         
                system.debug('Is Active %%%%'+childNode.getText() );
                if(childNode.getText() == 'true'){
                    metadataComp.isActive = true;                    
                }else{
                     metadataComp.isActive = false;   
                }                            
            }    

            if(childNode.getName() == 'actions'){
                 system.debug('** Link Action with WorflowRule '+childNode.getText() ); 
                 if(metadataComp.metadataReferences != null ){
                    metadataComp.metadataReferences.add(findChildReferences(childNode,metadataMapping));
                 }else{
                    CompReferenceList.add(findChildReferences(childNode,metadataMapping));
                    metadataComp.metadataReferences = CompReferenceList;
                 }
                
            }

            if(childNode.getText() != null){  
                system.debug('** inner childNode.getText'+childNode.getText() );                                   
                 for(RefTypeRegExMapping__c rexMap : regExMapping.Values()){            
                    if(rexMap.Target_Type__c == metaRef.Metadata_Type__c && rexMap.Component_Index__c != null){   
                        Pattern RegExptrn = Pattern.compile(rexMap.RegEx__c);
                        Matcher RegExmachr = RegExptrn.matcher(string.valueof(childNode.getText()));                        
                        while(RegExmachr.find()) {                                               
                            MetadataComponents refComp = new MetadataComponents();
                            refComp.MetadataApiName = RegExmachr.group(integer.valueOf(rexMap.Component_Index__c));
                            refComp.MetadataType = rexMap.Reference_Type__c; 
                            CompReferenceList.add(refComp);                   
                            System.debug('param details: ' + RegExmachr.group(integer.valueOf(rexMap.Component_Index__c)));
                        }    
                        metadataComp.metadataReferences = CompReferenceList;  
                    }            
                }
            } 

            if(metadataComp != null && metadataComp.MetadataApiName != null && metadataComp.MetadataType != null){
                if(!processeReferencesMap.containskey((metadataComp.MetadataType+'-'+metadataComp.MetadataApiName).toLowerCase())){
                    processeReferencesMap.put((metadataComp.MetadataType+'-'+metadataComp.MetadataApiName).toLowerCase(),metadataComp);
                }  
            }                
            if(metadataMapping.containskey(childNode.getName())){
                processeReferencesMap.putall(FindReferenceByRefType(compApiName,metadataMapping.get(childNode.getName()),childNode,processeReferencesMap));
            }                                                                                                     
        }                        
        return processeReferencesMap;
    }    
    
    public static MetadataComponents findChildReferences(Dom.XMLNode actionNode,map<string,MetadataNodeMapping__c> metadataMapping){
        MetadataComponents CompReference = new MetadataComponents();    
        for(Dom.XMLNode childNode: actionNode.getChildElements()){
            if(childNode.getName() == 'name'){
                CompReference.MetadataApiName = childNode.getText() ;
            }
            if(childNode.getName() == 'type'){
                for(string metaType: metadataMapping.keySet()){ 
                    if(metaType.toLowerCase() == (childNode.getText()+'s').toLowerCase()){
                        CompReference.MetadataType = metadataMapping.get(metaType).Metadata_Type__c;                         
                    }               
                }
            }
        }
        system.debug('&&&&&&&&&'+CompReference);
        return CompReference;
    }

    public static void findSobjectReference(string className, string classContent){        
        
        map<string,string> variableDataTypeMap = new map<string,string>();
        map<string,string> parameterDataTypeMap = new map<string,string>();
        map<string,set<string>> sObjectFieldsRefeMap = new map<string,set<string>>();
        variableDataTypeMap = getVariableDataTypeMap(classContent);
        sObjectFieldsRefeMap = findSObjectFields(variableDataTypeMap,classContent);
        system.debug('sObjectFieldsRefeMap**----'+sObjectFieldsRefeMap);
    }    

    public static map<string,string> getVariableDataTypeMap(string classContent){
        map<string,string> variableDataTypeMap = new map<string,string>();
        Pattern findSObjectFields = Pattern.compile('(?i)\\b(?!public|\\s|static|final\\b)([a-zA-Z0-9<,]+[^.]\\s)(.+);');       
        Matcher sObjectFieldsFind = findSObjectFields.matcher(classContent);    
         while (sObjectFieldsFind.find()) {                         
            string dataType = sObjectFieldsFind.group(1);
            string variablDecl = sObjectFieldsFind.group(2);
            if(variablDecl != null && !variablDecl.startsWith('=')){
                system.debug('@*****----'+dataType+'--'+variablDecl);                
                if(variablDecl.contains(',')){
                    for(string varD: variablDecl.split(',')){
                        string variable = varD.contains('=') ? varD.split('=')[0] : varD;
                        variableDataTypeMap.put(variable,dataType);                        
                    }
                }else{
                    string variable = variablDecl.contains('=') ? variablDecl.split('=')[0] : variablDecl;
                    variableDataTypeMap.put(variable,dataType);                      
                }
            }         
         }
         system.debug('variableDataTypeMap**----'+variableDataTypeMap); 
         return variableDataTypeMap;           
    }

    public static Map<string,Set<String>> findSObjectFields(map<string,string> variableDataTypeMap, string classContent){
        map<string,set<string>> sObjectFieldsRefeMap = new map<string,set<string>>();
        list<Schema.SObjectType> globalDescribeObj = Schema.getGlobalDescribe().Values();     
        set<string> sObjectNames = new set<string>();
        for(Schema.SObjectType sObjType : globalDescribeObj){
            sObjectNames.add(sObjType.getDescribe().getName().toLowerCase());
        }        
        
        for(string variableRef : variableDataTypeMap.keySet()){
            string objectName = variableDataTypeMap.get(variableRef).toLowerCase().trim();            
            system.debug('&&&&&&&&&*'+objectName);
            if(sObjectNames.contains(objectName)){
                Set<String> setOfFields= new Set<String>();
                string fieldReferences = VariableRef + '\\.';      
                Pattern findSObjectFields = Pattern.compile(fieldReferences);       
                Matcher sObjectFieldsFind = findSObjectFields.matcher(classContent);
                while (sObjectFieldsFind.find()) {
                    system.debug('sObjectFieldsFind---->>>'+sObjectFieldsFind.end());
                    string temp1 = classContent.substring(sObjectFieldsFind.end());
                    system.debug('temp1indexOf---->>>'+temp1.indexOf('='));
                    if(temp1.indexOf('=') != -1) {
                        string temp2 = temp1.substring(0,temp1.indexOf('=')).trim();
                        system.debug('temp2---->>>'+temp2);//classContent.indexOf('=')
                        setOfFields.add(temp2);
                    }
                }
                system.debug('setOfFields---->>>'+setOfFields);
                if(sObjectFieldsRefeMap.containskey(objectName)){
                    sObjectFieldsRefeMap.get(objectName).addall(setOfFields);
                }else{
                    sObjectFieldsRefeMap.put(objectName,setOfFields);
                }                
            }
        }
        return sObjectFieldsRefeMap;   
    }

    public static set<string> getPrimitiveDataTyes(){
        set<string> primitiveDataType = new set<string>();
        primitiveDataType.add('blob');
        primitiveDataType.add('boolean');
        primitiveDataType.add('date');
        primitiveDataType.add('datetime');
        primitiveDataType.add('decimal');
        primitiveDataType.add('double');
        primitiveDataType.add('id');
        primitiveDataType.add('integer');
        primitiveDataType.add('long');
        primitiveDataType.add('object');
        primitiveDataType.add('string');
        primitiveDataType.add('time');
        return primitiveDataType;
    }

    public static set<string> getReserveKeyWords(){
        set<string> keywords = new set<string>();
        keywords.add('public');
        keywords.add('static');
        keywords.add('void');
        keywords.add('new');
        return keywords;
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
            comp.Value__c = compRef.Value;
            comp.Is_Active__c = compRef.isActive;
            comp.Parent_APIName__c = compRef.ParentObject;
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
                    Components__c compRefRec = new Components__c();
                    compRefRec.APINameAndType__c = (childRef.MetadataType+'-'+childRef.MetadataApiName).toLowerCase();
                    refrnceCompMap.put((childRef.MetadataType+'-'+childRef.MetadataApiName).toLowerCase(),compRefRec);
                    Component_Reference__c compRefeRec = new Component_Reference__c();
                    compRefeRec.Parent_Component__r = MainCompRefMap.get((compRef.MetadataType+'-'+compRef.MetadataApiName).toLowerCase());
                    compRefeRec.Child_Component__r = refrnceCompMap.get((childRef.MetadataType+'-'+childRef.MetadataApiName).toLowerCase());
                    compRefeRec.UniqueKey__c = CompUniqueKeyMap.get((childRef.MetadataType+'-'+childRef.MetadataApiName).toLowerCase()).APINameAndType__c+'-'+CompUniqueKeyMap.get((compRef.MetadataType+'-'+compRef.MetadataApiName).toLowerCase()).APINameAndType__c;
                    upsertCompReferenceList.add(compRefeRec);                                                      
                }
            }
        }        
        
        Schema.SObjectField f = Components__c.APINameAndType__c ;        
        
        Database.UpsertResult[] pareteRecResults = Database.upsert(CompUniqueKeyMap.values(),f,false);
        list<Error_Handler__c>  errorList = new list<Error_Handler__c>();
        for(Database.UpsertResult res: pareteRecResults ){
            system.debug('*******'+res);     
            Error_Handler__c error = new Error_Handler__c();
            error.Error_Description__c = string.valueOf(res);
            errorList.add(error);
        }
        
        for(string c: CompUniqueKeyMap.keySet()){
            if(CompUniqueKeyMap.get(c).APINameAndType__c == 'customlabel-errormsg'){
                system.debug('&&&&&&&----str----'+c);
            }
            
        }
                
        Database.UpsertResult[] childObjResults = Database.upsert(upsertCompReferenceList,false);
        for(Database.UpsertResult res: childObjResults ){
           system.debug('CCCC*******'+res); 
            Error_Handler__c error = new Error_Handler__c();
            error.Error_Description__c = string.valueOf(res);
            errorList.add(error);                  
        }             
        
        // insert errorList;
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


    public static MetadataService.UpsertResult[] CreateStaticResourceFile(string StaticResName,blob AttachmentBody){
        string SESSION_ID;
        MetadataService.UpsertResult[] retrieveResult ;
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
                    MetadataService.MetadataPort portService = new MetadataService.MetadataPort();
                    portService.SessionHeader = new MetadataService.SessionHeader_element();
                    portService.SessionHeader.sessionId = SESSION_ID;
                    // Construct unmanaged package with component Type to retrieve in zip
                    MetadataService.MetadataPort service = portService;          
                    MetadataService.StaticResource staticResource = new MetadataService.StaticResource();
                    staticResource.fullName = StaticResName;
                    staticResource.contentType = 'application/x-zip-compressed';
                    staticResource.cacheControl = 'public';
                    staticResource.content = EncodingUtil.base64Encode(AttachmentBody);                     
                    retrieveResult = service.upsertMetadata(new List<MetadataService.Metadata> { staticResource }); 
                    return retrieveResult;            
             }
        }catch(Exception exp){
            return retrieveResult ; 
        }
        return retrieveResult ;        
    }

    public static MetadataService.DeleteResult[] DeleteStaticResourceFile(string StaticResName){
        string SESSION_ID;
        MetadataService.DeleteResult[] deleteResult ;
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
                    MetadataService.MetadataPort portService = new MetadataService.MetadataPort();
                    portService.SessionHeader = new MetadataService.SessionHeader_element();
                    portService.SessionHeader.sessionId = SESSION_ID;
                    // Construct unmanaged package with component Type to retrieve in zip
                    MetadataService.MetadataPort service = portService;                            
                    deleteResult  = service.deleteMetadata('StaticResource',new List<string> { StaticResName }); 
                    return deleteResult;            
             }
        }catch(Exception exp){
            return deleteResult ; 
        }
        return deleteResult ;        
    }

}